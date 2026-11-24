from datetime import date

from django.contrib import messages
from django.db import DatabaseError, transaction
from django.db.models import Count
from django.shortcuts import get_object_or_404, redirect, render

from .forms import AtividadeForm, CertificadoForm, CheckinForm, EventoForm
from .models import Atividade, Evento, Inscricao, Participante


def _msg_banco(e):
    """Mensagem do PostgreSQL (constraint ou gatilho), primeira linha."""
    return f'O banco recusou a operação: {str(e).splitlines()[0]}'


# ---------- CRUD de Evento + busca por substring ----------
def evento_list(request):
    q = request.GET.get('q', '').strip()
    eventos = Evento.objects.order_by('codigo_evento')
    if q:
        eventos = eventos.filter(nome_evento__icontains=q)  # ILIKE '%q%'
    return render(request, 'eventos/evento_list.html', {'eventos': eventos, 'q': q})


def evento_detail(request, pk):
    evento = get_object_or_404(Evento, pk=pk)
    atividades = Atividade.objects.filter(codigo_evento=evento)
    return render(request, 'eventos/evento_detail.html',
                  {'evento': evento, 'atividades': atividades})


def evento_form(request, pk=None):
    evento = get_object_or_404(Evento, pk=pk) if pk else None
    form = EventoForm(request.POST or None, instance=evento)
    if request.method == 'POST' and form.is_valid():
        try:
            with transaction.atomic():
                form.save()  # INSERT ou UPDATE em evento
            messages.success(request, 'Evento salvo com sucesso.')
            return redirect('evento_list')
        except DatabaseError as e:  # CHECK, UNIQUE...
            messages.error(request, _msg_banco(e))
    titulo = 'Editar evento' if pk else 'Novo evento'
    return render(request, 'eventos/form.html', {'form': form, 'titulo': titulo})


def evento_delete(request, pk):
    evento = get_object_or_404(Evento, pk=pk)
    if request.method == 'POST':
        try:
            with transaction.atomic():
                evento.delete()  # DELETE em evento
            messages.success(request, 'Evento removido.')
            return redirect('evento_list')
        except DatabaseError as e:  # FK RESTRICT: evento com atividades
            messages.error(request, _msg_banco(e))
            return redirect('evento_detail', pk=pk)
    return render(request, 'eventos/evento_delete.html', {'evento': evento})

def atividade_create(request, evento_pk):
    evento = get_object_or_404(Evento, pk=evento_pk)
    form = AtividadeForm(request.POST or None)
    if request.method == 'POST' and form.is_valid():
        try:
            with transaction.atomic():
                atividade = form.save(commit=False)
                atividade.codigo_evento = evento
                atividade.save()  # INSERT em atividade
            messages.success(request, 'Atividade cadastrada.')
            return redirect('evento_detail', pk=evento.pk)
        except DatabaseError as e:  # ex.: CHECK de carga horária
            messages.error(request, _msg_banco(e))
    return render(request, 'eventos/form.html', {
        'form': form, 'titulo': f'Nova atividade em "{evento.nome_evento}"'})

# ---------- Operação composta (várias linhas, 1 transação) ----------
def inscricao_multipla(request):
    if request.method == 'POST':
        cpf = request.POST.get('participante')
        ids = request.POST.getlist('atividades')
        if not ids:
            messages.error(request, 'Selecione pelo menos uma atividade.')
        else:
            try:
                with transaction.atomic():
                    for cod in ids:
                        Inscricao.objects.create(
                            cpf_participante_id=cpf,
                            codigo_atividade_id=cod,
                            data_inscricao=date.today(),
                            status='Confirmada',
                        )
                messages.success(request, f'{len(ids)} inscrição(ões) criada(s).')
                return redirect('relatorio_join')
            except DatabaseError as e:  # se uma falhar, nenhuma é gravada
                messages.error(request, _msg_banco(e))
    return render(request, 'eventos/inscricao_multipla.html', {
        'participantes': Participante.objects.order_by('nome_participante'),
        'atividades': Atividade.objects.order_by('titulo'),
    })


# ---------- Inscrições, check-in e certificado (gatilhos) ----------
def inscricao_list(request):
    inscricoes = (Inscricao.objects
                  .select_related('cpf_participante', 'codigo_atividade')
                  .order_by('id_inscricao'))
    return render(request, 'eventos/inscricao_list.html', {'inscricoes': inscricoes})


def inscricao_checkin(request, pk):
    insc = get_object_or_404(Inscricao, pk=pk)
    form = CheckinForm(request.POST or None, instance=insc)
    if request.method == 'POST' and form.is_valid():
        try:
            with transaction.atomic():
                form.save()  # UPDATE em inscricao -> dispara trg_valida_inscricao
            messages.success(request, 'Check-in/avaliação registrado.')
            return redirect('inscricao_list')
        except DatabaseError as e:  # RO-04, RA-04 ou CHECK da nota
            messages.error(request, _msg_banco(e))
    return render(request, 'eventos/form.html',
                  {'form': form, 'titulo': f'Check-in / avaliação da inscrição #{pk}'})


def certificado_create(request):
    form = CertificadoForm(request.POST or None)
    if request.method == 'POST' and form.is_valid():
        try:
            with transaction.atomic():
                form.save()  # INSERT em certificado -> dispara trg_valida_certificado
            messages.success(request, 'Certificado emitido.')
            return redirect('inscricao_list')
        except DatabaseError as e:  # RA-02 ou RA-03
            messages.error(request, _msg_banco(e))
    return render(request, 'eventos/form.html',
                  {'form': form, 'titulo': 'Emitir certificado'})


# ---------- Relatórios ----------
def relatorio_join(request):
    qs = (Inscricao.objects
          .select_related('cpf_participante', 'codigo_atividade__codigo_evento')
          .order_by('id_inscricao'))  # INNER JOINs
    linhas = [(i.cpf_participante.nome_participante, i.codigo_atividade.titulo,
               i.codigo_atividade.codigo_evento.nome_evento, i.status) for i in qs]
    return render(request, 'eventos/relatorio.html', {
        'titulo': 'Inscrições (JOIN: inscricao, participante, atividade, evento)',
        'colunas': ['Participante', 'Atividade', 'Evento', 'Status'],
        'linhas': linhas})


def _inscritos_por_atividade():
    return (Atividade.objects
            .values('codigo_atividade', 'titulo')
            .annotate(total=Count('inscricao'))  # GROUP BY + COUNT
            .order_by('-total'))


def relatorio_group(request):
    linhas = [(r['titulo'], r['total']) for r in _inscritos_por_atividade()]
    return render(request, 'eventos/relatorio.html', {
        'titulo': 'Inscritos por atividade (GROUP BY + COUNT)',
        'colunas': ['Atividade', 'Inscritos'], 'linhas': linhas})


def relatorio_having(request):
    try:
        minimo = int(request.GET.get('min', 2))
    except ValueError:
        minimo = 2
    qs = _inscritos_por_atividade().filter(total__gte=minimo)  # HAVING COUNT >= min
    linhas = [(r['titulo'], r['total']) for r in qs]
    return render(request, 'eventos/relatorio.html', {
        'titulo': f'Atividades com pelo menos {minimo} inscritos (GROUP BY + HAVING)',
        'colunas': ['Atividade', 'Inscritos'], 'linhas': linhas,
        'mostrar_filtro': True, 'minimo': minimo})

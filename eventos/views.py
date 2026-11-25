from django.contrib import messages
from django.db import DatabaseError, IntegrityError, connection
from django.shortcuts import get_object_or_404, redirect, render

from .forms import AtividadeForm, CertificadoForm, CheckinForm, EventoForm
from .models import Atividade, Evento, Inscricao, Participante

from django.db import DatabaseError, IntegrityError, transaction
from django.utils import timezone

from .models import (
    Aluno,
    Atividade,
    Evento,
    Externo,
    Inscricao,
    Participante,
    Professor,
    Certificado
)


from django.db import DatabaseError


import uuid

def inscricao_alterar_status(request, inscricao_id, novo_status):
    inscricao = get_object_or_404(Inscricao, pk=inscricao_id)
    if request.method == 'POST' and novo_status in ('Pendente', 'Confirmada', 'Cancelada'):
        try:
            inscricao.status = novo_status
            inscricao.save()
            messages.success(
                request,
                f'Status de {inscricao.cpf_participante.nome_participante} alterado para "{novo_status}".'
            )
        except DatabaseError as e:
            messages.error(request, str(e))
    return redirect(request.META.get('HTTP_REFERER') or 'participante_list')

def certificado_create(request):
    inscricao_id = request.GET.get('inscricao', '').strip()

    inscricoes_disponiveis = Inscricao.objects.select_related(
        'cpf_participante',
        'codigo_atividade',
        'codigo_atividade__codigo_evento',
    ).filter(
        data_hora_checkin__isnull=False,
        certificado__isnull=True,
    ).order_by('id_inscricao')

    if request.method == 'POST':
        form = CertificadoForm(request.POST)
        form.fields['id_inscricao'].queryset = inscricoes_disponiveis
        if form.is_valid():
            try:
                cert = form.save(commit=False)
                if not cert.link_pdf:
                    cert.link_pdf = f'http://certificados.evento.br/{cert.codigo_de_validacao}'
                cert.save()
                messages.success(request, f'Certificado {cert.codigo_de_validacao} emitido com sucesso!')
                return redirect('certificado_list')
            except DatabaseError as e:
                messages.error(request, str(e))
        inscricao_selecionada = str(request.POST.get('id_inscricao', ''))
    else:
        initial = {
            'codigo_de_validacao': f'CERT-{timezone.localdate().year}-{uuid.uuid4().hex[:6].upper()}',
            'data_de_emissao': timezone.localdate(),
        }
        inscricao_selecionada = ''
        if inscricao_id.isdigit():
            ins = inscricoes_disponiveis.filter(pk=int(inscricao_id)).first()
            if ins:
                initial['id_inscricao'] = ins
                initial['carga_horaria_certificada'] = ins.codigo_atividade.carga_horaria
                inscricao_selecionada = str(ins.pk)

        form = CertificadoForm(initial=initial)
        form.fields['id_inscricao'].queryset = inscricoes_disponiveis

    return render(request, 'eventos/certificado_form.html', {
        'form': form,
        'titulo': 'Emitir certificado',
        'inscricoes_disponiveis': inscricoes_disponiveis,
        'inscricao_selecionada': inscricao_selecionada,
    })

def certificado_delete(request, codigo):
    certificado = get_object_or_404(Certificado, pk=codigo)
    if request.method == 'POST':
        try:
            certificado.delete()
            messages.success(request, 'Certificado excluído com sucesso!')
            return redirect('certificado_list')
        except DatabaseError as e:
            messages.error(request, str(e))
            return redirect('certificado_list')

    return render(request, 'eventos/certificado_delete.html', {
        'certificado': certificado,
    })


def certificado_list(request):
    certificados = Certificado.objects.select_related(
        'id_inscricao',
        'id_inscricao__cpf_participante',
        'id_inscricao__codigo_atividade',
        'id_inscricao__codigo_atividade__codigo_evento',
    ).order_by('-data_de_emissao', 'codigo_de_validacao')
    return render(request, 'eventos/certificado_list.html', {
        'certificados': certificados,
    })


def _identificar_categoria(participante):
    if Aluno.objects.filter(pk=participante.pk).exists():
        return 'Aluno'
    if Professor.objects.filter(pk=participante.pk).exists():
        return 'Professor'
    if Externo.objects.filter(pk=participante.pk).exists():
        return 'Externo'
    return 'Sem categoria'


def _montar_itens_participantes(qs, inscricoes_qs):
    alunos_cpfs = set(Aluno.objects.values_list('cpf_participante_id', flat=True))
    profs_cpfs = set(Professor.objects.values_list('cpf_participante_id', flat=True))
    ext_cpfs = set(Externo.objects.values_list('cpf_participante_id', flat=True))

    inscricoes_por_cpf = {}
    for ins in inscricoes_qs:
        try:
            cert_codigo = ins.certificado.codigo_de_validacao
        except Certificado.DoesNotExist:
            cert_codigo = None
        ins.cert_codigo = cert_codigo
        inscricoes_por_cpf.setdefault(ins.cpf_participante_id, []).append(ins)

    itens = []
    for p in qs:
        if p.cpf_participante in alunos_cpfs:
            cat = 'Aluno'
        elif p.cpf_participante in profs_cpfs:
            cat = 'Professor'
        elif p.cpf_participante in ext_cpfs:
            cat = 'Externo'
        else:
            cat = 'Participante'

        itens.append({
            'participante': p,
            'categoria': cat,
            'inscricoes': inscricoes_por_cpf.get(p.cpf_participante, []),
        })
    return itens


def participante_list(request):
    """Tela geral: mostra TODOS os participantes cadastrados no sistema."""
    nome = request.GET.get('nome', '').strip()
    categoria = request.GET.get('categoria', 'todos').strip().lower()

    qs = Participante.objects.order_by('nome_participante')

    if nome:
        qs = qs.filter(nome_participante__icontains=nome)

    if categoria == 'aluno':
        qs = qs.filter(cpf_participante__in=Aluno.objects.values('cpf_participante_id'))
    elif categoria == 'professor':
        qs = qs.filter(cpf_participante__in=Professor.objects.values('cpf_participante_id'))
    elif categoria == 'externo':
        qs = qs.filter(cpf_participante__in=Externo.objects.values('cpf_participante_id'))

    inscricoes = Inscricao.objects.select_related(
        'cpf_participante',
        'codigo_atividade',
        'codigo_atividade__codigo_evento',
        'certificado',
    ).order_by('id_inscricao')

    itens = _montar_itens_participantes(qs, inscricoes)

    return render(request, 'eventos/participante_list.html', {
        'itens': itens,
        'nome': nome,
        'categoria': categoria,
        'evento_filtro': None,
    })


def evento_participante_list(request, evento_pk):
    """Tela do evento: mostra APENAS os participantes inscritos neste evento."""
    evento = get_object_or_404(Evento, pk=evento_pk)
    nome = request.GET.get('nome', '').strip()
    categoria = request.GET.get('categoria', 'todos').strip().lower()

    qs = Participante.objects.filter(
        inscricao__codigo_atividade__codigo_evento=evento
    ).distinct().order_by('nome_participante')

    if nome:
        qs = qs.filter(nome_participante__icontains=nome)

    if categoria == 'aluno':
        qs = qs.filter(cpf_participante__in=Aluno.objects.values('cpf_participante_id'))
    elif categoria == 'professor':
        qs = qs.filter(cpf_participante__in=Professor.objects.values('cpf_participante_id'))
    elif categoria == 'externo':
        qs = qs.filter(cpf_participante__in=Externo.objects.values('cpf_participante_id'))

    inscricoes = Inscricao.objects.select_related(
        'cpf_participante',
        'codigo_atividade',
        'codigo_atividade__codigo_evento',
        'certificado',
    ).filter(codigo_atividade__codigo_evento=evento).order_by('id_inscricao')

    itens = _montar_itens_participantes(qs, inscricoes)

    return render(request, 'eventos/participante_list.html', {
        'itens': itens,
        'nome': nome,
        'categoria': categoria,
        'evento_filtro': evento,
    })

def participante_create(request):
    evento_id = request.GET.get('evento') or request.POST.get('evento')
    if request.method == 'POST':
        cpf = request.POST.get('cpf_participante', '').strip()
        nome = request.POST.get('nome_participante', '').strip()
        email = request.POST.get('email_participante', '').strip()
        telefone = request.POST.get('telefone_participante', '').strip() or None
        nascimento = request.POST.get('data_nascimento', '').strip() or None
        categoria = request.POST.get('categoria', 'aluno')

        try:
            with transaction.atomic():
                participante = Participante.objects.create(
                    cpf_participante=cpf,
                    nome_participante=nome,
                    email_participante=email,
                    telefone_participante=telefone,
                    data_nascimento=nascimento,
                )

                if categoria == 'aluno':
                    Aluno.objects.create(
                        cpf_participante=participante,
                        matricula=request.POST.get('matricula', '').strip(),
                        curso=request.POST.get('curso', '').strip(),
                        semestre=request.POST.get('semestre') or None,
                        campus=request.POST.get('campus', '').strip() or None,
                    )
                elif categoria == 'professor':
                    Professor.objects.create(
                        cpf_participante=participante,
                        titulacao=request.POST.get('titulacao', '').strip(),
                        departamento=request.POST.get('departamento', '').strip(),
                        link_lattes=request.POST.get('link_lattes', '').strip() or None,
                    )
                elif categoria == 'externo':
                    Externo.objects.create(
                        cpf_participante=participante,
                        instituicao_origem=request.POST.get('instituicao_origem', '').strip(),
                        tipo_vinculo=request.POST.get('tipo_vinculo', '').strip(),
                        cargo=request.POST.get('cargo', '').strip() or None,
                        cidade=request.POST.get('cidade', '').strip() or None,
                    )

            messages.success(request, 'Participante cadastrado com sucesso!')
            if evento_id and str(evento_id).isdigit():
                return redirect('participante_inscrever', cpf=participante.cpf_participante)
            return redirect('participante_list')
        except DatabaseError as e:
            messages.error(request, f'Erro ao cadastrar participante: {e}')

    return render(request, 'eventos/participante_form.html', {
        'titulo': 'Novo participante',
        'modo': 'criar',
        'categoria_atual': 'aluno',
        'evento_id': evento_id,
    })

def inscricao_delete(request, inscricao_id):
    inscricao = get_object_or_404(Inscricao, pk=inscricao_id)
    if request.method == 'POST':
        try:
            inscricao.delete()
            messages.success(request, 'Inscrição excluída com sucesso!')
        except (IntegrityError, DatabaseError):
            messages.error(
                request,
                'Não é possível excluir esta inscrição porque há certificado emitido ou restrição no banco.'
            )
    return redirect(request.META.get('HTTP_REFERER') or 'participante_list')

def participante_update(request, cpf):
    participante = get_object_or_404(Participante, pk=cpf)
    aluno = Aluno.objects.filter(pk=participante.pk).first()
    professor = Professor.objects.filter(pk=participante.pk).first()
    externo = Externo.objects.filter(pk=participante.pk).first()

    if aluno:
        categoria_atual = 'aluno'
    elif professor:
        categoria_atual = 'professor'
    elif externo:
        categoria_atual = 'externo'
    else:
        categoria_atual = 'aluno'

    if request.method == 'POST':
        participante.nome_participante = request.POST.get('nome_participante', '').strip()
        participante.email_participante = request.POST.get('email_participante', '').strip()
        participante.telefone_participante = request.POST.get('telefone_participante', '').strip() or None
        participante.data_nascimento = request.POST.get('data_nascimento', '').strip() or None
        categoria = request.POST.get('categoria', categoria_atual)

        try:
            with transaction.atomic():
                participante.save()

                if categoria != 'aluno' and aluno:
                    aluno.delete()
                    aluno = None
                if categoria != 'professor' and professor:
                    professor.delete()
                    professor = None
                if categoria != 'externo' and externo:
                    externo.delete()
                    externo = None

                if categoria == 'aluno':
                    if not aluno:
                        aluno = Aluno(cpf_participante=participante)
                    aluno.matricula = request.POST.get('matricula', '').strip()
                    aluno.curso = request.POST.get('curso', '').strip()
                    aluno.semestre = request.POST.get('semestre') or None
                    aluno.campus = request.POST.get('campus', '').strip() or None
                    aluno.save()
                elif categoria == 'professor':
                    if not professor:
                        professor = Professor(cpf_participante=participante)
                    professor.titulacao = request.POST.get('titulacao', '').strip()
                    professor.departamento = request.POST.get('departamento', '').strip()
                    professor.link_lattes = request.POST.get('link_lattes', '').strip() or None
                    professor.save()
                elif categoria == 'externo':
                    if not externo:
                        externo = Externo(cpf_participante=participante)
                    externo.instituicao_origem = request.POST.get('instituicao_origem', '').strip()
                    externo.tipo_vinculo = request.POST.get('tipo_vinculo', '').strip()
                    externo.cargo = request.POST.get('cargo', '').strip() or None
                    externo.cidade = request.POST.get('cidade', '').strip() or None
                    externo.save()

            messages.success(request, 'Participante atualizado com sucesso!')
            return redirect('participante_list')
        except DatabaseError as e:
            messages.error(request, f'Erro ao atualizar participante: {e}')

    return render(request, 'eventos/participante_form.html', {
        'titulo': f'Editar participante — {participante.nome_participante}',
        'modo': 'editar',
        'participante': participante,
        'aluno': aluno,
        'professor': professor,
        'externo': externo,
        'categoria_atual': categoria_atual,
    })


def participante_delete(request, cpf):
    participante = get_object_or_404(Participante, pk=cpf)
    evento_id = request.GET.get('evento') or request.POST.get('evento')
    if request.method == 'POST':
        try:
            participante.delete()
            messages.success(request, 'Participante excluído com sucesso!')
        except (IntegrityError, DatabaseError):
            messages.error(
                request,
                'Não é possível excluir este participante porque ele possui inscrições registradas.'
            )
        if evento_id and str(evento_id).isdigit():
            return redirect(f"/participantes/?evento={evento_id}")
        return redirect('participante_list')

    return render(request, 'eventos/participante_delete.html', {
        'participante': participante,
        'categoria': _identificar_categoria(participante),
        'evento_id': evento_id,
    })

def participante_inscrever(request, cpf):
    participante = get_object_or_404(Participante, pk=cpf)
    evento_id = request.GET.get('evento') or request.POST.get('evento')
    atividades = Atividade.objects.select_related('codigo_evento').order_by(
        'codigo_evento__nome_evento', 'titulo'
    )
    if evento_id and str(evento_id).isdigit():
        atividades = atividades.filter(codigo_evento_id=int(evento_id))

    if request.method == 'POST':
        atividade_id = request.POST.get('atividade')
        status = request.POST.get('status', 'Confirmada')
        atividade = get_object_or_404(Atividade, pk=atividade_id)

        try:
            _, created = Inscricao.objects.get_or_create(
                cpf_participante=participante,
                codigo_atividade=atividade,
                defaults={
                    'data_inscricao': timezone.localdate(),
                    'status': status,
                },
            )
            if created:
                messages.success(
                    request,
                    f'{participante.nome_participante} inscrito em "{atividade.titulo}"!'
                )
            else:
                messages.warning(
                    request,
                    f'{participante.nome_participante} já está inscrito em "{atividade.titulo}".'
                )
            return redirect('participante_list')
        except DatabaseError as e:
            messages.error(request, f'Erro ao realizar inscrição: {e}')

    return render(request, 'eventos/participante_inscrever.html', {
        'participante': participante,
        'atividades': atividades,
        'evento_id': evento_id,
    })


def inscricao_checkin_rapido(request, inscricao_id):
    inscricao = get_object_or_404(Inscricao, pk=inscricao_id)
    if request.method == 'POST':
        try:
            inscricao.data_hora_checkin = timezone.now()
            inscricao.status = 'Confirmada'
            inscricao.save()
            messages.success(
                request,
                f'Check-in registrado para {inscricao.cpf_participante.nome_participante} em "{inscricao.codigo_atividade.titulo}".'
            )
        except DatabaseError as e:
            messages.error(request, str(e))
    return redirect('participante_list')


def evento_list(request):
    q = request.GET.get('q', '').strip()
    eventos = Evento.objects.order_by('codigo_evento')
    if q:
        eventos = eventos.filter(nome_evento__icontains=q)
    return render(request, 'eventos/evento_list.html', {
        'eventos': eventos,
        'q': q,
    })


def evento_create(request):
    if request.method == 'POST':
        form = EventoForm(request.POST)
        if form.is_valid():
            try:
                form.save()
                messages.success(request, 'Evento criado com sucesso!')
                return redirect('evento_list')
            except DatabaseError as e:
                messages.error(request, f'Erro ao criar evento: {e}')
    else:
        form = EventoForm()
    return render(request, 'eventos/form.html', {
        'form': form,
        'titulo': 'Novo evento',
    })


def evento_detail(request, pk):
    evento = get_object_or_404(Evento, pk=pk)
    atividades = Atividade.objects.filter(codigo_evento=evento).order_by('codigo_atividade')
    return render(request, 'eventos/evento_detail.html', {
        'evento': evento,
        'atividades': atividades,
    })


def evento_update(request, pk):
    evento = get_object_or_404(Evento, pk=pk)
    if request.method == 'POST':
        form = EventoForm(request.POST, instance=evento)
        if form.is_valid():
            try:
                form.save()
                messages.success(request, 'Evento atualizado com sucesso!')
                return redirect('evento_list')
            except DatabaseError as e:
                messages.error(request, f'Erro ao atualizar evento: {e}')
    else:
        form = EventoForm(instance=evento)
    return render(request, 'eventos/form.html', {
        'form': form,
        'titulo': f'Editar evento — {evento.nome_evento}',
    })


def evento_delete(request, pk):
    evento = get_object_or_404(Evento, pk=pk)
    if request.method == 'POST':
        try:
            evento.delete()
            messages.success(request, 'Evento excluído com sucesso!')
            return redirect('evento_list')
        except (IntegrityError, DatabaseError):
            messages.error(
                request,
                'Não é possível excluir este evento porque há atividades vinculadas a ele.'
            )
            return redirect('evento_list')
    return render(request, 'eventos/evento_delete.html', {'evento': evento})


def atividade_list(request, evento_pk):
    evento = get_object_or_404(Evento, pk=evento_pk)
    atividades = Atividade.objects.filter(codigo_evento=evento).order_by('codigo_atividade')
    return render(request, 'eventos/atividade_list.html', {
        'evento': evento,
        'atividades': atividades,
    })


def atividade_create(request, evento_pk):
    evento = get_object_or_404(Evento, pk=evento_pk)
    if request.method == 'POST':
        form = AtividadeForm(request.POST)
        if form.is_valid():
            atividade = form.save(commit=False)
            atividade.codigo_evento = evento
            try:
                atividade.save()
                messages.success(request, 'Atividade criada com sucesso!')
                return redirect('atividade_list', evento_pk=evento.pk)
            except DatabaseError as e:
                messages.error(request, f'Erro ao salvar atividade: {e}')
    else:
        form = AtividadeForm()
    return render(request, 'eventos/atividade_form.html', {
        'form': form,
        'evento': evento,
        'titulo': f'Nova atividade — {evento.nome_evento}',
    })


def atividade_update(request, evento_pk, pk):
    evento = get_object_or_404(Evento, pk=evento_pk)
    atividade = get_object_or_404(Atividade, pk=pk, codigo_evento=evento)
    if request.method == 'POST':
        form = AtividadeForm(request.POST, instance=atividade)
        if form.is_valid():
            try:
                form.save()
                messages.success(request, 'Atividade atualizada com sucesso!')
                return redirect('atividade_list', evento_pk=evento.pk)
            except DatabaseError as e:
                messages.error(request, f'Erro ao atualizar atividade: {e}')
    else:
        form = AtividadeForm(instance=atividade)
    return render(request, 'eventos/atividade_form.html', {
        'form': form,
        'evento': evento,
        'atividade': atividade,
        'titulo': f'Editar atividade — {atividade.titulo}',
    })


def atividade_delete(request, evento_pk, pk):
    evento = get_object_or_404(Evento, pk=evento_pk)
    atividade = get_object_or_404(Atividade, pk=pk, codigo_evento=evento)
    if request.method == 'POST':
        try:
            atividade.delete()
            messages.success(request, 'Atividade excluída com sucesso!')
            return redirect('atividade_list', evento_pk=evento.pk)
        except (IntegrityError, DatabaseError):
            messages.error(
                request,
                'Não é possível excluir esta atividade porque existem inscrições vinculadas.'
            )
            return redirect('atividade_list', evento_pk=evento.pk)
    return render(request, 'eventos/atividade_delete.html', {
        'evento': evento,
        'atividade': atividade,
    })


def inscricao_list(request):
    inscricoes = Inscricao.objects.select_related(
        'cpf_participante',
        'codigo_atividade',
    ).order_by('id_inscricao')
    return render(request, 'eventos/inscricao_list.html', {'inscricoes': inscricoes})


def inscricao_multipla(request):
    participantes = Participante.objects.order_by('nome_participante')
    atividades = Atividade.objects.select_related('codigo_evento').order_by('titulo')

    if request.method == 'POST':
        cpf = request.POST.get('participante')
        ids_atividades = request.POST.getlist('atividades')
        participante = get_object_or_404(Participante, pk=cpf)

        criadas = 0
        for atv_id in ids_atividades:
            atividade = get_object_or_404(Atividade, pk=atv_id)
            try:
                _, created = Inscricao.objects.get_or_create(
                    cpf_participante=participante,
                    codigo_atividade=atividade,
                    defaults={
                        'data_inscricao': timezone.localdate(),
                        'status': 'Pendente',
                    },
                )
                if created:
                    criadas += 1
            except DatabaseError as e:
                messages.error(request, f'Erro na atividade {atividade.titulo}: {e}')

        messages.success(request, f'{criadas} inscrição(ões) registrada(s).')
        return redirect('inscricao_list')

    return render(request, 'eventos/inscricao_multipla.html', {
        'participantes': participantes,
        'atividades': atividades,
    })


def inscricao_checkin(request, pk):
    inscricao = get_object_or_404(Inscricao, pk=pk)
    if request.method == 'POST':
        form = CheckinForm(request.POST, instance=inscricao)
        if form.is_valid():
            try:
                obj = form.save(commit=False)
                if obj.data_hora_checkin and obj.status == 'Pendente':
                    obj.status = 'Confirmada'
                obj.save()
                messages.success(request, 'Check-in / avaliação salvo com sucesso!')
                return redirect('inscricao_list')
            except DatabaseError as e:
                messages.error(request, str(e))
    else:
        form = CheckinForm(instance=inscricao)

    return render(request, 'eventos/form.html', {
        'form': form,
        'titulo': f'Check-in / Avaliação — Inscrição #{inscricao.pk}',
    })


def _rodar_sql(sql, params=None):
    with connection.cursor() as cursor:
        cursor.execute(sql, params or [])
        colunas = [col[0] for col in cursor.description]
        linhas = cursor.fetchall()
    return colunas, linhas


def relatorio_join(request):
    colunas, linhas = _rodar_sql("""
        SELECT e.nome_evento, a.titulo AS atividade, p.nome_palestrante, s.nome_sala
        FROM ATIVIDADE a
        JOIN EVENTO e ON e.codigo_evento = a.codigo_evento
        JOIN MINISTRA m ON m.codigo_atividade = a.codigo_atividade
        JOIN PALESTRANTE p ON p.cpf_palestrante = m.cpf_palestrante
        JOIN SALA s ON s.codigo_sala = m.codigo_sala
        ORDER BY e.nome_evento, a.titulo
    """)
    return render(request, 'eventos/relatorio.html', {
        'titulo': 'Cronograma (JOIN)',
        'colunas': colunas,
        'linhas': linhas,
        'mostrar_filtro': False,
    })


def relatorio_group(request):
    colunas, linhas = _rodar_sql("""
        SELECT e.nome_evento, COUNT(a.codigo_atividade) AS total_atividades
        FROM EVENTO e
        LEFT JOIN ATIVIDADE a ON a.codigo_evento = e.codigo_evento
        GROUP BY e.codigo_evento, e.nome_evento
        ORDER BY e.codigo_evento
    """)
    return render(request, 'eventos/relatorio.html', {
        'titulo': 'Atividades por Evento (GROUP BY)',
        'colunas': colunas,
        'linhas': linhas,
        'mostrar_filtro': False,
    })


def relatorio_having(request):
    minimo = int(request.GET.get('min', 1) or 1)
    colunas, linhas = _rodar_sql("""
        SELECT e.nome_evento, COUNT(i.id_inscricao) AS total_inscritos
        FROM EVENTO e
        LEFT JOIN ATIVIDADE a ON a.codigo_evento = e.codigo_evento
        LEFT JOIN INSCRICAO i ON i.codigo_atividade = a.codigo_atividade
        GROUP BY e.codigo_evento, e.nome_evento
        HAVING COUNT(i.id_inscricao) >= %s
        ORDER BY total_inscritos DESC
    """, [minimo])
    return render(request, 'eventos/relatorio.html', {
        'titulo': 'Eventos por Mínimo de Inscritos (HAVING)',
        'colunas': colunas,
        'linhas': linhas,
        'mostrar_filtro': True,
        'minimo': minimo,
    })
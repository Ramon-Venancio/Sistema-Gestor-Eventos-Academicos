from django import forms

from .models import Atividade, Certificado, Evento, Inscricao  # inclua Atividade aqui


class AtividadeForm(forms.ModelForm):
    class Meta:
        model = Atividade
        fields = ['titulo', 'tipo', 'carga_horaria', 'descricao_atividade']
        
class EventoForm(forms.ModelForm):
    class Meta:
        model = Evento
        fields = ['nome_evento', 'data_inicio', 'data_fim',
                  'descricao_evento', 'email_contato']
        widgets = {
            'data_inicio': forms.DateInput(format='%Y-%m-%d', attrs={'type': 'date'}),
            'data_fim': forms.DateInput(format='%Y-%m-%d', attrs={'type': 'date'}),
        }


class CheckinForm(forms.ModelForm):
    class Meta:
        model = Inscricao
        fields = ['data_hora_checkin', 'nota_avaliacao', 'comentario']
        widgets = {
            'data_hora_checkin': forms.DateTimeInput(
                format='%Y-%m-%dT%H:%M', attrs={'type': 'datetime-local'}),
        }


class CertificadoForm(forms.ModelForm):
    class Meta:
        model = Certificado
        fields = ['codigo_de_validacao', 'id_inscricao', 'data_de_emissao',
                  'carga_horaria_certificada']
        widgets = {
            'data_de_emissao': forms.DateInput(format='%Y-%m-%d', attrs={'type': 'date'}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['id_inscricao'].label_from_instance = (
            lambda i: f'#{i.pk} - CPF {i.cpf_participante_id} - atividade {i.codigo_atividade_id}')

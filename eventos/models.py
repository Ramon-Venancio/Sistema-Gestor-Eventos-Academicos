# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#   * Rearrange models' order
#   * Make sure each model has one field with primary_key=True
#   * Make sure each ForeignKey and OneToOneField has `on_delete` set to the desired behavior
#   * Remove `managed = False` lines if you wish to allow Django to create, modify, and delete the table
# Feel free to rename the models, but don't rename db_table values or field names.
from django.db import models


class Aluno(models.Model):
    cpf_participante = models.OneToOneField('Participante', models.DB_CASCADE, db_column='cpf_participante', primary_key=True)
    matricula = models.CharField(unique=True, max_length=50)
    curso = models.CharField(max_length=255)
    semestre = models.IntegerField(blank=True, null=True)
    campus = models.CharField(max_length=255, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'aluno'


class Atividade(models.Model):
    codigo_atividade = models.AutoField(primary_key=True)
    codigo_evento = models.ForeignKey('Evento', models.DO_NOTHING, db_column='codigo_evento')
    titulo = models.CharField(max_length=255)
    tipo = models.CharField(max_length=100)
    carga_horaria = models.IntegerField()
    descricao_atividade = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'atividade'


class AtividadePreRequisito(models.Model):
    pk = models.CompositePrimaryKey('codigo_atividade', 'pre_requisito')
    codigo_atividade = models.ForeignKey(Atividade, models.DB_CASCADE, db_column='codigo_atividade')
    pre_requisito = models.CharField(max_length=255)

    class Meta:
        managed = False
        db_table = 'atividade_pre_requisito'


class Certificado(models.Model):
    codigo_de_validacao = models.CharField(primary_key=True, max_length=100)
    id_inscricao = models.OneToOneField('Inscricao', models.DO_NOTHING, db_column='id_inscricao')
    data_de_emissao = models.DateField()
    carga_horaria_certificada = models.IntegerField()
    link_pdf = models.CharField(max_length=255, blank=True, null=True)
    observacao = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'certificado'


class Evento(models.Model):
    codigo_evento = models.AutoField(primary_key=True)
    nome_evento = models.CharField(max_length=255)
    data_inicio = models.DateField()
    data_fim = models.DateField()
    descricao_evento = models.TextField(blank=True, null=True)
    email_contato = models.CharField(max_length=255, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'evento'


class Externo(models.Model):
    cpf_participante = models.OneToOneField('Participante', models.DB_CASCADE, db_column='cpf_participante', primary_key=True)
    instituicao_origem = models.CharField(max_length=255)
    tipo_vinculo = models.CharField(max_length=100)
    cargo = models.CharField(max_length=255, blank=True, null=True)
    cidade = models.CharField(max_length=255, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'externo'


class Inscricao(models.Model):
    id_inscricao = models.AutoField(primary_key=True)
    cpf_participante = models.ForeignKey('Participante', models.DO_NOTHING, db_column='cpf_participante')
    codigo_atividade = models.ForeignKey(Atividade, models.DO_NOTHING, db_column='codigo_atividade')
    data_inscricao = models.DateField()
    status = models.CharField(max_length=50)
    data_hora_checkin = models.DateTimeField(blank=True, null=True)
    nota_avaliacao = models.DecimalField(max_digits=4, decimal_places=2, blank=True, null=True)
    comentario = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'inscricao'
        unique_together = (('cpf_participante', 'codigo_atividade'),)


class Ministra(models.Model):
    pk = models.CompositePrimaryKey('cpf_palestrante', 'codigo_atividade')
    cpf_palestrante = models.ForeignKey('Palestrante', models.DO_NOTHING, db_column='cpf_palestrante')
    codigo_atividade = models.ForeignKey(Atividade, models.DB_CASCADE, db_column='codigo_atividade')
    codigo_sala = models.ForeignKey('Sala', models.DO_NOTHING, db_column='codigo_sala')

    class Meta:
        managed = False
        db_table = 'ministra'


class Palestrante(models.Model):
    cpf_palestrante = models.CharField(primary_key=True, max_length=11)
    nome_palestrante = models.CharField(max_length=255)
    email_palestrante = models.CharField(max_length=255)
    minicurriculo = models.TextField()
    instituicao = models.CharField(max_length=255, blank=True, null=True)
    link_lattes = models.CharField(max_length=255, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'palestrante'


class Participante(models.Model):
    cpf_participante = models.CharField(primary_key=True, max_length=11)
    nome_participante = models.CharField(max_length=255)
    email_participante = models.CharField(max_length=255)
    telefone_participante = models.CharField(max_length=20, blank=True, null=True)
    data_nascimento = models.DateField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'participante'


class Professor(models.Model):
    cpf_participante = models.OneToOneField(Participante, models.DB_CASCADE, db_column='cpf_participante', primary_key=True)
    titulacao = models.CharField(max_length=100)
    departamento = models.CharField(max_length=255)
    link_lattes = models.CharField(max_length=255, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'professor'


class ProfessorAreaPesquisa(models.Model):
    pk = models.CompositePrimaryKey('cpf_participante', 'area_pesquisa')
    cpf_participante = models.ForeignKey(Professor, models.DB_CASCADE, db_column='cpf_participante')
    area_pesquisa = models.CharField(max_length=255)

    class Meta:
        managed = False
        db_table = 'professor_area_pesquisa'


class Sala(models.Model):
    codigo_sala = models.AutoField(primary_key=True)
    nome_sala = models.CharField(max_length=100)
    capacidade = models.IntegerField()
    bloco = models.CharField(max_length=50, blank=True, null=True)
    andar = models.IntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'sala'

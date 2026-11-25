from django.urls import path
from . import views

urlpatterns = [
    path('', views.evento_list, name='evento_list'),
    path('eventos/novo/', views.evento_create, name='evento_create'),
    path('eventos/<int:pk>/', views.evento_detail, name='evento_detail'),
    path('eventos/<int:pk>/editar/', views.evento_update, name='evento_update'),
    path('eventos/<int:pk>/excluir/', views.evento_delete, name='evento_delete'),
path('eventos/<int:evento_pk>/participantes/', views.evento_participante_list, name='evento_participante_list'),
    path('eventos/<int:evento_pk>/atividades/', views.atividade_list, name='atividade_list'),
    path('eventos/<int:evento_pk>/atividades/nova/', views.atividade_create, name='atividade_create'),
    path('eventos/<int:evento_pk>/atividades/<int:pk>/editar/', views.atividade_update, name='atividade_update'),
    path('eventos/<int:evento_pk>/atividades/<int:pk>/excluir/', views.atividade_delete, name='atividade_delete'),

    path('inscricoes/', views.inscricao_list, name='inscricao_list'),
    path('inscricoes/nova/', views.inscricao_multipla, name='inscricao_multipla'),
    path('inscricoes/<int:pk>/checkin/', views.inscricao_checkin, name='inscricao_checkin'),

    path('certificados/novo/', views.certificado_create, name='certificado_create'),

    path('relatorios/join/', views.relatorio_join, name='relatorio_join'),
    path('relatorios/group-by/', views.relatorio_group, name='relatorio_group'),
    path('relatorios/having/', views.relatorio_having, name='relatorio_having'),
    path('participantes/', views.participante_list, name='participante_list'),
    path('participantes/novo/', views.participante_create, name='participante_create'),
    path('participantes/<str:cpf>/editar/', views.participante_update, name='participante_update'),
    path('participantes/<str:cpf>/excluir/', views.participante_delete, name='participante_delete'),
    path('participantes/<str:cpf>/inscrever/', views.participante_inscrever, name='participante_inscrever'),
    path('inscricoes/<int:inscricao_id>/checkin-rapido/', views.inscricao_checkin_rapido, name='inscricao_checkin_rapido'),
    path('certificados/', views.certificado_list, name='certificado_list'),
    path('certificados/novo/', views.certificado_create, name='certificado_create'),
    path('certificados/<str:codigo>/excluir/', views.certificado_delete, name='certificado_delete'),
    path('inscricoes/<int:inscricao_id>/status/<str:novo_status>/', views.inscricao_alterar_status, name='inscricao_alterar_status'),
    path('inscricoes/<int:inscricao_id>/excluir/', views.inscricao_delete, name='inscricao_delete'),
]
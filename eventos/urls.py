from django.urls import path

from . import views

urlpatterns = [
    path('', views.evento_list, name='evento_list'),
    path('eventos/novo/', views.evento_form, name='evento_create'),
    path('eventos/<int:pk>/', views.evento_detail, name='evento_detail'),
    path('eventos/<int:pk>/editar/', views.evento_form, name='evento_update'),
    path('eventos/<int:pk>/excluir/', views.evento_delete, name='evento_delete'),
    path('inscricoes/', views.inscricao_list, name='inscricao_list'),
    path('inscricoes/nova/', views.inscricao_multipla, name='inscricao_multipla'),
    path('inscricoes/<int:pk>/checkin/', views.inscricao_checkin, name='inscricao_checkin'),
    path('certificados/novo/', views.certificado_create, name='certificado_create'),
    path('relatorios/join/', views.relatorio_join, name='relatorio_join'),
    path('relatorios/group-by/', views.relatorio_group, name='relatorio_group'),
    path('relatorios/having/', views.relatorio_having, name='relatorio_having'),
    path('eventos/<int:evento_pk>/atividades/nova/', views.atividade_create,
        name='atividade_create'),
]

from django.apps import apps
from django.contrib import admin
from django.db.models import CompositePrimaryKey

for model in apps.get_app_config('eventos').get_models():
    if isinstance(model._meta.pk, CompositePrimaryKey):
        continue  # o admin não suporta chave composta
    admin.site.register(model)
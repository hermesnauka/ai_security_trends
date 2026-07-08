from django.contrib import admin

from .models import Framework


@admin.register(Framework)
class FrameworkAdmin(admin.ModelAdmin):
    list_display = ["code", "name", "version"]

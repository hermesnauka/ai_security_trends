from django.apps import AppConfig


class ExportConfig(AppConfig):
    """Phase 6 scope (Celery-backed CSV/PDF export) - app registered now, no
    tasks/views until then."""

    default_auto_field = "django.db.models.BigAutoField"
    name = "export"

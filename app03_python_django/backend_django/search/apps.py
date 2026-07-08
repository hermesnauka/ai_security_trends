from django.apps import AppConfig


class SearchConfig(AppConfig):
    """Phase 6 scope (PostgreSQL full-text search) - app registered now,
    no models/views until then."""

    default_auto_field = "django.db.models.BigAutoField"
    name = "search"

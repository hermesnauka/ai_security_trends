from django.apps import AppConfig


class AccountsConfig(AppConfig):
    """Wires JWT auth (rest_framework_simplejwt) for Phase 1's editor/admin
    role skeleton. Full django-allauth (social login, registration flows)
    from PLAN.md's stack table is deferred - not needed until there's an
    actual admin CRUD endpoint to protect, same deferral app01_react/
    app02_angular made for their own admin auth."""

    default_auto_field = "django.db.models.BigAutoField"
    name = "accounts"

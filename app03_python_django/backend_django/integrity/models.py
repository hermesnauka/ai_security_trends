from django.db import models


class ContentHash(models.Model):
    """Phase 3 scope - backs HashVerificationService (PLAN.md section 10/11).
    Schema exists now; the service itself (hashlib.sha256 verification,
    called only from the management command and the Celery task, never a
    request-handling view) is not implemented yet."""

    file_name = models.CharField(max_length=100, unique=True)
    sha256_hash = models.CharField(max_length=64)
    verified_at = models.DateTimeField(null=True, blank=True)
    is_valid = models.BooleanField(default=False)
    verified_by = models.CharField(max_length=30, default="django-integrity-service")

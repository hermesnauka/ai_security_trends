from django.db import models


class CornucopiaCard(models.Model):
    """Phase 3 scope (the six OWASP Cornucopia YAML decks) - schema exists now,
    not loaded or served via API yet. See PLAN.md section 10 for the
    YAML -> Django ingestion pipeline this table is designed for."""

    card_id = models.CharField(max_length=10, unique=True)
    suit_code = models.CharField(max_length=10)
    suit_name = models.CharField(max_length=100)
    edition = models.CharField(max_length=20)
    value = models.CharField(max_length=2)
    is_critical = models.BooleanField(default=False)
    description_en = models.TextField()
    description_pl = models.TextField(blank=True)
    misc_note = models.TextField(blank=True)
    source_url = models.URLField(blank=True)
    owasp_refs = models.JSONField(default=list, blank=True)
    mitre_refs = models.JSONField(default=list, blank=True)
    content_sha256 = models.CharField(max_length=64, blank=True)

    class Meta:
        indexes = [
            models.Index(fields=["suit_code"]),
            models.Index(fields=["edition"]),
        ]

    def __str__(self) -> str:
        return self.card_id

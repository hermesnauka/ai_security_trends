from django.db import models

from frameworks.models import Framework


class Severity(models.TextChoices):
    CRITICAL = "CRITICAL"
    HIGH = "HIGH"
    MEDIUM = "MEDIUM"
    LOW = "LOW"
    INFO = "INFO"


class Threat(models.Model):
    framework = models.ForeignKey(Framework, on_delete=models.PROTECT, related_name="threats")
    code = models.CharField(max_length=40)
    title = models.CharField(max_length=300)
    severity = models.CharField(max_length=10, choices=Severity.choices)
    category = models.CharField(max_length=100, blank=True)
    description = models.TextField(blank=True)
    attack_vector = models.TextField(blank=True)
    attack_surface = models.TextField(blank=True)
    stride = models.CharField(max_length=6, blank=True)  # e.g. "SI" for combined Spoof+InfoDisclosure
    tags = models.JSONField(default=list, blank=True)

    class Meta:
        ordering = ["framework__code", "code"]
        constraints = [
            models.UniqueConstraint(fields=["framework", "code"], name="uq_threat_framework_code"),
        ]

    def __str__(self) -> str:
        return f"{self.code} {self.title}"


class ThreatTranslation(models.Model):
    """i18n content table (Phase 5 scope) - schema exists now, not served via API yet."""

    LOCALE_CHOICES = [("pl", "Polski"), ("en", "English")]

    threat = models.ForeignKey(Threat, on_delete=models.CASCADE, related_name="translations")
    locale = models.CharField(max_length=5, choices=LOCALE_CHOICES)
    title = models.CharField(max_length=300)
    description = models.TextField(blank=True)
    attack_vector = models.TextField(blank=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["threat", "locale"], name="uq_threattranslation_threat_locale"),
        ]


class MitigationType(models.TextChoices):
    PREVENTIVE = "PREVENTIVE"
    DETECTIVE = "DETECTIVE"
    CORRECTIVE = "CORRECTIVE"
    COMPENSATING = "COMPENSATING"


class Effort(models.TextChoices):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"


class Effectiveness(models.TextChoices):
    PARTIAL = "PARTIAL"
    SIGNIFICANT = "SIGNIFICANT"
    FULL = "FULL"


class Mitigation(models.Model):
    """Phase 2 scope (nested on Threat Detail) - schema exists now, not served via API yet."""

    threat = models.ForeignKey(Threat, null=True, blank=True, on_delete=models.CASCADE, related_name="mitigations")
    card = models.ForeignKey(
        "cards.CornucopiaCard", null=True, blank=True, on_delete=models.CASCADE, related_name="mitigations"
    )
    title = models.CharField(max_length=300)
    description = models.TextField(blank=True)
    mitigation_type = models.CharField(max_length=15, choices=MitigationType.choices)
    effort = models.CharField(max_length=10, choices=Effort.choices)
    effectiveness = models.CharField(max_length=15, choices=Effectiveness.choices)


class Language(models.TextChoices):
    PYTHON = "PYTHON"
    JAVA = "JAVA"
    GO = "GO"
    SCALA = "SCALA"
    LUA = "LUA"


class SampleType(models.TextChoices):
    ATTACK_DEMO = "ATTACK_DEMO"
    DEFENSE = "DEFENSE"


class CodeSample(models.Model):
    """Phase 4 scope - schema exists now, not served via API yet."""

    mitigation = models.ForeignKey(Mitigation, on_delete=models.CASCADE, related_name="code_samples")
    language = models.CharField(max_length=10, choices=Language.choices)
    sample_type = models.CharField(max_length=12, choices=SampleType.choices)
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    code = models.TextField()
    framework_hint = models.CharField(max_length=100, blank=True)
    version_note = models.CharField(max_length=100, blank=True)

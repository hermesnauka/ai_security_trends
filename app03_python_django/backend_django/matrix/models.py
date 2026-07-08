from django.db import models

from threats.models import Threat


class Relationship(models.TextChoices):
    EQUIVALENT = "EQUIVALENT"
    RELATED = "RELATED"
    MAPS_TO = "MAPS_TO"
    PARENT_CHILD = "PARENT_CHILD"


class CrossReference(models.Model):
    """Phase 2 scope (cross-framework matrix) - schema exists now, not served
    via API yet."""

    source = models.ForeignKey(Threat, on_delete=models.CASCADE, related_name="+")
    target = models.ForeignKey(Threat, on_delete=models.CASCADE, related_name="+")
    relationship = models.CharField(max_length=15, choices=Relationship.choices)
    description = models.TextField(blank=True)

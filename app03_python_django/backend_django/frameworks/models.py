from django.db import models


class Framework(models.Model):
    code = models.CharField(max_length=32, unique=True)
    name = models.CharField(max_length=200)
    version = models.CharField(max_length=20)
    description = models.TextField(blank=True)
    reference_url = models.URLField(blank=True)

    class Meta:
        ordering = ["code"]

    def __str__(self) -> str:
        return self.code

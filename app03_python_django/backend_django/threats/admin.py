from django.contrib import admin

from .models import CodeSample, Mitigation, Threat, ThreatTranslation


@admin.register(Threat)
class ThreatAdmin(admin.ModelAdmin):
    list_display = ["code", "title", "framework", "severity"]
    list_filter = ["framework", "severity"]


admin.site.register(ThreatTranslation)
admin.site.register(Mitigation)
admin.site.register(CodeSample)

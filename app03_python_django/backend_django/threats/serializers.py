from rest_framework import serializers

from .models import Threat


class ThreatSummarySerializer(serializers.ModelSerializer):
    framework_code = serializers.CharField(source="framework.code", read_only=True)

    class Meta:
        model = Threat
        fields = ["id", "framework_code", "code", "title", "severity", "category", "stride", "tags"]


class ThreatDetailSerializer(serializers.ModelSerializer):
    framework_code = serializers.CharField(source="framework.code", read_only=True)
    framework_name = serializers.CharField(source="framework.name", read_only=True)

    class Meta:
        model = Threat
        fields = [
            "id",
            "framework_code",
            "framework_name",
            "code",
            "title",
            "severity",
            "category",
            "description",
            "attack_vector",
            "attack_surface",
            "stride",
            "tags",
        ]

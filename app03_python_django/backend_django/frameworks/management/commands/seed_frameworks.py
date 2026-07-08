import json

from django.conf import settings
from django.core.management.base import BaseCommand
from django.db import transaction

from frameworks.models import Framework
from threats.models import Threat

FIXTURE_FILES = [
    "owasp_web_top10.json",
    "owasp_llm_top10.json",
    "mitre_atlas.json",
    "comptia_secai.json",
]


class Command(BaseCommand):
    help = (
        "Seed OWASP_WEB, OWASP_LLM, MITRE_ATLAS, and COMPTIA_SECAI frameworks + "
        "threats from data/*.json fixtures (Phase 1 scope - the remaining "
        "OWASP variants and the six Cornucopia card decks are Phase 3+/6+, "
        "loaded by cards.management.commands.load_cornucopia_cards later)."
    )

    @transaction.atomic
    def handle(self, *args, **options):
        data_dir = settings.BASE_DIR / "data"
        for filename in FIXTURE_FILES:
            path = data_dir / filename
            with open(path, encoding="utf-8") as f:
                payload = json.load(f)

            framework, created = Framework.objects.update_or_create(
                code=payload["framework"]["code"],
                defaults=payload["framework"],
            )
            self.stdout.write(f"{'Created' if created else 'Updated'} framework {framework.code}")

            for threat_data in payload["threats"]:
                Threat.objects.update_or_create(
                    framework=framework,
                    code=threat_data["code"],
                    defaults={**threat_data, "framework": framework},
                )

            self.stdout.write(f"  seeded {len(payload['threats'])} threats")

        total_frameworks = Framework.objects.count()
        total_threats = Threat.objects.count()
        self.stdout.write(self.style.SUCCESS(f"Done: {total_frameworks} frameworks, {total_threats} threats."))

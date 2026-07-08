from django.views.generic import TemplateView
from rest_framework.generics import ListAPIView, RetrieveAPIView

from threats.models import Threat

from .models import Framework
from .serializers import FrameworkSerializer


class HomeView(TemplateView):
    """Server-rendered home page - framework tiles + quick search + disclaimer
    per PLAN.md's page structure. Search here is a plain GET-and-filter
    (?q=) rather than HTMX-driven partial swaps; that interactivity is Phase 2
    scope on the dedicated /threats/ browser, not this page."""

    template_name = "home.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        q = self.request.GET.get("q", "").strip()
        frameworks = Framework.objects.all()
        if q:
            frameworks = frameworks.filter(name__icontains=q) | frameworks.filter(code__icontains=q)
        context["frameworks"] = frameworks
        context["framework_count"] = Framework.objects.count()
        context["threat_count"] = Threat.objects.count()
        context["query"] = q
        return context


class FrameworkListView(ListAPIView):
    queryset = Framework.objects.all()
    serializer_class = FrameworkSerializer
    pagination_class = None  # PLAN.md's frameworks endpoint returns a plain list, not paginated


class FrameworkDetailView(RetrieveAPIView):
    queryset = Framework.objects.all()
    serializer_class = FrameworkSerializer
    lookup_field = "code"

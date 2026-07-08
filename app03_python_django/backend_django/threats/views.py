from django.db.models import Q
from rest_framework.generics import ListAPIView, RetrieveAPIView

from .models import Threat
from .serializers import ThreatDetailSerializer, ThreatSummarySerializer


class ThreatListView(ListAPIView):
    serializer_class = ThreatSummarySerializer

    def get_queryset(self):
        qs = Threat.objects.select_related("framework").all()
        params = self.request.query_params

        framework_code = params.get("framework")
        if framework_code:
            qs = qs.filter(framework__code__iexact=framework_code)

        severity = params.get("severity")
        if severity:
            qs = qs.filter(severity__iexact=severity)

        stride = params.get("stride")
        if stride:
            qs = qs.filter(stride__icontains=stride.upper())

        category = params.get("category")
        if category:
            qs = qs.filter(category__iexact=category)

        tag = params.get("tag")
        if tag:
            qs = qs.filter(tags__contains=[tag])

        q = params.get("q")
        if q:
            qs = qs.filter(Q(title__icontains=q) | Q(description__icontains=q))

        return qs


class ThreatDetailView(RetrieveAPIView):
    queryset = Threat.objects.select_related("framework").all()
    serializer_class = ThreatDetailSerializer

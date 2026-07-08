from django.urls import path

from .views import ThreatDetailView, ThreatListView

urlpatterns = [
    path("", ThreatListView.as_view(), name="threat-list"),
    path("<int:pk>/", ThreatDetailView.as_view(), name="threat-detail"),
]

from django.urls import path

from .views import FrameworkDetailView, FrameworkListView

urlpatterns = [
    path("", FrameworkListView.as_view(), name="framework-list"),
    path("<str:code>/", FrameworkDetailView.as_view(), name="framework-detail"),
]

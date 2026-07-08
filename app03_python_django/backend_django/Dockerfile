# Single image for both the Django web process and the Celery worker/beat
# processes, per PLAN.md section 5 Phase 7 - "same image, different
# entrypoints". docker-compose.yml's `command:` override picks which.
FROM python:3.13-slim

WORKDIR /app

RUN addgroup --system threatcompass && adduser --system --group threatcompass

COPY pyproject.toml ./
RUN pip install --no-cache-dir \
    "Django>=5.2,<5.3" \
    "djangorestframework>=3.16,<3.17" \
    "drf-spectacular>=0.27,<0.28" \
    "djangorestframework-simplejwt>=5.3,<5.4" \
    "psycopg[binary]>=3.2,<3.3" \
    "django-redis>=5.4,<5.5" \
    "celery>=5.4,<5.5" \
    "redis>=5.0,<6.0" \
    "gunicorn>=22.0,<23.0" \
    "python-dotenv>=1.0,<2.0"

COPY . .

RUN chown -R threatcompass:threatcompass /app
USER threatcompass

EXPOSE 8000

CMD ["gunicorn", "threatcompass.wsgi:application", "--bind", "0.0.0.0:8000"]

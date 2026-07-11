# VULNERABLE — do not use in production
from django.db import connection

def find_user_by_name(request):
    name = request.GET["name"]
    with connection.cursor() as cursor:
        cursor.execute(f"SELECT id, email FROM users WHERE name = '{name}'")
        return cursor.fetchall()

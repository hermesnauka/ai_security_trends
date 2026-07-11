# SECURE pattern
from django.db import connection

def find_user_by_name(request):
    name = request.GET["name"]
    with connection.cursor() as cursor:
        # WHY: %s is a placeholder bound by the DB driver, never concatenated into the SQL text
        cursor.execute("SELECT id, email FROM users WHERE name = %s", [name])
        return cursor.fetchall()

// VULNERABLE — do not use in production
val name = request.getParameter("name")
val rs = statement.executeQuery(s"SELECT id, email FROM users WHERE name = '$name'")

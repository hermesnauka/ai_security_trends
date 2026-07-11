// VULNERABLE — do not use in production
String name = request.getParameter("name");
Statement stmt = connection.createStatement();
ResultSet rs = stmt.executeQuery("SELECT id, email FROM users WHERE name = '" + name + "'");

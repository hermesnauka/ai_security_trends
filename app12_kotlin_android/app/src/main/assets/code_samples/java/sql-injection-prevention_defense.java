// SECURE pattern
String name = request.getParameter("name");
// WHY: PreparedStatement sends the query shape and the value separately, so user input can never alter the query structure
PreparedStatement stmt = connection.prepareStatement("SELECT id, email FROM users WHERE name = ?");
stmt.setString(1, name);
ResultSet rs = stmt.executeQuery();

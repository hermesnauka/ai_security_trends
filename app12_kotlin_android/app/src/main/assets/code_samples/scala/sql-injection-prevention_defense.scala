// SECURE pattern
val name: String = request.getParameter("name")
// WHY: Slick's sql interpolator binds `name` as a bound parameter, not string-interpolated SQL text
val query = sql"SELECT id, email FROM users WHERE name = $name".as[(Long, String)]
db.run(query)

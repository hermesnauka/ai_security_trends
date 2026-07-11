// SECURE pattern
name := r.URL.Query().Get("name")
// WHY: pgx binds $1 as a parameter at the wire protocol level, never interpolated into the query text
rows, err := db.Query(context.Background(), "SELECT id, email FROM users WHERE name = $1", name)

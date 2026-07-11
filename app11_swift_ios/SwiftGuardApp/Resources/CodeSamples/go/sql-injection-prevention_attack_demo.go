// VULNERABLE — do not use in production
name := r.URL.Query().Get("name")
query := fmt.Sprintf("SELECT id, email FROM users WHERE name = '%s'", name)
rows, err := db.Query(query)

-- name: SearchThreats :many
-- D-02: this is the entire optional-filter surface for GET /api/v1/threats
-- as ONE statically-checked query - sqlc.narg() makes each filter nullable
-- at the parameter level, so there is no runtime query builder and no
-- string-concatenation path, satisfying the same guarantee app04_scala_react
-- gets from ZIO Quill's macros.
SELECT t.id, t.framework_id, t.code, t.title, t.severity, t.category,
       t.description, t.attack_vector, t.attack_surface, t.stride,
       t.cve_references, t.tags, f.code AS framework_code
FROM threat t
JOIN framework f ON f.id = t.framework_id
WHERE (sqlc.narg('framework_code')::text IS NULL OR f.code = sqlc.narg('framework_code')::text)
  AND (sqlc.narg('severity')::text IS NULL OR t.severity = sqlc.narg('severity')::text)
  AND (sqlc.narg('stride')::text IS NULL OR t.stride ILIKE '%' || sqlc.narg('stride')::text || '%')
  AND (sqlc.narg('category')::text IS NULL OR t.category = sqlc.narg('category')::text)
  AND (sqlc.narg('tag')::text IS NULL OR t.tags ILIKE '%' || sqlc.narg('tag')::text || '%')
  AND (
    sqlc.narg('q')::text IS NULL
    OR t.title ILIKE '%' || sqlc.narg('q')::text || '%'
    OR t.description ILIKE '%' || sqlc.narg('q')::text || '%'
  )
ORDER BY f.code, t.code;

-- name: GetThreatByID :one
SELECT t.id, t.framework_id, t.code, t.title, t.severity, t.category,
       t.description, t.attack_vector, t.attack_surface, t.stride,
       t.cve_references, t.tags, f.code AS framework_code, f.name AS framework_name
FROM threat t
JOIN framework f ON f.id = t.framework_id
WHERE t.id = $1;

-- name: UpsertThreat :exec
INSERT INTO threat (framework_id, code, title, severity, category, description, attack_vector, attack_surface, stride, tags)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
ON CONFLICT (framework_id, code) DO UPDATE SET
    title = EXCLUDED.title,
    severity = EXCLUDED.severity,
    category = EXCLUDED.category,
    description = EXCLUDED.description,
    attack_vector = EXCLUDED.attack_vector,
    attack_surface = EXCLUDED.attack_surface,
    stride = EXCLUDED.stride,
    tags = EXCLUDED.tags;

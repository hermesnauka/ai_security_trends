-- name: ListFrameworks :many
SELECT id, code, name, version, description, reference_url
FROM framework
ORDER BY code;

-- name: GetFrameworkByCode :one
SELECT id, code, name, version, description, reference_url
FROM framework
WHERE code = $1;

-- name: UpsertFramework :one
INSERT INTO framework (code, name, version, description, reference_url)
VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (code) DO UPDATE SET
    name = EXCLUDED.name,
    version = EXCLUDED.version,
    description = EXCLUDED.description,
    reference_url = EXCLUDED.reference_url
RETURNING id, code, name, version, description, reference_url;

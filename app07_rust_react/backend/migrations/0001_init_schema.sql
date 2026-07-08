-- RustBastion 2026 - Phase 1 schema
-- Mirrors app01_react's framework/threat tables exactly (see ../../CLAUDE.md
-- "Canonical Phase-1 API contract" and app01's V1__init_schema.sql), including
-- the comma-joined TEXT columns for stride/tags/cve_references (deliberately
-- not using native TEXT[], per app07_rust_react/CLAUDE.md's recorded decision).
--
-- Unlike app01, this migration does NOT pre-create Phase 2+ placeholder tables
-- (threat_translation, mitigation, code_sample, cross_reference,
-- cornucopia_card, content_hash) - app01 needed those so its Flyway history
-- stays linear from day one, but this is a fresh sqlx migration history with
-- no such constraint, and this app is scoped to Phase-1 parity only.

CREATE TABLE framework (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code           VARCHAR(64) NOT NULL UNIQUE,
    name           VARCHAR(255) NOT NULL,
    version        VARCHAR(32) NOT NULL,
    description    TEXT,
    reference_url  VARCHAR(512)
);

CREATE TABLE threat (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    framework_id    UUID NOT NULL REFERENCES framework(id) ON DELETE RESTRICT,
    code            VARCHAR(64) NOT NULL,
    title           VARCHAR(255) NOT NULL,
    severity        VARCHAR(16) NOT NULL,
    category        VARCHAR(128),
    description     TEXT,
    attack_vector   TEXT,
    attack_surface  TEXT,
    stride          VARCHAR(32),   -- comma-separated STRIDE letters, e.g. "S,T,E"
    cve_references  TEXT,          -- comma-separated CVE ids
    tags            TEXT,          -- comma-separated tags
    CONSTRAINT uq_threat_framework_code UNIQUE (framework_id, code)
);

CREATE INDEX idx_threat_framework_id ON threat(framework_id);
CREATE INDEX idx_threat_severity ON threat(severity);
CREATE INDEX idx_threat_category ON threat(category);

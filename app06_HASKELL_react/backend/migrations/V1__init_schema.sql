-- HaskShield 2026 -- Phase 1 schema.
-- Deliberately narrower than app01_react's V1: this only creates the two
-- tables Phase 1 actually serves (framework, threat). app01 also creates
-- threat_translation/mitigation/code_sample/cross_reference/cornucopia_card/
-- content_hash "ahead of schedule" for Flyway migration-history linearity --
-- a JPA/Flyway-specific concern that doesn't apply to this project's simple
-- custom migration runner. Add those tables in a later migration when a
-- later phase actually needs them.
--
-- stride/cve_references/tags are native TEXT[] here, not app01's
-- comma-joined TEXT column -- see CLAUDE.md "Known deliberate deviations".

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
    stride          TEXT[],
    cve_references  TEXT[],
    tags            TEXT[],
    CONSTRAINT uq_threat_framework_code UNIQUE (framework_id, code)
);

CREATE INDEX idx_threat_framework_id ON threat(framework_id);
CREATE INDEX idx_threat_severity ON threat(severity);
CREATE INDEX idx_threat_category ON threat(category);

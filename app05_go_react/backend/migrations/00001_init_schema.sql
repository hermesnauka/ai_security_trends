-- +goose Up
-- GoSentry 2026 - Phase 1 schema
-- Covers data model 5.2 (Framework) and 5.3 (Threat) as live sqlc-mapped
-- tables. Tables for 5.4-5.9 are created now so later phases can add goose
-- migrations that only ALTER, never re-create, keeping migration history
-- linear.

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
    category        VARCHAR(128) NOT NULL DEFAULT '',
    description     TEXT NOT NULL DEFAULT '',
    attack_vector   TEXT NOT NULL DEFAULT '',
    attack_surface  TEXT NOT NULL DEFAULT '',
    stride          VARCHAR(32) NOT NULL DEFAULT '',   -- comma-separated STRIDE letters, e.g. "S,T,E"
    cve_references  TEXT NOT NULL DEFAULT '',          -- comma-separated CVE ids
    tags            TEXT NOT NULL DEFAULT '',          -- comma-separated tags
    CONSTRAINT uq_threat_framework_code UNIQUE (framework_id, code)
);

CREATE INDEX idx_threat_framework_id ON threat(framework_id);
CREATE INDEX idx_threat_severity ON threat(severity);
CREATE INDEX idx_threat_category ON threat(category);

-- 5.4 ThreatTranslation (i18n, Phase 5) - table only, not sqlc-mapped yet
CREATE TABLE threat_translation (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    threat_id     UUID NOT NULL REFERENCES threat(id) ON DELETE CASCADE,
    locale        VARCHAR(8) NOT NULL,
    title         VARCHAR(255) NOT NULL,
    description   TEXT,
    attack_vector TEXT,
    CONSTRAINT uq_threat_translation_locale UNIQUE (threat_id, locale)
);

-- 5.6 Mitigation (Phase 2) - table only, not sqlc-mapped yet
CREATE TABLE mitigation (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    threat_id              UUID REFERENCES threat(id) ON DELETE CASCADE,
    card_id                UUID,
    title                  VARCHAR(255) NOT NULL,
    description            TEXT,
    mitigation_type        VARCHAR(32) NOT NULL,
    effort                 VARCHAR(16) NOT NULL,
    effectiveness          VARCHAR(16) NOT NULL
);

CREATE INDEX idx_mitigation_threat_id ON mitigation(threat_id);

-- 5.7 CodeSample (Phase 4) - table only, not sqlc-mapped yet
CREATE TABLE code_sample (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mitigation_id   UUID NOT NULL REFERENCES mitigation(id) ON DELETE CASCADE,
    language        VARCHAR(16) NOT NULL,
    sample_type     VARCHAR(16) NOT NULL,
    title           VARCHAR(255) NOT NULL,
    description     TEXT,
    code            TEXT NOT NULL,
    framework_hint  VARCHAR(128),
    version_note    VARCHAR(100)
);

CREATE INDEX idx_code_sample_mitigation_id ON code_sample(mitigation_id);
CREATE INDEX idx_code_sample_language ON code_sample(language);

-- 5.8 CrossReference (Phase 2+) - table only, not sqlc-mapped yet
CREATE TABLE cross_reference (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_threat_id    UUID NOT NULL REFERENCES threat(id) ON DELETE CASCADE,
    target_threat_id    UUID NOT NULL REFERENCES threat(id) ON DELETE CASCADE,
    relationship_type   VARCHAR(32) NOT NULL,
    description         TEXT
);

CREATE INDEX idx_cross_reference_source ON cross_reference(source_threat_id);
CREATE INDEX idx_cross_reference_target ON cross_reference(target_threat_id);

-- 5.5 CornucopiaCard (Phase 3+) - table only, not sqlc-mapped yet.
-- card_kind + nullable severity enforce D-07/US-19: DESIGN_HARM cards (the
-- dbd deck) physically cannot carry a severity value once the Go
-- constructor-level enforcement lands in Phase 3 - the column is nullable
-- now so that constraint isn't fought at the schema layer later.
CREATE TABLE cornucopia_card (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id         VARCHAR(16) NOT NULL UNIQUE,
    suit_code       VARCHAR(16) NOT NULL,
    suit_name       VARCHAR(128) NOT NULL,
    edition         VARCHAR(32) NOT NULL,
    value           VARCHAR(4) NOT NULL,
    is_critical     BOOLEAN NOT NULL DEFAULT FALSE,
    card_kind       VARCHAR(20) NOT NULL DEFAULT 'TECHNICAL_THREAT',
    severity        VARCHAR(16),
    description_en  TEXT,
    description_pl  TEXT,
    misc_note       TEXT,
    source_url      VARCHAR(512),
    owasp_refs      TEXT,
    mitre_refs      TEXT,
    content_sha256  VARCHAR(64)
);

ALTER TABLE mitigation ADD CONSTRAINT fk_mitigation_card FOREIGN KEY (card_id) REFERENCES cornucopia_card(id) ON DELETE CASCADE;

CREATE INDEX idx_cornucopia_card_suit_code ON cornucopia_card(suit_code);

-- 5.9 ContentHash (Phase 3+, SSDLC) - table only, not sqlc-mapped yet
CREATE TABLE content_hash (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_name     VARCHAR(255) NOT NULL UNIQUE,
    sha256_hash   VARCHAR(64) NOT NULL,
    verified_at   TIMESTAMPTZ,
    is_valid      BOOLEAN NOT NULL DEFAULT TRUE,
    verified_by   VARCHAR(30) NOT NULL DEFAULT 'go-integrity-service'
);

-- +goose Down
DROP TABLE IF EXISTS content_hash;
DROP TABLE IF EXISTS cornucopia_card CASCADE;
DROP TABLE IF EXISTS cross_reference;
DROP TABLE IF EXISTS code_sample;
DROP TABLE IF EXISTS mitigation;
DROP TABLE IF EXISTS threat_translation;
DROP TABLE IF EXISTS threat;
DROP TABLE IF EXISTS framework;

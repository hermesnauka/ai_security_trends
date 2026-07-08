-- ThreatView 2026 - Phase 1 schema
-- Covers data model 4.1 (Framework) and 4.2 (Threat) as live JPA-mapped tables.
-- Tables for 4.3-4.8 are created now so later phases can add Flyway migrations
-- that only ALTER, never re-create, keeping migration history linear.

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

-- 4.3 ThreatTranslation (i18n, Phase 5) - table only, not JPA-mapped yet
CREATE TABLE threat_translation (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    threat_id     UUID NOT NULL REFERENCES threat(id) ON DELETE CASCADE,
    locale        VARCHAR(8) NOT NULL,
    title         VARCHAR(255) NOT NULL,
    description   TEXT,
    attack_vector TEXT,
    category      VARCHAR(128),
    CONSTRAINT uq_threat_translation_locale UNIQUE (threat_id, locale)
);

-- 4.5 Mitigation (Phase 2) - table only, not JPA-mapped yet
CREATE TABLE mitigation (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    threat_id              UUID NOT NULL REFERENCES threat(id) ON DELETE CASCADE,
    title                  VARCHAR(255) NOT NULL,
    description            TEXT,
    mitigation_type        VARCHAR(32) NOT NULL,
    implementation_effort  VARCHAR(16) NOT NULL,
    effectiveness          VARCHAR(16) NOT NULL
);

CREATE INDEX idx_mitigation_threat_id ON mitigation(threat_id);

-- 4.6 CodeSample (Phase 3) - table only, not JPA-mapped yet
CREATE TABLE code_sample (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mitigation_id   UUID NOT NULL REFERENCES mitigation(id) ON DELETE CASCADE,
    language        VARCHAR(16) NOT NULL,
    sample_type     VARCHAR(16) NOT NULL,
    title           VARCHAR(255) NOT NULL,
    description     TEXT,
    code_snippet    TEXT NOT NULL,
    framework_hint  VARCHAR(128),
    version         VARCHAR(64)
);

CREATE INDEX idx_code_sample_mitigation_id ON code_sample(mitigation_id);
CREATE INDEX idx_code_sample_language ON code_sample(language);

-- 4.7 CrossReference (Phase 2+) - table only, not JPA-mapped yet
CREATE TABLE cross_reference (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_threat_id   UUID NOT NULL REFERENCES threat(id) ON DELETE CASCADE,
    target_threat_id   UUID NOT NULL REFERENCES threat(id) ON DELETE CASCADE,
    relationship_type  VARCHAR(32) NOT NULL,
    description        TEXT
);

CREATE INDEX idx_cross_reference_source ON cross_reference(source_threat_id);
CREATE INDEX idx_cross_reference_target ON cross_reference(target_threat_id);

-- 4.4 CornucopiaCard (Phase 6+) - table only, not JPA-mapped yet
CREATE TABLE cornucopia_card (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id         VARCHAR(16) NOT NULL UNIQUE,
    suit_code       VARCHAR(16) NOT NULL,
    suit_name       VARCHAR(128) NOT NULL,
    edition         VARCHAR(32) NOT NULL,
    value           VARCHAR(4) NOT NULL,
    is_critical     BOOLEAN NOT NULL DEFAULT FALSE,
    description_en  TEXT,
    description_pl  TEXT,
    owasp_refs      TEXT,
    mitre_refs      TEXT,
    mavs_refs       TEXT,
    cicd_sec_refs   TEXT,
    oat_refs        TEXT,
    agent_ai_refs   TEXT,
    content_hash    VARCHAR(64)
);

CREATE INDEX idx_cornucopia_card_suit_code ON cornucopia_card(suit_code);

-- 4.8 ContentHash (Phase 6+, SSDLC) - table only, not JPA-mapped yet
CREATE TABLE content_hash (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_name     VARCHAR(255) NOT NULL UNIQUE,
    sha256_hash   VARCHAR(64) NOT NULL,
    verified_at   TIMESTAMPTZ,
    is_valid      BOOLEAN NOT NULL DEFAULT TRUE
);

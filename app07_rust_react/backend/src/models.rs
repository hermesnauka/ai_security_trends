use serde::Serialize;
use uuid::Uuid;

/// Splits app01's comma-joined TEXT columns (stride/tags/cve_references) into
/// a Vec<String>. Always yields `[]` for NULL/empty input rather than passing
/// a null through - app01's own DTOs pass tags/cveReferences through
/// unguarded (can emit JSON `null`), but the already-built frontend types
/// (frontend/src/types/index.ts) assume these are always arrays, so this
/// backend deliberately normalizes to `[]` (same fix app06 already made).
pub fn split_csv(raw: &Option<String>) -> Vec<String> {
    raw.as_deref()
        .unwrap_or("")
        .split(',')
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(str::to_string)
        .collect()
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct Framework {
    pub id: Uuid,
    pub code: String,
    pub name: String,
    pub version: String,
    pub description: Option<String>,
    #[serde(rename = "referenceUrl")]
    pub reference_url: Option<String>,
}

#[derive(Debug, sqlx::FromRow)]
pub struct ThreatSummaryRow {
    pub id: Uuid,
    pub framework_code: String,
    pub code: String,
    pub title: String,
    pub severity: String,
    pub category: Option<String>,
    pub stride: Option<String>,
    pub tags: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct ThreatSummary {
    pub id: Uuid,
    #[serde(rename = "frameworkCode")]
    pub framework_code: String,
    pub code: String,
    pub title: String,
    pub severity: String,
    pub category: Option<String>,
    pub stride: Vec<String>,
    pub tags: Vec<String>,
}

impl From<ThreatSummaryRow> for ThreatSummary {
    fn from(row: ThreatSummaryRow) -> Self {
        Self {
            id: row.id,
            framework_code: row.framework_code,
            code: row.code,
            title: row.title,
            severity: row.severity,
            category: row.category,
            stride: split_csv(&row.stride),
            tags: split_csv(&row.tags),
        }
    }
}

#[derive(Debug, sqlx::FromRow)]
pub struct ThreatDetailRow {
    pub id: Uuid,
    pub framework_code: String,
    pub framework_name: String,
    pub code: String,
    pub title: String,
    pub severity: String,
    pub category: Option<String>,
    pub description: Option<String>,
    pub attack_vector: Option<String>,
    pub attack_surface: Option<String>,
    pub stride: Option<String>,
    pub cve_references: Option<String>,
    pub tags: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct ThreatDetail {
    pub id: Uuid,
    #[serde(rename = "frameworkCode")]
    pub framework_code: String,
    #[serde(rename = "frameworkName")]
    pub framework_name: String,
    pub code: String,
    pub title: String,
    pub severity: String,
    pub category: Option<String>,
    pub description: Option<String>,
    #[serde(rename = "attackVector")]
    pub attack_vector: Option<String>,
    #[serde(rename = "attackSurface")]
    pub attack_surface: Option<String>,
    pub stride: Vec<String>,
    #[serde(rename = "cveReferences")]
    pub cve_references: Vec<String>,
    pub tags: Vec<String>,
}

impl From<ThreatDetailRow> for ThreatDetail {
    fn from(row: ThreatDetailRow) -> Self {
        Self {
            id: row.id,
            framework_code: row.framework_code,
            framework_name: row.framework_name,
            code: row.code,
            title: row.title,
            severity: row.severity,
            category: row.category,
            description: row.description,
            attack_vector: row.attack_vector,
            attack_surface: row.attack_surface,
            stride: split_csv(&row.stride),
            cve_references: split_csv(&row.cve_references),
            tags: split_csv(&row.tags),
        }
    }
}

#[derive(Debug, Serialize)]
pub struct Page<T> {
    pub content: Vec<T>,
    #[serde(rename = "totalElements")]
    pub total_elements: i64,
    #[serde(rename = "totalPages")]
    pub total_pages: i64,
    pub number: i64,
    pub size: i64,
}

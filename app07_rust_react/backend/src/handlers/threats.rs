use axum::{
    Json,
    extract::{Path, Query, State},
};
use serde::Deserialize;
use sqlx::{Postgres, QueryBuilder};
use uuid::Uuid;

use crate::{
    error::{AppError, AppResult},
    models::{Page, ThreatDetail, ThreatDetailRow, ThreatSummary, ThreatSummaryRow},
    state::AppState,
};

const VALID_SEVERITIES: [&str; 5] = ["CRITICAL", "HIGH", "MEDIUM", "LOW", "INFO"];
const SORTABLE_COLUMNS: [&str; 4] = ["code", "title", "severity", "category"];
const DEFAULT_PAGE_SIZE: i64 = 20;

#[derive(Debug, Deserialize)]
pub struct ThreatQuery {
    #[serde(rename = "frameworkCode")]
    pub framework_code: Option<String>,
    pub severity: Option<String>,
    pub stride: Option<String>,
    pub tag: Option<String>,
    pub q: Option<String>,
    pub page: Option<i64>,
    pub size: Option<i64>,
    pub sort: Option<String>,
}

/// Filters mirror app01's ThreatSpecifications: frameworkCode is an exact,
/// case-insensitive match; severity is exact (case-insensitive); stride/tag/q
/// are case-insensitive substring matches against the comma-joined columns
/// (stride/tags) or title+description. All combine with AND.
fn push_filters(qb: &mut QueryBuilder<Postgres>, params: &ThreatQuery) {
    if let Some(framework_code) = &params.framework_code {
        qb.push(" AND UPPER(f.code) = UPPER(")
            .push_bind(framework_code.clone())
            .push(")");
    }
    if let Some(severity) = &params.severity {
        qb.push(" AND t.severity = ")
            .push_bind(severity.to_uppercase());
    }
    if let Some(stride) = &params.stride {
        qb.push(" AND UPPER(COALESCE(t.stride, '')) LIKE ")
            .push_bind(format!("%{}%", stride.to_uppercase()));
    }
    if let Some(tag) = &params.tag {
        qb.push(" AND LOWER(COALESCE(t.tags, '')) LIKE ")
            .push_bind(format!("%{}%", tag.to_lowercase()));
    }
    if let Some(q) = &params.q {
        let pattern = format!("%{}%", q.to_lowercase());
        qb.push(" AND (LOWER(t.title) LIKE ")
            .push_bind(pattern.clone())
            .push(" OR LOWER(COALESCE(t.description, '')) LIKE ")
            .push_bind(pattern)
            .push(")");
    }
}

pub async fn list_threats(
    State(state): State<AppState>,
    Query(params): Query<ThreatQuery>,
) -> AppResult<Json<Page<ThreatSummary>>> {
    if let Some(severity) = &params.severity
        && !VALID_SEVERITIES.contains(&severity.to_uppercase().as_str())
    {
        return Err(AppError::BadRequest(format!(
            "invalid severity: {severity}"
        )));
    }

    let page = params.page.unwrap_or(0).max(0);
    let size = params.size.unwrap_or(DEFAULT_PAGE_SIZE).clamp(1, 200);
    let offset = page * size;

    let mut count_qb: QueryBuilder<Postgres> = QueryBuilder::new(
        "SELECT COUNT(*) FROM threat t JOIN framework f ON f.id = t.framework_id WHERE 1 = 1",
    );
    push_filters(&mut count_qb, &params);
    let total_elements: i64 = count_qb
        .build_query_scalar()
        .fetch_one(&state.pool)
        .await?;

    let mut qb: QueryBuilder<Postgres> = QueryBuilder::new(
        "SELECT t.id, f.code AS framework_code, t.code, t.title, t.severity, t.category, \
         t.stride, t.tags \
         FROM threat t JOIN framework f ON f.id = t.framework_id WHERE 1 = 1",
    );
    push_filters(&mut qb, &params);

    if let Some(sort) = &params.sort {
        let mut parts = sort.splitn(2, ',');
        let field = parts.next().unwrap_or("");
        let direction = parts.next().unwrap_or("asc");
        if SORTABLE_COLUMNS.contains(&field) {
            // `field` is checked against a fixed whitelist above, so this is
            // never attacker-controlled despite being pushed as raw SQL.
            let direction = if direction.eq_ignore_ascii_case("desc") {
                "DESC"
            } else {
                "ASC"
            };
            qb.push(" ORDER BY t.")
                .push(field)
                .push(" ")
                .push(direction);
        }
    }

    qb.push(" LIMIT ")
        .push_bind(size)
        .push(" OFFSET ")
        .push_bind(offset);

    let rows: Vec<ThreatSummaryRow> = qb.build_query_as().fetch_all(&state.pool).await?;
    let content: Vec<ThreatSummary> = rows.into_iter().map(Into::into).collect();

    let total_pages = if total_elements == 0 {
        0
    } else {
        (total_elements + size - 1) / size
    };

    Ok(Json(Page {
        content,
        total_elements,
        total_pages,
        number: page,
        size,
    }))
}

pub async fn get_threat(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> AppResult<Json<ThreatDetail>> {
    let row = sqlx::query_as::<_, ThreatDetailRow>(
        r#"SELECT t.id, f.code AS framework_code, f.name AS framework_name, t.code, t.title,
                  t.severity, t.category, t.description, t.attack_vector, t.attack_surface,
                  t.stride, t.cve_references, t.tags
           FROM threat t JOIN framework f ON f.id = t.framework_id
           WHERE t.id = $1"#,
    )
    .bind(id)
    .fetch_optional(&state.pool)
    .await?
    .ok_or_else(|| AppError::NotFound("Threat", id.to_string()))?;

    Ok(Json(row.into()))
}

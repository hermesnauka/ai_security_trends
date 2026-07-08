use axum::{
    Json,
    extract::{Path, State},
};

use crate::{
    error::{AppError, AppResult},
    models::Framework,
    state::AppState,
};

// Runtime-checked (`query_as`, not the `query_as!` macro) rather than
// compile-time-checked, unlike PLAN.md's original commitment - compile-time
// checking needs a live, already-migrated database present at `cargo build`
// time, which makes the build non-portable (fails for anyone who clones this
// repo without a running, pre-migrated Postgres). See ../CLAUDE.md.
pub async fn list_frameworks(State(state): State<AppState>) -> AppResult<Json<Vec<Framework>>> {
    let frameworks = sqlx::query_as::<_, Framework>(
        r#"SELECT id, code, name, version, description, reference_url
           FROM framework
           ORDER BY code"#,
    )
    .fetch_all(&state.pool)
    .await?;

    Ok(Json(frameworks))
}

pub async fn get_framework(
    State(state): State<AppState>,
    Path(code): Path<String>,
) -> AppResult<Json<Framework>> {
    let framework = sqlx::query_as::<_, Framework>(
        r#"SELECT id, code, name, version, description, reference_url
           FROM framework
           WHERE UPPER(code) = UPPER($1)"#,
    )
    .bind(&code)
    .fetch_optional(&state.pool)
    .await?
    .ok_or_else(|| AppError::NotFound("Framework", code.clone()))?;

    Ok(Json(framework))
}

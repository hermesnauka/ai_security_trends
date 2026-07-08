use axum::{
    Json, Router,
    routing::{get, post},
};
use serde_json::{Value, json};
use tower_http::{
    cors::{Any, CorsLayer},
    trace::TraceLayer,
};

use crate::{auth, handlers::frameworks, handlers::threats, state::AppState};

pub fn build_router(state: AppState) -> Router {
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    Router::new()
        .route("/health", get(health))
        .route("/api/v1/auth/login", post(auth::login))
        .route("/api/v1/frameworks", get(frameworks::list_frameworks))
        .route("/api/v1/frameworks/{code}", get(frameworks::get_framework))
        .route("/api/v1/threats", get(threats::list_threats))
        .route("/api/v1/threats/{id}", get(threats::get_threat))
        .layer(cors)
        .layer(TraceLayer::new_for_http())
        .with_state(state)
}

async fn health() -> Json<Value> {
    Json(json!({ "status": "UP" }))
}

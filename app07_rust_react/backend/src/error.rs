use axum::{
    Json,
    http::StatusCode,
    response::{IntoResponse, Response},
};
use serde::Serialize;

#[derive(Debug, thiserror::Error)]
pub enum AppError {
    #[error("{0} not found: {1}")]
    NotFound(&'static str, String),
    #[error("invalid credentials")]
    Unauthorized,
    #[error("invalid request: {0}")]
    BadRequest(String),
    #[error(transparent)]
    Database(#[from] sqlx::Error),
}

#[derive(Serialize)]
struct ErrorBody {
    timestamp: String,
    status: u16,
    error: String,
    message: String,
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, error, message) = match &self {
            AppError::NotFound(kind, id) => (
                StatusCode::NOT_FOUND,
                "Not Found",
                format!("{kind} not found: {id}"),
            ),
            AppError::Unauthorized => (
                StatusCode::UNAUTHORIZED,
                "Unauthorized",
                self.to_string(),
            ),
            AppError::BadRequest(msg) => (StatusCode::BAD_REQUEST, "Bad Request", msg.clone()),
            AppError::Database(err) => {
                tracing::error!(error = %err, "database error");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "Internal Server Error",
                    "an unexpected error occurred".to_string(),
                )
            }
        };

        let body = ErrorBody {
            timestamp: chrono::Utc::now().to_rfc3339(),
            status: status.as_u16(),
            error: error.to_string(),
            message,
        };

        (status, Json(body)).into_response()
    }
}

pub type AppResult<T> = Result<T, AppError>;

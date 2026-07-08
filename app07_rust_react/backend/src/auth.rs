use std::time::{SystemTime, UNIX_EPOCH};

use argon2::{
    Argon2,
    password_hash::{PasswordHash, PasswordVerifier},
};
use axum::{Json, extract::State};
use jsonwebtoken::{EncodingKey, Header, encode};
use serde::{Deserialize, Serialize};

use crate::{
    config::Config,
    error::{AppError, AppResult},
    state::AppState,
};

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub username: String,
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct LoginResponse {
    pub token: String,
    #[serde(rename = "tokenType")]
    pub token_type: String,
    pub role: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct Claims {
    sub: String,
    role: String,
    iat: u64,
    exp: u64,
}

/// Argon2id, not app01's BCrypt - password hashing is an internal storage
/// detail, not part of the wire contract, so this app follows PLAN.md's
/// Argon2id commitment instead of matching app01 byte-for-byte here. The
/// admin password itself (`changeme-dev-only__`) still matches app01's so
/// login credentials are identical across every sibling app - only the
/// stored hash format differs. See ../CLAUDE.md.
fn verify_password(password: &str, hash: &str) -> bool {
    let Ok(parsed_hash) = PasswordHash::new(hash) else {
        return false;
    };
    Argon2::default()
        .verify_password(password.as_bytes(), &parsed_hash)
        .is_ok()
}

fn issue_token(config: &Config, username: &str) -> AppResult<String> {
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("system clock before unix epoch")
        .as_secs();
    let exp = now + (config.jwt_expiration_minutes.max(0) as u64) * 60;
    let claims = Claims {
        sub: username.to_string(),
        role: "ADMIN".to_string(),
        iat: now,
        exp,
    };
    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(config.jwt_secret.as_bytes()),
    )
    .map_err(|err| {
        tracing::error!(error = %err, "failed to sign JWT");
        AppError::BadRequest("failed to issue token".to_string())
    })
}

pub async fn login(
    State(state): State<AppState>,
    Json(req): Json<LoginRequest>,
) -> AppResult<Json<LoginResponse>> {
    if req.username.trim().is_empty() || req.password.is_empty() {
        return Err(AppError::BadRequest(
            "username and password are required".to_string(),
        ));
    }

    let username_matches = req.username == state.config.admin_username;
    let password_matches = verify_password(&req.password, &state.config.admin_password_hash);

    if !username_matches || !password_matches {
        return Err(AppError::Unauthorized);
    }

    let token = issue_token(&state.config, &req.username)?;
    Ok(Json(LoginResponse {
        token,
        token_type: "Bearer".to_string(),
        role: "ADMIN".to_string(),
    }))
}

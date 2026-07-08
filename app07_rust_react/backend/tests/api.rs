use argon2::{
    Argon2,
    password_hash::{PasswordHasher, SaltString, rand_core::OsRng},
};
use axum_test::TestServer;
use securevision_backend::{AppState, Config, routes::build_router};
use sqlx::PgPool;

const TEST_PASSWORD: &str = "test-password-1234";

fn test_state(pool: PgPool) -> AppState {
    let salt = SaltString::generate(&mut OsRng);
    let hash = Argon2::default()
        .hash_password(TEST_PASSWORD.as_bytes(), &salt)
        .unwrap()
        .to_string();

    let config = Config {
        database_url: String::new(),
        bind_addr: "127.0.0.1:0".to_string(),
        jwt_secret: "test-only-secret-at-least-32-bytes-long".to_string(),
        jwt_expiration_minutes: 60,
        admin_username: "admin".to_string(),
        admin_password_hash: hash,
    };

    AppState { pool, config }
}

#[sqlx::test(migrations = "./migrations")]
async fn health_check_returns_up(pool: PgPool) {
    let server = TestServer::new(build_router(test_state(pool)));

    let response = server.get("/health").await;

    response.assert_status_ok();
    response.assert_json(&serde_json::json!({ "status": "UP" }));
}

#[sqlx::test(migrations = "./migrations")]
async fn login_succeeds_with_correct_credentials(pool: PgPool) {
    let server = TestServer::new(build_router(test_state(pool)));

    let response = server
        .post("/api/v1/auth/login")
        .json(&serde_json::json!({ "username": "admin", "password": TEST_PASSWORD }))
        .await;

    response.assert_status_ok();
    let body: serde_json::Value = response.json();
    assert_eq!(body["tokenType"], "Bearer");
    assert_eq!(body["role"], "ADMIN");
    assert!(body["token"].as_str().unwrap().len() > 10);
}

#[sqlx::test(migrations = "./migrations")]
async fn login_fails_with_wrong_password(pool: PgPool) {
    let server = TestServer::new(build_router(test_state(pool)));

    let response = server
        .post("/api/v1/auth/login")
        .json(&serde_json::json!({ "username": "admin", "password": "wrong-password" }))
        .await;

    response.assert_status(axum::http::StatusCode::UNAUTHORIZED);
    let body: serde_json::Value = response.json();
    assert_eq!(body["status"], 401);
    assert_eq!(body["error"], "Unauthorized");
}

#[sqlx::test(migrations = "./migrations")]
async fn login_rejects_blank_username(pool: PgPool) {
    let server = TestServer::new(build_router(test_state(pool)));

    let response = server
        .post("/api/v1/auth/login")
        .json(&serde_json::json!({ "username": "", "password": TEST_PASSWORD }))
        .await;

    response.assert_status(axum::http::StatusCode::BAD_REQUEST);
}

#[sqlx::test(migrations = "./migrations")]
async fn list_frameworks_returns_all_seeded_frameworks(pool: PgPool) {
    let server = TestServer::new(build_router(test_state(pool)));

    let response = server.get("/api/v1/frameworks").await;

    response.assert_status_ok();
    let body: Vec<serde_json::Value> = response.json();
    assert_eq!(body.len(), 4);
    let codes: Vec<&str> = body.iter().map(|f| f["code"].as_str().unwrap()).collect();
    assert!(codes.contains(&"OWASP_WEB"));
    assert!(codes.contains(&"OWASP_LLM"));
    assert!(codes.contains(&"MITRE_ATLAS"));
    assert!(codes.contains(&"COMPTIA_SECAI"));
}

#[sqlx::test(migrations = "./migrations")]
async fn get_framework_by_code_is_case_insensitive(pool: PgPool) {
    let server = TestServer::new(build_router(test_state(pool)));

    let response = server.get("/api/v1/frameworks/owasp_web").await;

    response.assert_status_ok();
    let body: serde_json::Value = response.json();
    assert_eq!(body["code"], "OWASP_WEB");
    assert_eq!(body["name"], "OWASP Top 10");
}

#[sqlx::test(migrations = "./migrations")]
async fn get_framework_not_found_returns_404_with_error_body(pool: PgPool) {
    let server = TestServer::new(build_router(test_state(pool)));

    let response = server.get("/api/v1/frameworks/NOPE").await;

    response.assert_status_not_found();
    let body: serde_json::Value = response.json();
    assert_eq!(body["status"], 404);
    assert_eq!(body["error"], "Not Found");
    assert!(body["message"].as_str().unwrap().contains("NOPE"));
}

#[sqlx::test(migrations = "./migrations")]
async fn list_threats_default_pagination(pool: PgPool) {
    let server = TestServer::new(build_router(test_state(pool)));

    let response = server.get("/api/v1/threats").await;

    response.assert_status_ok();
    let body: serde_json::Value = response.json();
    assert_eq!(body["number"], 0);
    assert_eq!(body["size"], 20);
    assert_eq!(body["totalElements"], 34);
    assert_eq!(body["totalPages"], 2);
    assert_eq!(body["content"].as_array().unwrap().len(), 20);
}

#[sqlx::test(migrations = "./migrations")]
async fn list_threats_filters_by_framework_code_and_severity(pool: PgPool) {
    let server = TestServer::new(build_router(test_state(pool)));

    let response = server
        .get("/api/v1/threats?frameworkCode=OWASP_WEB&severity=CRITICAL")
        .await;

    response.assert_status_ok();
    let body: serde_json::Value = response.json();
    let content = body["content"].as_array().unwrap();
    assert!(!content.is_empty());
    for item in content {
        assert_eq!(item["frameworkCode"], "OWASP_WEB");
        assert_eq!(item["severity"], "CRITICAL");
    }
}

#[sqlx::test(migrations = "./migrations")]
async fn list_threats_rejects_invalid_severity(pool: PgPool) {
    let server = TestServer::new(build_router(test_state(pool)));

    let response = server.get("/api/v1/threats?severity=NOT_A_SEVERITY").await;

    response.assert_status(axum::http::StatusCode::BAD_REQUEST);
}

#[sqlx::test(migrations = "./migrations")]
async fn list_threats_free_text_search_matches_title(pool: PgPool) {
    let server = TestServer::new(build_router(test_state(pool)));

    let response = server.get("/api/v1/threats?q=prompt%20injection").await;

    response.assert_status_ok();
    let body: serde_json::Value = response.json();
    let content = body["content"].as_array().unwrap();
    assert!(!content.is_empty());
    assert!(
        content
            .iter()
            .any(|t| t["title"].as_str().unwrap().to_lowercase().contains("prompt"))
    );
}

#[sqlx::test(migrations = "./migrations")]
async fn list_threats_filters_by_stride_and_tag(pool: PgPool) {
    let server = TestServer::new(build_router(test_state(pool)));

    let response = server.get("/api/v1/threats?stride=E").await;
    response.assert_status_ok();
    let body: serde_json::Value = response.json();
    let content = body["content"].as_array().unwrap();
    assert!(!content.is_empty());
    for item in content {
        let stride: Vec<&str> = item["stride"]
            .as_array()
            .unwrap()
            .iter()
            .map(|v| v.as_str().unwrap())
            .collect();
        assert!(stride.contains(&"E"));
    }

    let response = server.get("/api/v1/threats?tag=exam-objective").await;
    response.assert_status_ok();
    let body: serde_json::Value = response.json();
    assert!(!body["content"].as_array().unwrap().is_empty());
}

#[sqlx::test(migrations = "./migrations")]
async fn list_threats_pagination_params(pool: PgPool) {
    let server = TestServer::new(build_router(test_state(pool)));

    let response = server.get("/api/v1/threats?page=1&size=5").await;

    response.assert_status_ok();
    let body: serde_json::Value = response.json();
    assert_eq!(body["number"], 1);
    assert_eq!(body["size"], 5);
    assert_eq!(body["content"].as_array().unwrap().len(), 5);
}

#[sqlx::test(migrations = "./migrations")]
async fn threats_never_expose_null_tags_or_cve_references(pool: PgPool) {
    let server = TestServer::new(build_router(test_state(pool)));

    // A06:2021 is seeded with NULL stride - confirms it normalizes to [] not null.
    let response = server
        .get("/api/v1/threats?frameworkCode=OWASP_WEB&q=vulnerable%20and%20outdated")
        .await;
    response.assert_status_ok();
    let body: serde_json::Value = response.json();
    let content = body["content"].as_array().unwrap();
    assert!(!content.is_empty());
    for item in content {
        assert!(item["stride"].is_array());
        assert!(item["tags"].is_array());
    }
}

#[sqlx::test(migrations = "./migrations")]
async fn get_threat_detail_by_id(pool: PgPool) {
    let server = TestServer::new(build_router(test_state(pool)));

    let list_response = server
        .get("/api/v1/threats?frameworkCode=OWASP_WEB&size=1")
        .await;
    let list_body: serde_json::Value = list_response.json();
    let id = list_body["content"][0]["id"].as_str().unwrap().to_string();

    let response = server.get(&format!("/api/v1/threats/{id}")).await;

    response.assert_status_ok();
    let body: serde_json::Value = response.json();
    assert_eq!(body["id"], id);
    assert!(body["frameworkName"].is_string());
    assert!(body["cveReferences"].is_array());
    assert!(body["tags"].is_array());
}

#[sqlx::test(migrations = "./migrations")]
async fn get_threat_not_found_returns_404(pool: PgPool) {
    let server = TestServer::new(build_router(test_state(pool)));

    let response = server
        .get("/api/v1/threats/00000000-0000-0000-0000-000000000000")
        .await;

    response.assert_status_not_found();
}

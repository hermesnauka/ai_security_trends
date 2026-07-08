pub mod auth;
pub mod config;
pub mod error;
pub mod handlers;
pub mod models;
pub mod routes;
pub mod state;

use sqlx::postgres::PgPoolOptions;

pub use config::Config;
pub use state::AppState;

pub async fn build_state(config: Config) -> AppState {
    let pool = PgPoolOptions::new()
        .max_connections(10)
        .connect(&config.database_url)
        .await
        .expect("failed to connect to database");

    AppState { pool, config }
}

pub async fn run_migrations(state: &AppState) {
    sqlx::migrate!("./migrations")
        .run(&state.pool)
        .await
        .expect("failed to run migrations");
}

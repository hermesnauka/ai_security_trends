use securevision_backend::{Config, build_state, routes::build_router, run_migrations};

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(
            |_| tracing_subscriber::EnvFilter::new("info,securevision_backend=debug"),
        ))
        .init();

    let config = Config::from_env();
    let bind_addr = config.bind_addr.clone();

    let state = build_state(config).await;
    run_migrations(&state).await;

    let app = build_router(state);

    let listener = tokio::net::TcpListener::bind(&bind_addr)
        .await
        .expect("failed to bind");
    tracing::info!("listening on {}", bind_addr);
    axum::serve(listener, app).await.expect("server error");
}

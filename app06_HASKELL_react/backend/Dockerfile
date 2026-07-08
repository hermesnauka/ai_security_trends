# HaskShield 2026 backend -- multi-stage build per PLAN.md S2/S3.
# NOT tested this session -- there is no Docker on the machine this was
# written on (see CLAUDE.md). Written for portability/parity; verify on a
# machine with Docker before relying on it.

FROM haskell:9.8 AS builder
WORKDIR /build
COPY hasshield.cabal cabal.project ./
RUN cabal update && cabal build --only-dependencies
COPY app ./app
COPY src ./src
COPY migrations ./migrations
RUN cabal build exe:api && \
    cp "$(cabal list-bin exe:api)" /build/api

FROM debian:bookworm-slim AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends libpq5 ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /build/api ./api
COPY migrations ./migrations
EXPOSE 8080
CMD ["./api"]

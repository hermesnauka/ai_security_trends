# D-06: cmd/api and cmd/worker ship as fully static (CGO_ENABLED=0) binaries
# in FROM scratch images - no shell, no package manager, no interpreter
# inside the running container. The `build` stage below is NOT scratch (it
# has the Go toolchain + goose CLI) and is reused directly as the image for
# the one-shot migrate/seed steps in docker-compose.yml, which exit
# immediately and aren't a persistent attack surface the way api/worker are.

FROM golang:1.23-alpine AS build
WORKDIR /build
RUN go install github.com/pressly/goose/v3/cmd/goose@v3.24.0
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /bin/api ./cmd/api
RUN CGO_ENABLED=0 GOOS=linux go build -o /bin/worker ./cmd/worker
RUN CGO_ENABLED=0 GOOS=linux go build -o /bin/seed ./cmd/seed

FROM scratch AS api
COPY --from=build /bin/api /api
EXPOSE 8080
ENTRYPOINT ["/api"]

FROM scratch AS worker
COPY --from=build /bin/worker /worker
ENTRYPOINT ["/worker"]

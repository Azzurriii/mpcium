FROM golang:1.26 AS builder

ARG TARGETOS
ARG TARGETARCH

WORKDIR /src

ENV GOPRIVATE=github.com/fystack/*
RUN apt-get update && apt-get install -y --no-install-recommends openssh-client && \
    rm -rf /var/lib/apt/lists/* && \
    git config --global --add safe.directory '*' && \
    git config --global url."git@github.com:".insteadOf "https://github.com/"

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=ssh \
    mkdir -p -m 0700 /root/.ssh && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts && \
    go mod download

COPY . .

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=ssh \
    CGO_ENABLED=0 \
    GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH} \
    go build -o /out/mpcium ./cmd/mpcium

FROM gcr.io/distroless/base-debian12:latest

USER nonroot:nonroot
WORKDIR /app

COPY --from=builder /out/mpcium /app/mpcium

ENTRYPOINT ["/app/mpcium"]

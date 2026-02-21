FROM ghcr.io/cirruslabs/flutter:latest AS builder
WORKDIR /app

RUN useradd --create-home --shell /bin/bash flutter \
  && chown -R flutter:flutter /app

USER flutter

ARG API_BASE_URL=/api/v1

COPY --chown=flutter:flutter pubspec.yaml pubspec.lock analysis_options.yaml ./
RUN flutter pub get

COPY --chown=flutter:flutter lib ./lib
COPY --chown=flutter:flutter assets ./assets
COPY --chown=flutter:flutter web ./web

RUN flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL

FROM nginx:1.25-alpine
COPY --from=builder /app/build/web /usr/share/nginx/html

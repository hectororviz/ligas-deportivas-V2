FROM ghcr.io/cirruslabs/flutter:latest AS builder
WORKDIR /app
ENV HOME=/home/flutter \
    PUB_CACHE=/home/flutter/.pub-cache \
    FLUTTER_ROOT=/sdks/flutter

RUN useradd --create-home --shell /bin/bash flutter \
  && mkdir -p "$HOME" "$PUB_CACHE" \
  && chown -R flutter:flutter /app "$HOME" /sdks/flutter

USER flutter

RUN set -eux; \
    git config --global --add safe.directory /sdks/flutter; \
    for repo in /sdks/flutter/bin/cache/pkg/sky_engine /sdks/flutter/bin/cache/flutter_web_sdk; do \
      if [ -d "$repo/.git" ] || git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then \
        git config --global --add safe.directory "$repo"; \
      fi; \
    done

ARG API_BASE_URL=/api/v1

COPY --chown=flutter:flutter pubspec.yaml pubspec.lock analysis_options.yaml ./
RUN flutter pub get

COPY --chown=flutter:flutter lib ./lib
COPY --chown=flutter:flutter assets ./assets
COPY --chown=flutter:flutter web ./web

RUN flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL

FROM nginx:1.25-alpine
COPY --from=builder /app/build/web /usr/share/nginx/html

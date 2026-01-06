FROM ghcr.io/cirruslabs/flutter:latest AS builder
WORKDIR /app

ARG API_BASE_URL=/api/v1

COPY pubspec.yaml pubspec.lock analysis_options.yaml ./
RUN flutter pub get

COPY lib ./lib
COPY assets ./assets
COPY web ./web

RUN flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL

FROM nginx:1.25-alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY infra/nginx.conf /etc/nginx/conf.d/default.conf

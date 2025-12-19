FROM ghcr.io/cirruslabs/flutter:latest AS builder
WORKDIR /app

COPY pubspec.yaml pubspec.lock analysis_options.yaml ./
RUN flutter pub get

COPY lib ./lib
COPY assets ./assets
COPY web ./web

RUN flutter build web --release

FROM nginx:1.25-alpine
COPY --from=builder /app/build/web /usr/share/nginx/html


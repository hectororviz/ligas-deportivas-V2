FROM ghcr.io/cirruslabs/flutter:3.19.6 AS builder
USER root
WORKDIR /app
RUN chown -R cirrus:cirrus /app
USER cirrus
COPY --chown=cirrus:cirrus pubspec.yaml analysis_options.yaml ./
RUN flutter pub get
COPY --chown=cirrus:cirrus lib ./lib
COPY --chown=cirrus:cirrus assets ./assets
RUN flutter build web --release

FROM nginx:1.25-alpine
COPY --from=builder /app/build/web /usr/share/nginx/html

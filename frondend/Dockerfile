# ==========================================
# STAGE 1: BUILD FLUTTER WEB
# ==========================================
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

ARG API_BASE_URL
ARG STORAGE_PUBLIC_URL
ARG FLUTTER_BUILD_ARGS=""
ARG GIT_SHA="unknown"
ARG BUILD_VERSION="2026.05.30.03"

ENV CI=true

COPY pubspec.* ./
RUN flutter pub get

COPY . .

RUN echo "{\"version\":\"${BUILD_VERSION}\",\"build\":\"fulltech-store\",\"gitSha\":\"${GIT_SHA}\",\"updatedAt\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > web/version.json

# Dejamos que Flutter genere el build web moderno por defecto.
RUN if [ -n "$API_BASE_URL" ]; then \
      flutter build web --release --pwa-strategy=none \
        --dart-define=API_BASE_URL="$API_BASE_URL" \
        --dart-define=STORAGE_PUBLIC_URL="$STORAGE_PUBLIC_URL" \
        $FLUTTER_BUILD_ARGS; \
    else \
      flutter build web --release --pwa-strategy=none \
        --dart-define=STORAGE_PUBLIC_URL="$STORAGE_PUBLIC_URL" \
        $FLUTTER_BUILD_ARGS; \
    fi

RUN sed -i "s/__FULLTECH_BUILD_VERSION__/${BUILD_VERSION}/g" /app/build/web/index.html

# ==========================================
# STAGE 2: SERVE WITH NGINX
# ==========================================
FROM nginx:alpine

LABEL org.opencontainers.image.source="FULLTECH_BOT/frondend"

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

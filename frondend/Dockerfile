# ==========================================
# STAGE 1: BUILD FLUTTER WEB
# ==========================================
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

ARG API_BASE_URL
ARG STORAGE_PUBLIC_URL
ARG FLUTTER_BUILD_ARGS=""
ARG GIT_SHA="unknown"
ARG BUILD_VERSION="2026.05.30.01"

ENV CI=true

# Copy pubspec first to cache dependencies
COPY pubspec.* ./
RUN flutter pub get

# Copy project
COPY . .

# Generar version.json con la versión del build
RUN echo "{\"version\":\"${BUILD_VERSION}\",\"build\":\"fulltech-store\",\"gitSha\":\"${GIT_SHA}\",\"updatedAt\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > web/version.json

# Build the web app en modo release
# --pwa-strategy=none: No generar service worker automático de Flutter
# --web-renderer html: Más rápido que canvaskit para tiendas con muchas imágenes
#   Canvaskit es más pesado de descargar (2-3MB extra) y tarda más en renderizar
#   HTML renderer carga más rápido y es mejor para contenido dinámico como tiendas
RUN if [ -n "$API_BASE_URL" ]; then \
      flutter build web --release --no-wasm-dry-run --pwa-strategy=none \
        --web-renderer html \
        --dart-define=API_BASE_URL="$API_BASE_URL" \
        --dart-define=STORAGE_PUBLIC_URL="$STORAGE_PUBLIC_URL" \
        $FLUTTER_BUILD_ARGS; \
    else \
      flutter build web --release --no-wasm-dry-run --pwa-strategy=none \
        --web-renderer html \
        --dart-define=STORAGE_PUBLIC_URL="$STORAGE_PUBLIC_URL" \
        $FLUTTER_BUILD_ARGS; \
    fi

# Reemplazar placeholder de versión en index.html
RUN sed -i "s/__FULLTECH_BUILD_VERSION__/${BUILD_VERSION}/g" /app/build/web/index.html

# ==========================================
# STAGE 2: SERVE WITH NGINX
# ==========================================
FROM nginx:alpine

LABEL org.opencontainers.image.source="FULLTECH_BOT/frondend"

# Copiar build de Flutter
COPY --from=build /app/build/web /usr/share/nginx/html

# Copiar configuración Nginx personalizada
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

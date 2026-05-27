FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

ARG API_BASE_URL
ARG FLUTTER_BUILD_ARGS=""
ARG GIT_SHA="unknown"

ENV CI=true

# Copy pubspec first to cache dependencies
COPY pubspec.* ./
RUN flutter pub get

# Copy project
COPY . .

# Build the web app with optional dart-defines from EasyPanel.
RUN if [ -n "$API_BASE_URL" ]; then \
      flutter build web --release --no-wasm-dry-run --dart-define=API_BASE_URL="$API_BASE_URL" $FLUTTER_BUILD_ARGS; \
    else \
      flutter build web --release --no-wasm-dry-run $FLUTTER_BUILD_ARGS; \
    fi

FROM nginx:alpine

LABEL org.opencontainers.image.source="FULLTECH_BOT/frondend"

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

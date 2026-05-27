FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy pubspec first to cache dependencies
COPY pubspec.* ./
RUN flutter pub get

# Copy project
COPY . .

# Ensure web build uses release mode and reasonable renderer (auto)
RUN flutter clean || true
RUN flutter pub get
RUN flutter build web --release --web-renderer=html

FROM nginx:alpine

LABEL org.opencontainers.image.source="FULLTECH_BOT/frondend"

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

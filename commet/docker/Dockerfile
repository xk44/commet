# syntax=docker/dockerfile:1.6

FROM ghcr.io/cirruslabs/flutter:3.35.4 AS build
WORKDIR /app

COPY commet/pubspec.yaml commet/pubspec.lock ./
RUN flutter pub get

COPY commet/ .
RUN flutter build web --release

FROM nginx:1.27-alpine
COPY commet/docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]

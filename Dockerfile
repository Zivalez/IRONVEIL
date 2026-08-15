FROM barichello/godot-ci:4.7.1 AS builder

WORKDIR /app
COPY . .

RUN mkdir -p /app/build \
    && godot --headless --editor --path /app --quit \
    && godot --headless --path /app --export-release "Web" /app/build/index.html

FROM nginx:alpine AS runtime

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/ /usr/share/nginx/html/

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1/ || exit 1

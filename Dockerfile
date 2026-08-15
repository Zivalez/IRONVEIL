FROM barichello/godot-ci:4.7.1 AS builder

# godot-ci is Ubuntu-based; fontconfig removes noisy headless system-font errors.
RUN apt-get update \
    && apt-get install -y --no-install-recommends fontconfig \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

# --import waits for importable resources before export. This is safer in CI than
# opening the editor and quitting immediately.
RUN mkdir -p /app/build \
    && godot --headless --path /app --import \
    && godot --headless --path /app --script res://scripts/tests/run_headless_tests.gd \
    && godot --headless --path /app --export-release "Web" /app/build/index.html

FROM nginx:alpine AS runtime

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/ /usr/share/nginx/html/

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1/ || exit 1

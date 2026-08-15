FROM barichello/godot-ci:4.7.1 AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends fontconfig \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

# CI gate order matters:
# 1) import resources,
# 2) compile/load every runtime script independently,
# 3) instantiate the gameplay scene in headless mode and run deterministic tests,
# 4) only then create the Web export.
RUN mkdir -p /app/build \
    && godot --headless --path /app --import \
    && godot --headless --path /app --script res://scripts/tests/compile_all.gd \
    && godot --headless --path /app --script res://scripts/tests/run_headless_tests.gd \
    && godot --headless --path /app --export-release "Web" /app/build/index.html \
    && test -s /app/build/index.html \
    && test -s /app/build/index.js \
    && test -s /app/build/index.wasm \
    && test -s /app/build/index.pck

FROM nginx:alpine AS runtime

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/ /usr/share/nginx/html/

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1/ || exit 1

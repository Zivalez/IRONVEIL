FROM barichello/godot-ci:4.7.1 AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends fontconfig \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

# The test gate MUST run through a normal project scene. Running a SceneTree
# script via `godot --script` bypasses the lifecycle in which project autoload
# singletons are installed, so production scripts that correctly reference
# GameState/TickManager/etc. can fail to resolve only in CI.
RUN rm -rf /app/.godot \
    && mkdir -p /app/build \
    && godot --headless --path /app --import \
    && timeout 120s godot --headless --path /app res://scenes/tests/ci_runner.tscn \
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

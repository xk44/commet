#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/troubleshoot"
STAMP="$(date +%Y%m%d-%H%M%S)"
BUNDLE="$OUT_DIR/cfk-troubleshoot-$STAMP.tar.gz"

mkdir -p "$OUT_DIR/$STAMP"

(
  cd "$ROOT_DIR"
  docker compose ps > "$OUT_DIR/$STAMP/docker-compose-ps.txt"
  docker compose logs --tail 500 > "$OUT_DIR/$STAMP/docker-compose-logs.txt"
)

sed -E -i 's/(password|secret|token|access[_-]?key)([^[:space:]]*)/[REDACTED]/Ig' "$OUT_DIR/$STAMP/docker-compose-logs.txt"

cp "$ROOT_DIR/.env" "$OUT_DIR/$STAMP/.env" 2>/dev/null || true
sed -E -i 's/=.*/=[REDACTED]/g' "$OUT_DIR/$STAMP/.env" 2>/dev/null || true

tar -C "$OUT_DIR" -czf "$BUNDLE" "$STAMP"
rm -rf "$OUT_DIR/$STAMP"

echo "Troubleshoot bundle written to: $BUNDLE"

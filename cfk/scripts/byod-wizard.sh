#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

prompt() {
  local var_name="$1"
  local question="$2"
  local default_value="${3:-}"
  local current_value="${!var_name:-}"

  if [[ -n "$current_value" ]]; then
    return
  fi

  read -r -p "$question ${default_value:+[$default_value]}: " input
  printf -v "$var_name" '%s' "${input:-$default_value}"
}

load_existing_env() {
  if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
  fi
}

write_env() {
  cat > "$ENV_FILE" <<EOT
MATRIX_SERVER_NAME=$MATRIX_SERVER_NAME
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_DB=$POSTGRES_DB
PUBLIC_IP=$PUBLIC_IP
TURN_SHARED_SECRET=$TURN_SHARED_SECRET
GRAFANA_ADMIN_PASSWORD=$GRAFANA_ADMIN_PASSWORD
REGISTRATION_SHARED_SECRET=$REGISTRATION_SHARED_SECRET
MACAROON_SECRET_KEY=$MACAROON_SECRET_KEY
FORM_SECRET=$FORM_SECRET
EOT
}

render_template() {
  local input="$1"
  local output="$2"

  sed \
    -e "s/__MATRIX_SERVER_NAME__/$MATRIX_SERVER_NAME/g" \
    -e "s/__POSTGRES_USER__/$POSTGRES_USER/g" \
    -e "s/__POSTGRES_PASSWORD__/$POSTGRES_PASSWORD/g" \
    -e "s/__POSTGRES_DB__/$POSTGRES_DB/g" \
    -e "s/__TURN_SHARED_SECRET__/$TURN_SHARED_SECRET/g" \
    -e "s/__REGISTRATION_SHARED_SECRET__/$REGISTRATION_SHARED_SECRET/g" \
    -e "s/__MACAROON_SECRET_KEY__/$MACAROON_SECRET_KEY/g" \
    -e "s/__FORM_SECRET__/$FORM_SECRET/g" \
    "$input" > "$output"
}

render_templates() {
  render_template "$ROOT_DIR/Caddyfile.tmpl" "$ROOT_DIR/Caddyfile"
  render_template "$ROOT_DIR/synapse/homeserver.yaml.tmpl" "$ROOT_DIR/synapse/homeserver.yaml"
  render_template "$ROOT_DIR/well-known/matrix-client.tmpl" "$ROOT_DIR/well-known/matrix-client"
  render_template "$ROOT_DIR/well-known/matrix-server.tmpl" "$ROOT_DIR/well-known/matrix-server"
}

main() {
  load_existing_env

  prompt MATRIX_SERVER_NAME "Matrix server domain"
  prompt POSTGRES_USER "Postgres user" "synapse"
  prompt POSTGRES_PASSWORD "Postgres password"
  prompt POSTGRES_DB "Postgres database" "synapse"
  prompt PUBLIC_IP "Public server IP"
  prompt TURN_SHARED_SECRET "TURN shared secret"
  prompt GRAFANA_ADMIN_PASSWORD "Grafana admin password" "change-me"
  prompt REGISTRATION_SHARED_SECRET "Synapse registration shared secret"
  prompt MACAROON_SECRET_KEY "Synapse macaroon secret key"
  prompt FORM_SECRET "Synapse form secret"

  write_env
  render_templates

  echo "Configuration written to $ENV_FILE"
  echo "Run one of:"
  echo "  docker compose up -d"
  echo "  docker compose --profile monitoring up -d"
}

main "$@"

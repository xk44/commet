# Commet Federation Kit (CFK)

CFK is an opinionated, single-command deployment starter for a production-grade Matrix homeserver.

## What is included

- Synapse + Postgres
- Reverse proxy (Caddy) with automatic ACME TLS
- `.well-known` templates for federation-ready discovery
- TURN (coturn) pre-configuration for calls/screenshare
- Healthchecks on Postgres and Synapse services
- Optional monitoring profile (Prometheus + Grafana)
- BYOD bootstrap wizard for first-time setup (renders *.tmpl files)
- Idempotent upgrade helper
- Troubleshoot bundle generator with basic secret redaction
- Optional local-only non-federated mode

## Quick start

```bash
cd cfk
./scripts/byod-wizard.sh
docker compose up -d
```

Optional monitoring stack:

```bash
docker compose --profile monitoring up -d
```

## Non-federated / simple mode

Use this mode for a quick private/local server setup:

```bash
docker compose -f docker-compose.yml -f docker-compose.simple.yml up -d
```

This keeps Synapse local-only and disables TURN.

## Idempotent upgrades

```bash
./scripts/upgrade.sh
```

## Quick troubleshoot command

```bash
./scripts/troubleshoot.sh
```

The command generates a tarball with service status + logs and performs basic redaction for obvious secret patterns.

## Recommended ports / firewall checklist

Open inbound:

- `80/tcp` for ACME HTTP challenge and redirects
- `443/tcp` for Matrix client + federation traffic over HTTPS
- `3478/tcp` and `3478/udp` for TURN
- `5349/tcp` for TURN over TLS
- `49160-49200/udp` for TURN relay media

If using optional dashboards externally:

- `3000/tcp` Grafana (recommended to keep internal)
- `9090/tcp` Prometheus (recommended to keep internal)

Hardening checklist:

- Restrict SSH by source IP and disable password login
- Keep dashboard ports private or behind VPN/SSO
- Rotate `.env` secrets regularly
- Back up `./data` and validate restore procedures

## Notes

- These files are intended as a deploy starter, not a complete hardening guide.
- Replace defaults and review Synapse/Caddy/coturn configuration before production use.

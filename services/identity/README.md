# Identity

Dart/Shelf service with an independently owned PostgreSQL database. Verified email
registration, password sign-in/recovery, per-device opaque sessions and encrypted
transactional SMTP outbox. No medical records or document bytes are stored here.

Run through [local Compose](../../docs/accounts-and-sessions.md) or
[server Ansible](../../infra/ansible/README.md). Do not start a host daemon in deployment.
[ADR 0012](../../docs/adr/0012-accounts-and-sessions.md) records the boundaries and limits;
[OpenAPI](../../contracts/openapi/identity.yaml) specifies the public API.

Required runtime configuration: `IDENTITY_DATABASE_URL`, `IDENTITY_SERVICE_KEY`,
`IDENTITY_MAIL_KEY` (base64 32-byte AES key), `SMTP_HOST`, `SMTP_FROM`.
Optional: `SMTP_PORT` (587), `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_SSL`,
`SMTP_ALLOW_INSECURE` (false), `IDENTITY_SECURE_COOKIE` (true), `IDENTITY_BIND`, `PORT`.
Secrets are never printed. `--health` performs a loopback readiness request.

Tests use only the local `identity_tests` database. Production defaults use PBKDF2
600000; most transaction tests inject a cheaper verifier, with a separate test of
the production cost. Mail tests use a fake recipient sink, the HTTP probe uses Mailpit.

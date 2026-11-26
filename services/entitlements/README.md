# Entitlements

Independent Dart/PostgreSQL cloud policy service. Three capability flags, expiry,
active-record/storage-byte/monthly-recognition limits. Usage belongs to Records,
Documents and Processing; this service owns policy revisions, admin receipts and
CloudPolicyChanged outbox only. No medical data, user tokens or payment details.

[Contract and operations](../../docs/cloud-access.md),
[ADR 0013](../../docs/adr/0013-cloud-rights-and-quotas.md).
Required configuration: ENTITLEMENTS_DATABASE_URL, CLOUD_SERVICE_KEY, CLOUD_ADMIN_KEY.
Start through Compose/Ansible. `--health` checks loopback readiness;
`--grant` reads administrative JSON on stdin and calls the loopback API using the
container's admin key. The service port is never published on the host.

PostgreSQL tests use only `entitlements_tests`, with synthetic owners and fake keys.

# Provider Directory

Реестр семи источников, durable расписание и опубликованный публичный каталог.
Владелец собственной БД PostgreSQL; задания получают отдельные микросервисы
`workers/provider_connector`. [Эксплуатация](../../docs/operations/provider-connectors.md),
[ADR](../../docs/adr/0017-provider-connectors.md),
[HTTP-контракт](../../contracts/openapi/provider-directory.yaml).

`DIRECTORY_DATABASE_URL`, `DIRECTORY_ADMIN_KEY` и семь `DIRECTORY_*_KEY`
обязательны. Ключи различаются и имеют длину не менее 32 символов.
По умолчанию bind `127.0.0.1:8086`, config `config/sources.json`,
seed `config/catalog.json` (в Docker копируется из пакета).
Миграции идемпотентны и выполняются до readiness. Запуск — через Compose/Ansible.

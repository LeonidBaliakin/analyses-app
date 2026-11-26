# Notifications scaffold

Внутренний Shelf/PostgreSQL orchestrator: simulation bindings, намерения, три
логические очереди, leases, идемпотентные receipts и transactional outbox. Данные
принадлежат этому сервису. Workers обращаются только по HTTP.

Это каркас имитации. В нём нет отправки провайдерам, привязки реальных адресатов,
публичных вебхуков, пользовательских настроек и чтения бизнес-outbox других сервисов.
`webhooks/*` возвращает 503. Публичные порты отсутствуют.

[Контракт и переходы](../../docs/messenger-integrations.md),
[OpenAPI](../../contracts/openapi/notifications.yaml),
[инструкция оператору](../../docs/operations/messengers.md).

Сборка — из корня репозитория с `-f services/notifications/Dockerfile`.
В deployment применяется optional Compose profile `messengers`.
БД `notifications` создаётся bootstrap job, schema v1 — сервисом при запуске.
Для тестов нужна отдельная `notifications_tests` на локальном PostgreSQL 55438
из `infra/documents`; альтернативный URL — `NOTIFICATIONS_TEST_DATABASE_URL`.
Тесты очищают только указанную тестовую БД, не направляйте их на рабочую.

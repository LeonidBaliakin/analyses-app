# Health records synchronization

Dart/Shelf + собственная PostgreSQL БД `records`. Владеет версиями подтверждённых
записей, доступом профиля, receipts, change log и RecordChanged outbox. Медицинский
DTO общий с клиентом (`packages/record_sync`); пакет остаётся standalone с lockfile.
Оригиналы и OCR не читает, отправки внешним AI нет.

[Сценарий/протокол](../../docs/reports-and-sync.md), [ADR 0011](../../docs/adr/0011-period-reports-and-record-sync.md),
[OpenAPI](../../contracts/openapi/records.yaml). Запускается через development Compose
профиль `sync` либо [серверный Ansible/Compose](../../infra/ansible/README.md).

Тесты используют отдельную PostgreSQL `records_tests` и синтетические значения.
Bootstrap identities/grants — пилотная авторизация; публичные аккаунты/врачебные права
и платежи ещё не подключены. Повтор grant не восстанавливает отозванное can_write.

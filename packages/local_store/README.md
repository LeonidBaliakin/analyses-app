# local_store

Транзакционное SQLite-хранилище на Drift. Получает внедрённый `QueryExecutor`,
реализует порт `HealthRecordsRepository` из чистого `medical_domain`.
Открытие native/WASM находится в адаптере приложения.

Схема, миграция, outbox, ограничения и сценарии проверки описаны в
[локальных записях](../../docs/local-records.md) и [ADR 0006](../../docs/adr/0006-local-health-records.md).

`test/records_database_test.dart` использует настоящие SQLite-транзакции и файлы.
`tool/browser_probe.dart` — синтетический тест в настоящем браузере: seed,
устаревшая форма в одной вкладке, правка в другой и повторное открытие.

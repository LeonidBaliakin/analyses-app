# Проверка облачных прав и квот, 26 ноября 2026

Синтетические данные и локальные Docker-стенды. [Контракт](../cloud-access.md),
[ADR 0013](../adr/0013-cloud-rights-and-quotas.md).

153 теста прошли: health_app 128, cloud_access 2, Entitlements 3, Documents 9,
Records 5, Processing 6. Новые PostgreSQL-проверки используют только отдельные
`entitlements_tests`, `documents_tests`, `records_tests`, `processing_tests`.

- Независимые флаги и expiry по PostgreSQL, отсутствие grant у read key, replay
  одного operationId, изменённый payload, stale revision, атомарный policy/outbox.
- Параллельные создания записей, полнота квоты, правки/удаления/повторы без нового
  расхода, отказ после отзыва, canWrite=false при недоступном policy backend.
- Независимый storage flag, used/reserved, replay reserve, полный и уменьшенный
  лимит, неизменяемый исходник и чтение после отзыва/отказа backend.
- Monthly slot, replay jobId без двойного резерва, отказ новой задачи, освобождение
  при отмене/ошибке, ready→used, другой месяц, отзыв перед worker, чтение прежнего
  draft. Ошибка вставки quota ledger откатывает job; ошибка completion outbox не
  оставляет charged slot. Миграция Processing 1→2 сохраняет jobs и не дублирует ledger.
- HTTP policy client отвергает чужого owner/версию/невалидные лимиты и отказ backend.
- Widget/ViewModel: значения квот RU/light и EN/dark, окно 375 px, увеличение до
  1020 px с эмулированным шарниром и текстом 140%, сохранение ввода. Сбой обновления
  сохраняет предыдущий snapshot с явной отметкой устаревания, сессия не исчезает.

`tool/cloud_access_smoke.dart` прошёл против полного локального Ansible deployment
на Docker Desktop ARM64, API loopback 18098. Политика bootstrap-владельца временно
меняется и восстанавливается в finally. Реальные HTTP и SQLite проверяют:

1. Нулевой record limit оставляет подтверждённую локальную запись и одну операцию
   в устойчивом outbox; после grant та же операция проходит без нового ID.
2. Нулевой storage limit отвергает резерв до загрузки; разрешённый синтетический PDF
   проходит reserve/stage/finalize.
3. Нулевой monthly limit отвергает processing job до постановки в очередь/AI.
4. Отзыв трёх прав отражается в capabilities, но готовый оригинал скачивается с тем
   же SHA-256. Подтверждённые медицинские данные не удаляются.

Синтетический результат/PDF остаются в локальном стенде, временная SQLite удалена.
Тест не отправляет реальные медицинские документы и не вызывает внешний AI API.

Ansible создал отдельную БД/образ Entitlements, подключил общий Dart-контракт к
Documents/Records/Processing и мигрировал Processing без очистки volumes. Первый
и повторный deployment завершились с `failed=0`, `unreachable=0`; readiness checks
Documents, Processing, Records, Identity и cloud-access прошли. SHA-256 fingerprints
всех прежних credentials сохранились, добавлены разные policy read/admin ключи.

Проверены анализ изменённых Dart-пакетов, форматирование, OpenAPI/YAML и Markdown
ссылки. Оплата, реальные магазины, внешний SMTP и проверки на физических телефонах
не входили в этап. Числовые лимиты не доказывают нагрузочную пригодность сервера и
не ограничивают суммарный размер исторических/производных/служебных данных.

В браузере через Flutter web-server проверен вход синтетического аккаунта, реальные
права и три расходных счётчика в тёмной теме, затем выход. Browser console errors
отсутствуют. Chrome debug/DWDS-сеанс не смог установить соединение; проверка UI
выполнена через web-server. Native-сборки и новые установки в этом этапе не запускались.

Для web-server подключён DTD: hot reload через Dart/Flutter MCP успешен, runtime errors
отсутствуют. Итоговый сквозной probe повторён после Ansible-обновления и снова прошёл.

# Каркас интеграций с мессенджерами

Реализован 26.11.2026: **только имитация** для Telegram, VK и MAX. Это подготовка
общего протокола и deployment; боты не подключены, реальные сообщения не отправляются.
Настройки каналов Flutter остаются демонстрационными. Решение —
[ADR 0014](adr/0014-messenger-scaffolding.md).

## Состав

- `services/notifications`: владеет БД `notifications`, намерениями, внутренними
  simulation bindings, очередями по channel, leases, receipts и outbox.
- `workers/messenger_delivery`: отдельные адаптеры Telegram/VK/MAX и отдельные
  контейнеры. Stateless workers получают задания через API, без доступа к БД.
- [Compose](../infra/server/compose.yaml): профиль `messengers`, internal network
  для workers без выхода в интернет; порты не публикуются.
- [Ansible](../infra/ansible/README.md): opt-in профиль, persistent ключи,
  миграции и readiness. По умолчанию профиль выключен, каждый канал `disabled`.

Одна таблица хранит независимые логические очереди: claim Telegram не выбирает
VK/MAX; каждый worker имеет собственный ключ и режим. Изоляция БД по каналам,
provider callbacks и собственное канальное хранение адресатов — будущий этап.
Общая БД очередей сейчас является общей точкой отказа.

## Внутренний контракт v1

[OpenAPI](../contracts/openapi/notifications.yaml). Все JSON-запросы содержат
`schemaVersion: 1`; неподдерживаемые версии и лишние поля отвергаются. Тело до
8 КиБ. HTTP открыт только внутри доверенной сети deployment; клиентам приложения
эти ключи и API не выдаются. При разделении по хостам потребуется TLS/mTLS.

| Вход | Ключ | Назначение |
|---|---|---|
| `POST /internal/bindings` | admin | Создать/выключить только simulation binding |
| `POST /internal/notifications` | publisher | Идемпотентно поставить намерение |
| `GET /internal/notifications/{id}` | publisher | Текущее состояние |
| `POST /internal/channels/{channel}/claim` | ключ этого канала | Lease одного задания |
| `POST /internal/channels/{channel}/result` | ключ этого канала | Отдельное подтверждение результата попытки |
| `GET /health` | нет | Готовность БД, `simulationOnly: true` |

Binding содержит opaque `bindingId`, `ownerId`, channel, enabled и обязательный
`simulationOnly: true`. Адресов Telegram/VK/MAX в нём нет. Владелец/канал binding
неизменяемы; повтор меняет только enabled. Это административная тестовая запись,
не подтверждённое пользовательское согласие и не привязка учётной записи Identity.

Intent содержит `notificationId`, `ownerId`, channel, `bindingId`, template и
locale. Проверяются владелец/канал/активность binding. Нельзя передать текст,
медицинские значения, имя пациента, внешний recipient ID, документ или URL.
Допустимы `activity_available` и `processing_ready`, языки ru/en; тексты предлагают
открыть приложение, ссылок пока нет. Уведомление о готовности обработки не
подтверждает медицинский черновик.

`notificationId` — одновременно idempotency key и correlation ID. Будущий
publisher должен сохранять стабильный ID для сочетания source event + channel +
binding и повторять его после потери ответа. Повтор идентичного intent возвращает
текущее состояние; другой payload с тем же ID даёт 409. После отключения binding
повтор enqueue даёт 403, прежний результат доступен через GET. Новый ID означает
новое намерение: сам сервис не может распознать дубликат с другим ID.

Claim возвращает `attemptId`, opaque binding, template/locale, channel и
`simulationOnly`. Выдача защищена `FOR UPDATE SKIP LOCKED`; lease 60 секунд,
максимум 5 попыток, TTL намерения 24 часа. Часы PostgreSQL задают сроки. Worker
подтверждает результат отдельно; одинаковый receipt повторяется без новой записи
и outbox-события, изменение receipt даёт 409. Устаревшая попытка не меняет состояние.

| Состояние | Значение и дальнейшее поведение |
|---|---|
| queued | Ожидает claim |
| leased | Выдано одной попытке |
| simulated | Терминальная имитация; это не отправка и не доставка |
| retry | Только явно безопасные `transport_not_sent` / `provider_rate_limited`; задержка 1–86400 с, по умолчанию 30 с |
| unknown | Неопределённый результат или истёкший lease; автоматически не повторяется |
| failed | Ошибка адаптера либо исчерпаны попытки |
| cancelled | Истёк TTL или binding отключён |

Истечение lease переводит leased → unknown при следующем claim данного канала.
Пока worker выключен, автоматической уборки нет. Отзыв binding проверяется при
enqueue/claim/result. Уже начатый внешний эффект будущего live-адаптера таким
отзывом отменить нельзя; текущий каркас внешних эффектов не имеет.
`retry + ambiguous_result` отклоняется. Предусмотренные retry/unknown/failed
исходы доступны внутреннему протоколу для будущих адаптеров; текущий dry-run
worker отправляет только `simulated + dry_run`.

Запись/переход состояния и `NotificationStateChanged` в `notification_outbox`
атомарны. Event ID = `notificationId:revision`. Экспорт outbox, метрики backlog,
retention и ручное разрешение unknown пока не реализованы. Очередь и receipts
сохраняются в PostgreSQL volume; outbox/receipts нельзя очищать независимо ради
повторной отправки. Непрерывные synthetic прогоны требуют отдельной тестовой БД.

Ошибки: 400 schema/ID/недопустимые поля, 401 неверный ключ, 403 binding_denied,
404 not_found, 409 operation_mismatch/binding_mismatch/receipt_mismatch/stale_lease,
413 too_large, 503 unavailable. `webhooks/*` всегда отвечает 503
`webhook_not_implemented`, не принимает события как обработанные.
Логи workers содержат только техническое событие/канал/режим; текст и ключи не
печатаются. Health выдаёт технические счётчики процесса без адресатов и payload.

## Следующий этап перед реальной отправкой

1. Публичный API настроек и opt-in через Identity; одноразовая привязка с TTL,
   проверкой owner/profile и подтверждением получателя, отключение и удаление.
2. Провайдерные webhook handlers: проверка секрета/источника/принадлежности боту,
   дедупликация входящих событий, durable inbox перед ACK; ответы confirmation VK.
3. Publisher из бизнес-outbox через API/события, без чтения таблиц соседних
   сервисов, с серверной проверкой настроек и применимых cloud entitlements.
4. Live adapters, secret mounts, разрешённый egress, rate limits/backoff,
   provider message ID, классификация принятого/неопределённого результата,
   проверенные provider-specific правила дедупликации и callback receipts.
5. Отдельная политика хранения адресатов, ротация/backup/restore, мониторинг
   backlog/unknown/401/429, приложение по HTTPS/universal links и приёмка.

Добавление токенов или переключение переменной не выполняет эти пункты. Текущий
бинарный файл отвергает `live`. Регистрация вебхуков до реализации обработчиков
создаст повторные ошибки провайдера, поэтому адреса пока не регистрируют.

[Действия оператора](operations/messengers.md) отделены от этих задач разработки.

## Проверка

Тесты Notifications используют отдельный PostgreSQL и проверяют права, схему,
конкурентные enqueue/claim, повтор ACK, потерю lease/перезапуск, отзыв binding,
TTL, безопасные повторы и rollback при отказе outbox. Worker tests проверяют
все три адаптера, запрет live/чужого канала/неизвестной схемы/произвольного payload,
повтор ACK без повторного simulate. Сквозной
[smoke](../infra/server/messengers_smoke.py) работает через контейнерный HTTP:
3 синтетических intent, повтор enqueue, ровно одна simulated попытка на канал,
после проверки bindings выключаются. Это не проверка внешних API и доставки.

[Фактические результаты локального прогона 26.11.2026](reports/messengers-scaffold-2026-11-26.md).

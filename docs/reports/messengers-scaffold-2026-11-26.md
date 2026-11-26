# Проверка каркаса мессенджеров, 26.11.2026

Проверялся текущий checkout, локальный Docker Desktop на Mac, отдельный deployment
`.runtime/server-check`, API существующего стека на loopback 18098. Notifications
и workers не публикуют host ports. Все задания синтетические, все три канала
в dry_run; внешние API и реальные получатели не использовались.

## Код и контракт

- Notifications: 9 тестов с реальным PostgreSQL в отдельной `notifications_tests`.
- Worker: 6 тестов, включая все адаптеры и потерянный ACK.
- `dart analyze` обоих пакетов: No issues found; MCP analyze: No errors.
- `dart format --output=none --set-exit-if-changed`: 9 файлов, без изменений.
- OpenAPI/YAML: синтаксис и локальные `$ref` проверены; генератор клиентов не запускался.
- Относительные Markdown-ссылки и `git diff --check`: пройдены.

## Deployment и имитация

- Ansible syntax-check пройден. Первый запуск: ok=19, changed=6,
  unreachable=0, failed=0. Повтор после финальной правки: ok=19, changed=2,
  unreachable=0, failed=0. Изменения повтора — build inputs и пересборка.
- Compose config проверен с профилем messengers и без него.
- Notifications и delivery-telegram/vk/max: healthy.
- `infra/server/messengers_smoke.py`: по одному intent на канал, повтор enqueue,
  итог simulated, attempts=1 у каждого. Созданные bindings после прогона выключены.
- После явного restart Notifications и всех трёх workers сохранены 3 intent,
  3 receipt и 9 outbox events, повторных попыток не появилось.
- Проверен неизменный hash persistent bootstrap credentials, значения не выводились.
- Docker inspect: worker подключён только к сети с Internal=true, host ports отсутствуют.

Локальные логи: `.runtime/messengers-deploy.log`, `.runtime/messengers-redeploy.log`.
В Git они не входят. На стенде оставлен режим имитации; проектные defaults —
выключенный профиль и disabled у каждого канала.

Проверка не подтверждает доставку Telegram/VK/MAX, публичный TLS/webhook,
привязку реального пользователя или установку Docker на чистой Ubuntu.
[Ограничения реализации](../messenger-integrations.md),
[задачи оператора](../operations/messengers.md).

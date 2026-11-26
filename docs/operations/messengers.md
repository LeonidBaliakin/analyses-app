# Мессенджеры: действия оператора

Подготовлено 26.11.2026 для [каркаса Telegram/VK/MAX](../messenger-integrations.md).
Сейчас работают только disabled и dry_run. Реальных sender, вебхуков и
пользовательской привязки ещё нет. Токены ботов текущим образом не используются;
`live` отвергается. Не регистрируйте вебхуки на этот каркас.

## Что можно подготовить сейчас

1. Назначить владельца интеграций и резервного администратора; создать отдельные
   тестовые и рабочие аккаунты ботов/сообществ под контролем организации.
2. Выбрать каналы, назначение уведомлений и языки. Базовый сценарий — общее
   сообщение «В приложении есть обновление»; результаты и оригиналы остаются в
   приложении. Утвердить явное согласие пользователя и способ отключения канала.
3. Подготовить домен, DNS и HTTPS с доверенным сертификатом для будущего
   контейнерного reverse proxy. Внешним станет только нужный webhook route;
   `/internal/*`, БД и health/admin API должны остаться закрытыми.
4. Подготовить защищённое хранилище секретов, права доступа, резервные копии и
   ответственных за ротацию. Токены передаются серверу через секреты, не через
   чат, Git, клиентское приложение, shell history или access logs.

### Telegram

Создать бота через BotFather, зафиксировать bot ID/username и сохранить токен в
хранилище секретов. Создание и управление описаны в
[официальном руководстве Telegram](https://core.telegram.org/bots/features#botfather).
Подготовить отдельный случайный webhook secret. После реализации обработчика
нужно будет вызвать `setWebhook` с HTTPS URL и `secret_token`; сервер проверит
`X-Telegram-Bot-Api-Secret-Token`. Детали —
[setWebhook](https://core.telegram.org/bots/api#setwebhook).
Привязку начнёт сам пользователь из приложения и подтвердит в боте; вручную
вписанный chat ID не будет заменять подтверждение. Это проектируемый сценарий,
в текущем каркасе его нет.

### VK

Подготовить управляемое организацией сообщество и администратора; сохранить
group ID и community access token с необходимым доступом к сообщениям.
Набор разрешений и актуальную версию API проверить в кабинете VK при подключении:
веб-руководство `dev.vk.com` в этой проверке было недоступно. Официальный SDK
документирует community access token и обработку Callback API:
[VKCOM/vk-php-sdk](https://github.com/VKCOM/vk-php-sdk#readme).
Для будущего Callback API потребуются секрет, строка подтверждения и согласованный
HTTPS URL; подтверждать адрес можно после реализации обработчика. Согласовать
разрешённые типы событий и разрешение пользователя на сообщения.

Разработчик должен сохранять стабильный `random_id` при повторе `messages.send`,
а не генерировать новый для каждой попытки. Параметр дедупликации описан в
[официальной схеме VK](https://github.com/VKCOM/api-schema-typescript/blob/master/src/methods/messages.ts).
Это задача реализации sender, а не ручная настройка оператора.

### MAX

Получить доступ к платформе MAX для бизнеса, пройти требуемые платформой шаги
создания/проверки бота, сохранить bot ID и токен. Текущая документация указывает
получение токена в настройках чат-бота на платформе либо в MAX для бизнеса;
требования регистрации следует сверить для своей организации. Токен передаётся
через `Authorization`, не query-параметр:
[авторизация MAX](https://dev.max.ru/docs-api/methods/GET/subscriptions).

После реализации обработчика потребуется подписка на согласованные события
через `POST /subscriptions`, HTTPS URL и отдельный secret для проверки
`X-Max-Bot-Api-Secret`. В актуальных документах API указан домен
`platform-api2.max.ru`; HTTP и самоподписные сертификаты вебхуков больше не
поддерживаются. При вводе live-адаптера нужно проверить доверенную цепочку CA
согласно документации, не отключая проверку TLS:
[вебхуки MAX](https://dev.max.ru/docs-api/methods/POST/subscriptions).

## Запустить внутреннюю имитацию

Используется обычный [Ansible deployment](../../infra/ansible/README.md).
В vars выбранного inventory задать:

```yaml
analyses_messengers_enabled: true
analyses_telegram_delivery_mode: dry_run
analyses_vk_delivery_mode: dry_run
analyses_max_delivery_mode: dry_run
```

Роль добавит недостающие внутренние ключи в `.secrets/bootstrap.json`, сохранив
существующие, и запишет `.env` с правами 0600. Разные ключи:
`NOTIFICATIONS_ADMIN_KEY`, `NOTIFICATIONS_PUBLISHER_KEY`,
`NOTIFICATIONS_TELEGRAM_KEY`, `NOTIFICATIONS_VK_KEY`, `NOTIFICATIONS_MAX_KEY`.
Это ключи внутренних API; они не являются токенами ботов. В каждый worker
передаётся только ключ его канала. Провайдерные секреты пока не монтируются.

После deployment на сервере:

```bash
cd /opt/analyses-app
sudo docker compose --profile messengers ps
sudo docker compose exec -T notifications /app/notifications --health
sudo docker compose exec -T delivery-telegram /app/delivery --health
sudo docker compose exec -T delivery-vk /app/delivery --health
sudo docker compose exec -T delivery-max /app/delivery --health
```

`notifications-db` штатно завершён с кодом 0. Workers в dry_run здоровы при
успешном обращении к очереди за последние 30 секунд. Их health не подтверждает
связь с внешним мессенджером. С контроллера с доступом к Docker этого deployment
можно выполнить синтетический probe из checkout:

```bash
python3 infra/server/messengers_smoke.py /absolute/path/to/deployment
```

Probe создаёт три synthetic binding/intent, повторяет запросы, ждёт `simulated`
с одной попыткой на канал, затем выключает созданные bindings. Тестовые строки
и история сохраняются; запускайте на тестовом deployment. Для проверки по одному
каналу включайте dry_run только ему; общий probe требует dry_run всех трёх.

Административные операции доступны через stdin контейнерного helper. Пример
создания **только синтетической** привязки:

```bash
sudo docker compose exec -T notifications /app/notifications --request <<'JSON'
{"operation":"binding","body":{"schemaVersion":1,"bindingId":"synthetic-tg","ownerId":"synthetic-owner","channel":"telegram","enabled":true,"simulationOnly":true}}
JSON
```

Enqueue и status через тот же helper:

```bash
sudo docker compose exec -T notifications /app/notifications --request <<'JSON'
{"operation":"enqueue","body":{"schemaVersion":1,"notificationId":"synthetic-event-tg-1","ownerId":"synthetic-owner","channel":"telegram","bindingId":"synthetic-tg","template":"activity_available","locale":"ru"}}
JSON
sudo docker compose exec -T notifications /app/notifications --request <<'JSON'
{"operation":"status","notificationId":"synthetic-event-tg-1"}
JSON
```

Чтобы отключить этот binding, повторить первую команду с `enabled: false`.
Для паузы канала задайте его режим `disabled` и повторите deployment: задания
останутся в БД до возобновления/истечения TTL. Для немедленной остановки всех workers:

```bash
sudo docker compose --profile messengers stop delivery-telegram delivery-vk delivery-max
```

`analyses_messengers_enabled: false` исключает профиль из следующего `up`, но
сам по себе не останавливает уже созданные контейнеры. Их нужно остановить явно:

```bash
sudo docker compose --profile messengers stop delivery-telegram delivery-vk delivery-max notifications
```

Не используйте `down -v` для отключения. PostgreSQL volume и `.secrets` нужны
для восстановления очереди и идемпотентности. Backup/restore всего серверного
стека пока требует отдельного эксплуатационного процесса.

## Что понадобится для боевого включения

Сначала команда разработки должна завершить opt-in/привязки, webhook/inbox,
sender/receipts, publisher из бизнес-outbox и мониторинг, перечисленные в
[техническом контракте](../messenger-integrations.md#следующий-этап-перед-реальной-отправкой).
Оператор после этого:

1. Разворачивает согласованный релиз с live adapters и закрытыми internal API.
2. Подключает provider secrets только соответствующим каналам и проверяет
   разрешённый egress, HTTPS/CA и маскирование токенов в proxy/error logs.
3. Регистрирует webhook каждого провайдера, настраивает события/секрет и
   проверяет отвержение неверного секрета и повтор одного события без дублей.
4. Подключает отдельный тестовый аккаунт через подтверждённый пользовательский
   сценарий; по явному разрешению выполняет реальную пробную отправку общего
   уведомления и проверяет отказ/отзыв согласия, блокировку бота и rate limits.
5. Проверяет мониторинг очереди/unknown/ошибок, восстановление после рестарта,
   ротацию токена и способ выключить один канал. Только затем включает канал
   пользователям, давшим согласие.

Для передачи разработчику достаточно несекретного набора: выбранные каналы,
bot username/ID или group ID, домен, окружение test/prod, типы уведомлений,
контакт ответственного и ссылки на секреты в принятом хранилище. Сами токены
в переписку не присылаются. Текущая подготовка не требует регистрации вебхуков,
реальной рассылки или отправки медицинских документов.

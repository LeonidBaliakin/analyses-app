# Documents: локальный рабочий срез

Сервис владеет облачными метаданными, доступом, сессиями, квотой и outbox;
SeaweedFS OSS хранит закрытые байты. [Контракт OpenAPI](../../contracts/openapi/documents.yaml),
[решение и пределы](../../docs/adr/0008-originals-and-documents.md).

Из корня репозитория один раз создайте локальную конфигурацию:

```bash
python3 infra/documents/init_dev.py
```

Скрипт не перезаписывает существующие ключи. В `infra/documents`:

```bash
docker compose config --quiet
docker compose up -d --build
docker compose logs --tail=20 documents
```

API: `http://127.0.0.1:18088`. В приложении сначала создайте локальный профиль,
затем откройте «Оригиналы документов» → «Подключить хранилище». Для локального
стенда токен — значение `DOCUMENTS_DEV_TOKEN` из игнорируемого `.env`.
Он не является ключом S3 и хранится приложением только в памяти.

Для browser CORS запустите приложение из `apps/health_app` с фиксированным origin:

```bash
flutter run -d chrome --web-port=7357
```

Стенд разрешает `http://localhost:7357` и `http://127.0.0.1:7357`.
Для другого origin измените `DOCUMENTS_ALLOWED_ORIGINS` в compose и пересоздайте
только Documents. Native-клиент не использует браузерный CORS. HTTP разрешён клиентом
только для loopback и Android emulator host `10.0.2.2`; внешний сервер требует HTTPS.

Сквозная проверка из `apps/health_app`:

```bash
dart run tool/documents_smoke.dart
```

Она использует только синтетические PDF/PNG и постоянные ID `smoke-v2-*`, повтор
не создаёт новые облачные оригиналы. Проверяет локальный перезапуск, два upload,
download и SHA-256. Можно повторить после `docker compose restart` без удаления volumes.

Для тестов PostgreSQL создайте **отдельную** БД из `infra/documents`:

```bash
docker compose exec -T postgres createdb -U documents documents_tests
```

В `services/documents`:

```bash
dart pub get --enforce-lockfile
dart analyze
dart test
```

Агенты запускают тесты через Dart/Flutter MCP. Тесты используют `documents_tests`
и очищают только её таблицы; основной `documents` не затрагивается. Для fault injection
S3 в этих тестах подменяется памятью, а сквозной probe использует реальный SeaweedFS.

Завершение стенда: `docker compose stop` из `infra/documents`. Именованные volumes
сохраняют данные. Удаление volumes не является обычной остановкой или сбросом тестов.
Bootstrap, фиксированная квота и один локальный профиль предназначены для разработки;
публичный аккаунтный сервер, multipart, удаления и бэкапы пока не реализованы.

Полный серверный стек, включая контейнерную LLM, разворачивается через
[Ansible](../../infra/ansible/README.md). Этот локальный development-стенд не заменяет серверный deployment.

Подтверждённые записи синхронизируются через отдельный [Records API](../../docs/reports-and-sync.md),
проксируемый Documents. Development Compose использует профиль `sync`.

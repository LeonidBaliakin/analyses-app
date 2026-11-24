# Processing: собственный OCR/LLM worker

Сервис владеет заданиями, промежуточным OCR, производным черновиком и DraftReady outbox
в своей PostgreSQL БД. Оригиналы читает через авторизованный Documents API. Медицинские
результаты создаёт клиент только после явного подтверждения.

[Запуск, контракты, проверки и ограничения](../../docs/document-processing.md),
[ADR 0009](../../docs/adr/0009-shared-processing-draft.md),
[OpenAPI](../../contracts/openapi/processing.yaml).

Пакет имеет отдельные pubspec/lock. Для PostgreSQL-тестов нужен подготовленный
локальный стенд с `processing_tests`; данные рабочей БД не очищаются. Сервис запускается
с session advisory lock единственного лидера; при потере соединения лидера завершается.
Это development worker с восстановлением очереди, без распределённого масштабирования.

Для сервера используйте [Ansible/Compose](../../infra/ansible/README.md): OCR и LLM
работают в контейнерах. Хостовый llama-server относится только к Mac development-стенду.

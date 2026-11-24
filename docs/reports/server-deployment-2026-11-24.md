# Проверка Docker Compose и Ansible, 24 ноября 2026

Проверен полный серверный стек из `infra/server/compose.yaml`: PostgreSQL 18.1,
SeaweedFS OSS 4.55, Documents, Processing/Tesseract и отдельный контейнер inference.
llama.cpp b12679, source `af5c58347fdbc2cd19e65b278e81c8f528f8a175`, официальный
multiarch digest `sha256:6fab63852916c294cc8a2f1515079c4ca40248193eea8868ae742134335b989b`.
Модель — прежняя Qwen2.5-1.5B-Instruct Q4_K_M с проверенным SHA-256.

Контроллер: ansible-core 2.21.4, community.docker 5.3.0. Исполнение на локальном
Docker Desktop ARM64, отдельные project/volumes и loopback-порт 18098. Хостовая LLM
не используется этим стеком: Processing обращается к `http://inference:8080`.

Первый плейбук: `failed=0`, `unreachable=0`; контейнеры запущены, PostgreSQL и LLM
healthy, одноразовое создание Processing БД завершилось с кодом 0. Проверки `/health`
и авторизованной processing capability прошли. Оригиналы не публикуются через
открытый S3, наружу выведен только loopback-порт Documents.

`infra/server/smoke.py` прошёл до и после повторного Ansible-deploy:

- синтетический PNG 51 445 байт, SHA-256
  `36b20a6b63a08fcf534c48028cd6fd91bc5697955dff529ded777daed290c07c`;
- повторные reserve/upload/finalize, скачивание с тем же SHA-256;
- отказ 401 при чтении оригинала без bearer;
- повтор одного jobId, реальный Tesseract и контейнерная LLM, две строки черновика;
- evidence привязано к OCR, digest inference включён в версии;
- готовый job и оригинал сохранились после повторного deployment;
- bootstrap-секреты и ID всех контейнеров остались прежними.

На повторе плейбук снова завершился без ошибок: `changed=1` относится к Compose,
который повторно запускает идемпотентный job создания БД. БД не пересоздаётся,
секреты, исходники и manifest не меняются, сервисные контейнеры не заменяются.

Полная регрессия пункта 5: 170 Dart/Flutter/PostgreSQL тестов прошли. Дополнительно
проверены синтаксис Ansible, Compose config, Python compile, Markdown-ссылки и
`git diff --check`. Секреты/веса/deployment inventory исключены из Git.

Установка Docker через apt/systemd на чистом удалённом Ubuntu 24.04 не запускалась:
проверка использовала уже установленный Docker и `analyses_install_docker=false`.
Плейбук этой роли проверен синтаксически и сверён с официальной инструкцией Docker.
GPU, TLS reverse proxy, боевые аккаунты, backup/restore и нагрузочная пригодность
этим прогоном не подтверждаются. Качество пилотной модели по-прежнему требует ручной
проверки; этот smoke проверяет функциональный путь, не медицинскую точность.

[Инструкция развёртывания](../../infra/ansible/README.md),
[ADR 0010](../adr/0010-docker-compose-ansible.md).

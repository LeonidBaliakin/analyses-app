# Обработка оригинала и проверка черновика

Рабочий срез пункта 5: два реальных OCR/LLM-адаптера, один Dart-черновик,
локальные правки и отдельное подтверждение. [ADR 0009](adr/0009-shared-processing-draft.md),
[качество на фиксированном наборе](reports/processing-pilot-2026-11-24.md),
[API](../contracts/openapi/processing.yaml).

## Сценарий

В «Оригиналах документов» импортируйте синтетический PDF/PNG/JPEG и откройте
«Распознать и проверить». Выберите локальный или собственный серверный режим.
Для сервера сначала подключите Documents и загрузите оригинал. Облачная копия
сама по себе не запускает обработку. Внешний AI API не подключён; переключения
после ошибки нет.

Проверьте OCR и исходный фрагмент каждой строки, исправьте поля, исключите лишние
или добавьте пропущенные результаты. Дата вводится полностью, если её нет в источнике.
Кандидаты словаря не выбираются автоматически. Явный выбор показателя/единицы
фиксирует выпуск и проверенный контекст. «Сохранить черновик» не создаёт результаты;
«Подтвердить и сохранить» создаёт их атомарно с историей и outbox. После подтверждения
они доступны в списке анализов и могут редактироваться с сохранением происхождения.

Правки черновика, OCR и задания переживают перезапуск SQLite. Повтор подтверждения
не создаёт дубль. Новая обработка создаёт отдельное задание; второй раз подтвердить
тот же оригинал в первом срезе нельзя. Сбой LLM оставляет OCR для ручного заполнения.
Отменённое задание не публикует черновик. Прерванное задание можно повторить с прежним
ID и runtime; при смене runtime требуется новый запуск. Закрытие экрана не отменяет
работу, пока приложение живо. Несохранённые правки требуют выбора при закрытии.

## Контракты и хранение

`document_processing` хранит идентичность original/document/profile/job, SHA-256,
режим, выпуск словаря, версии OCR/model/prompt/worker/runtime. Поля исходника
содержат raw, номер страницы, смещение в OCR и issue; слова OCR — координаты и confidence.
Review хранится отдельно. Недоказанное поле сохраняется как отклонённое предложение,
а поле для проверки остаётся пустым. Позиции относятся к OCR, а не PDF text layer.

DTO worker `schemaVersion=1`: `runtimeId`, `versions`, `pages[{number,text,words}]`,
`rows[{page,evidence,name,value,unit,reference,date,laboratory,specimen,method}]`.
Строки и значения копируются без перевода единиц/десятичных разделителей. Общий
Dart-валидатор проверяет привязку к тексту, а затем предлагает нормализацию. Ошибки
самого OCR и неверное разделение колонок остаются предметом проверки человеком.

SQLite schema 4 добавляет processing_jobs, processing_drafts, draft_history,
draft_confirmations и confirmed_originals. Подтверждённый LabResult использует
payload 3 с documentSource; форматы 1/2 и старые outbox не переписываются. Прямое
изменение source запрещено. Ручная новая строка имеет пустой source, а не выдуманное
происхождение. Черновики пока не синхронизируются.

Processing имеет собственные jobs/processing_outbox и отдельную БД. Входные байты
получаются только через готовый оригинал Documents с повторной проверкой SHA-256.
До трёх активных заданий владельца, один исполняющий worker. Байты из очереди удаляются
при завершении/ошибке/отмене; оригинал Documents остаётся. Временные изображения
и файлы удаляются helper/adapters. OCR и черновики остаются в БД для восстановления;
автоматический retention производных пока отсутствует.

## Development runtime на macOS ARM64

Нужны Python 3.11+, Tesseract и Poppler (`tesseract`, `pdftoppm` в PATH).
Из корня репозитория:

```bash
python3 workers/document_processing/install_runtime.py
python3 workers/document_processing/make_config.py \
  .runtime/processing/manifest.json .runtime/processing/local-config.json
.runtime/processing/llama-b12359/llama-b12359/llama-server \
  --host 127.0.0.1 --port 18089 \
  --model .runtime/processing/qwen2.5-1.5b-instruct-q4_k_m.gguf \
  --alias qwen2.5-1.5b-q4_k_m-6a1a2eb6d156 \
  --ctx-size 8192 --parallel 1 --threads 4 --log-disable
```

Установщик загружает около 1,12 ГБ весов и закреплённые llama.cpp/tessdata,
проверяет SHA-256 и не сохраняет их в Git. GGUF:
[официальная модель Qwen, Apache 2.0](https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF),
revision `91cad51170dc346986eccefdc2dd33a9da36ead9`,
SHA `6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e`.
[llama.cpp b12359](https://github.com/ggml-org/llama.cpp/releases/tag/b12359),
[закреплённые OCR-данные](https://github.com/tesseract-ocr/tessdata_fast/tree/87416418657359cb625c412a48b6e1d6d41c29bd).
Runtime ID включает хеш worker и версии этих компонентов. Config хранит абсолютные
локальные пути: после переноса каталога создайте его заново. LLM слушает loopback.

Для Flutter desktop из `apps/health_app` передайте абсолютный путь:

```bash
flutter run -d macos \
  --dart-define=LOCAL_PROCESSING_CONFIG=/absolute/path/analyses-app/.runtime/processing/local-config.json
```

Реальные Dart-адаптеры проверены CLI на Mac; запуск helper из sandbox подписанного
macOS-приложения ещё не проверен. Linux-контракт есть, установщик поддерживает только
macOS ARM64. На Android/iOS/web кнопка локальной обработки сообщает недоступность;
есть ручной ввод и явно выбираемый серверный путь. Mobile FFI, загрузка весов в UI,
измерения на телефонах и системные фоновые задания пока отсутствуют.

## Серверное развёртывание

Полный контейнерный стек и Ansible находятся в [infra/ansible](../infra/ansible/README.md).
На сервере LLM запускается отдельным Compose-сервисом по закреплённому digest; ручной
запуск llama-server на хосте не нужен. [ADR 0010](adr/0010-docker-compose-ansible.md).

## Development-стенд с Mac inference

Сначала запустите [Documents](../services/documents/README.md). При работающем
локальном llama-server из корня выполните:

```bash
python3 infra/documents/prepare_processing.py
```

Затем из `infra/documents`:

```bash
docker compose --profile processing config --quiet
docker compose --profile processing up -d --build documents processing
```

Создаются отдельные `processing` и `processing_tests`; существующие БД не очищаются.
Processing не имеет host-порта. Клиент использует Documents `127.0.0.1:18088` и прежний
токен в памяти. Docker OCR использует свои Tesseract/Poppler, а LLM development-стенда —
тот же Mac через `host.docker.internal`. Полный серверный CPU deployment подготовлен отдельно в `infra/server` и
`infra/ansible`; этот development-стенд сохраняет Mac Metal для разработки. Не сохраняйте токены, медицинские данные и подписанные ссылки в логах.

## Воспроизведение проверки

Из корня (Pillow нужен только генератору синтетических изображений):

```bash
python3 -m venv .runtime/processing/venv
.runtime/processing/venv/bin/pip install -r workers/document_processing/requirements-fixtures.txt
.runtime/processing/venv/bin/python workers/document_processing/fixtures.py
python3 workers/document_processing/evaluate.py
python3 workers/document_processing/probe_failures.py
```

Генератор использует Arial из macOS; версии входных файлов фиксирует SHA-256.
Набор содержит русский PNG и PDF, английский качественный результат без даты,
бланк с вредоносными инструкциями и пустой лист. Из `packages/document_processing`:

```bash
dart run tool/evaluate.dart
```

Сводка считает отдельно ошибки OCR, извлечения LLM и полей после общего валидатора.
Из `apps/health_app`:

```bash
dart run tool/processing_smoke.dart
```

Probe использует настоящие адаптеры: OCR/LLM → общий черновик → правка → перезапуск
SQLite → подтверждение/повтор, проверяет отсутствие дублей и неизменность оригинала.
Серверный путь проходит через Documents и реальный SeaweedFS. Только синтетические
оригиналы probe/evaluation добавляются в локальный стенд. Unit/widget и PostgreSQL
проверки запускаются агентами через Dart/Flutter MCP; Processing-тесты очищают только
свою БД `processing_tests`.

# Развёртывание серверного стека

Все серверные процессы запускаются через [Docker Compose](../server/compose.yaml):
PostgreSQL, SeaweedFS OSS, Documents, Processing с OCR и отдельный CPU inference.
LLM не требует запуска процесса на хосте. Закреплён официальный multiarch-образ
llama.cpp b12679 (source `af5c58347fdbc2cd19e65b278e81c8f528f8a175`) по digest; модель и rus/eng tessdata проверяются SHA-256.

Автоматическая установка Docker рассчитана на Ubuntu 24.04 amd64/arm64 с SSH,
Python 3 и sudo. Для уже подготовленного Docker-хоста можно отключить роль
установки через `analyses_install_docker: false`. Серверу нужен выход к Docker registry,
Hugging Face и GitHub при первом запуске; после загрузки обработка идёт внутри стека.
Исходники берутся из текущего checkout контроллера, только по списку build inputs.

Из `infra/ansible`:

```bash
python3 -m venv ../../.runtime/ansible
../../.runtime/ansible/bin/pip install -r requirements-controller.txt
../../.runtime/ansible/bin/ansible-galaxy collection install -r requirements.yml
mkdir -p inventory
cp inventory.example.yml inventory/hosts.yml
# Укажите адрес и SSH-пользователя в inventory/hosts.yml.
../../.runtime/ansible/bin/ansible-playbook deploy.yml --syntax-check
../../.runtime/ansible/bin/ansible-playbook deploy.yml --ask-become-pass
```

Контроллер проверен с ansible-core 2.21.4 и community.docker 5.3.0. Inventory не попадает
в Git. При passwordless sudo параметр `--ask-become-pass` не нужен. Ключ SSH настраивается
стандартно через `ansible_ssh_private_key_file` или ssh-agent. Внешнее развёртывание
выполняется только по явно выбранному inventory; шаблон использует документационный IP.

Плейбук создаёт `/opt/analyses-app`, копирует минимальный build context, генерирует
секреты один раз, загружает закреплённые веса (~1,12 ГБ) и OCR-данные, создаёт БД
Processing через одноразовый Compose-job и поднимает контейнеры. На повторе секреты
и named volumes сохраняются. Исходники пересобираются при изменении; развёртывание
завершается проверкой `/health` и авторизованной processing capability.

Параметры роли находятся в [defaults/main.yml](roles/analyses_server/defaults/main.yml).
Обычно меняются `analyses_root`, `analyses_api_port`, `analyses_allowed_origins`,
`analyses_owner_id`, `analyses_profile_id` и `analyses_quota_bytes`. CPU-модель пилотная;
требования к качеству и ограничения — в [обработке документов](../../docs/document-processing.md).
Образ inference можно изменить только вместе с его digest; значение записывается
в версии runtime. GPU deployment пока не подготовлен.

## Доступ и обслуживание

По умолчанию наружу не публикуются PostgreSQL, S3, OCR или LLM. Documents слушает
только `127.0.0.1:18088` сервера. Для доступа без контейнерного HTTPS reverse proxy:

```bash
ssh -L 18088:127.0.0.1:18088 ubuntu@SERVER
```

В клиенте используется `http://127.0.0.1:18088`. Для browser добавьте его origin в
`analyses_allowed_origins`, например `http://localhost:7357`. При публичном доступе
подключите контейнерный HTTPS reverse proxy к Documents; bootstrap авторизация остаётся
пилотной и не заменяет учётные записи/управление доступом.

Файл `.secrets/bootstrap.json` на сервере содержит клиентский token и внутренние
учётные данные; доступ только владельцу каталога (обычно root). Получайте token
на сервере через SSH, не добавляйте файл в inventory, Git или логи. `.env` имеет
режим 0600, каталог `.secrets` — 0700. В контейнеры монтируются отдельные нужные файлы.
Ansible скрывает задачи с секретами и результат Compose, который может включать env.

На сервере:

```bash
cd /opt/analyses-app
sudo docker compose ps
sudo docker compose logs --tail=50 documents processing
sudo docker compose stop
sudo docker compose up -d --wait
```

`processing-db` штатно имеет состояние exited(0): это идемпотентное создание БД,
а не постоянно работающий сервис. `stop` сохраняет volumes. Не используйте `down -v`
для обычного обновления. Бэкапы PostgreSQL, SeaweedFS volume и `.secrets` нужно хранить
согласованно; автоматический backup/restore пока не входит в этот срез.
Не удаляйте bootstrap.json ради смены пароля: ротация требует согласования с БД/S3.

## Локальная проверка deployment

Используйте отдельный `analyses_project_name`, каталог внутри `.runtime`, свободный
`analyses_api_port`, `ansible_connection: local`, `analyses_install_docker: false`
и `ansible_become: false`. Это не проверяет установку Docker/systemd на чистой Ubuntu.
Повтор плейбука проверяет сохранность секретов/томов и идемпотентность запуска.
[Синтетический smoke probe](../server/smoke.py) принимает каталог deployment:

```bash
python3 infra/server/smoke.py /absolute/path/to/deployment
```

Он проверяет SHA при загрузке/скачивании, приватный доступ, повтор задания и реальный
OCR/LLM по внутреннему адресу inference. Используется только сгенерированный пример.

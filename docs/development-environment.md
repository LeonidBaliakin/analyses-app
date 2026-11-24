# Окружение разработки

## Зафиксированный SDK

Используем Flutter **3.50.0 stable**, включающий Dart **3.14.0**. Версия Flutter записана в [`.flutter-version`](../.flutter-version); файл фиксирует ожидаемую версию, но сам не переключает SDK.

На текущем Mac SDK установлен в `/Users/pavel/.local/share/flutter/3.50.0`. Команды `/opt/homebrew/bin/flutter` и `/opt/homebrew/bin/dart` ссылаются на его `bin/`. Использована чистая копия официального SDK из окружения «Книг»; исходная установка во временном каталоге не изменена. Framework revision: `ab2912035e160d9cad6306df307576da6128ebdb`.

Локальные настройки Flutter используют существующие Android SDK `/Users/pavel/Android/Sdk` и Java 21 `/opt/homebrew/opt/openjdk@21`. Установлен CocoaPods **1.17.0**. Пути относятся к этой машине; SDK и его кеши не хранятся в Git.

Проверка в новом терминале:

```bash
command -v flutter dart
flutter --version
dart --version
flutter doctor -v
```

На другой машине установите ту же версию из [официального архива Flutter](https://docs.flutter.dev/install/archive), добавьте `<flutter-sdk>/bin` в `PATH` и установите зависимости нужных платформ. Не запускайте `flutter upgrade` как часть обычной задачи: изменение SDK требует обновления зафиксированной версии и проверки совместимости.

## Официальные навыки

В `.agents/skills/` находятся шесть проектных и десять официальных навыков. Официальные установлены выбранными каталогами через `skill-installer`; полный набор плагинов и дубли Dart-навыков не устанавливались.

| Источник | Зафиксированная ревизия | Навыки |
|---|---|---|
| [flutter/agent-plugins](https://github.com/flutter/agent-plugins/tree/ff6d472ee66dbed566c4500edee460c94fde0a02) | `ff6d472ee66dbed566c4500edee460c94fde0a02` | Архитектура, responsive layout, исправление layout, widget/integration tests, routing, localization, JSON serialization |
| [dart-lang/skills](https://github.com/dart-lang/skills/tree/f84b16872b5d186f4e877511b49b93c204a1c4ef) | `f84b16872b5d186f4e877511b49b93c204a1c4ef` | Static analysis, unit tests |

Точные имена, исходные пути и SHA-256 файлов перечислены в [lock-файле](../.agents/official-skills.lock.json). Каждый внешний навык содержит исходную BSD-3-Clause лицензию. В `SKILL.md` нормализованы только хвостовые пробелы и завершающий перевод строки; lock-файл сохраняет хеши исходной и установленной версии.

Перед обновлением навыков выберите конкретную upstream-ревизию, прочитайте изменённые инструкции и вспомогательные файлы, обновите лицензии/хеши и проверьте diff. Не обновляйте навыки автоматически при запуске приложения или агента.

Примеры upstream согласуются с проектными границами:

- `ChangeNotifier`, `provider`, `freezed`, `go_router` и другие библиотеки из примеров не считаются выбранными зависимостями проекта без соответствующего решения.
- Сериализация DTO не переносит Flutter и `compute()` в чистое медицинское ядро.
- Driver extension для интерактивного тестирования подключается только в отдельной тестовой/debug-точке входа; production entrypoint его не включает.
- Названия MCP-команд в примерах сверяются с `tools/list` установленного сервера. Например, действия Flutter Driver могут предоставляться через `flutter_driver_command`.
- Поле `metadata.model` в upstream-навыках не является поручением менять модель агента.

Навыки доступны агентам в репозитории; после установки они должны появиться при следующем обращении. Общий процесс описан в [agent-development.md](agent-development.md).

## Dart/Flutter MCP для Codex

Проектный сервер `dart_flutter` настроен в [`.codex/config.toml`](../.codex/config.toml). Используется встроенный в Dart SDK сервер, отдельный npm-пакет и API-ключ не нужны.

В установленной версии MCP **1.2.2** часть CLI-команд выключена по умолчанию. Поэтому конфигурация явно включает форматирование, тесты, исправления и управление запуском приложения:

```text
dart mcp-server --enable=dart_format,run_tests,dart_fix,launch_app,list_devices,stop_app
```

Анализатор, LSP, инспектор виджетов, hot reload/restart и другие стандартные инструменты также доступны. Наличие инструмента не означает разрешения менять несвязанные файлы или запускать внешние эффекты.

Проверка конфигурации из корня доверенного проекта:

```bash
codex mcp get dart_flutter --json
dart mcp-server --version
```

Codex должен загрузить проектную конфигурацию при следующем запуске сессии; если сервер не появился, перезапустите сессию в этом проекте. Конфигурация не меняет глобальные MCP, модель, sandbox или правила подтверждения. Подробности — в [документации Codex MCP](https://learn.chatgpt.com/docs/extend/mcp?surface=cli) и [официальном описании Flutter AI tools](https://docs.flutter.dev/ai/tools).

Для runtime-инспекции сначала запустите фактическое Flutter-приложение в debug/profile и получите его DTD URI; для запущенного агентом процесса используйте `flutter run --print-dtd`. До создания приложения в этом репозитории проверять его runtime нечего.

## Проверено на текущей машине

Проверка выполнена **24 ноября 2026** на macOS arm64:

- `flutter` и `dart` запускаются из постоянной установки с ожидаемыми версиями.
- Codex читает проектную конфигурацию `dart_flutter` как включённый STDIO MCP.
- Через настоящий MCP обмен выполнены `initialize`, `tools/list`, `analyze_files` и `run_tests`: анализ без ошибок, стандартный widget-тест прошёл.
- Выполнена release web-сборка стандартного Flutter-приложения, включая успешную Wasm dry run.
- Проверочный Flutter-проект создан во временном каталоге вне репозитория. Это проверка SDK и MCP; код приложения analyses-app ещё не создан.

## Однократное завершение настройки native-платформ

`flutter doctor` обнаружил требования, оставшиеся от существующего системного окружения:

1. **Android:** часть лицензий SDK не принята. Откройте и примите необходимые соглашения интерактивно:

   ```bash
   flutter doctor --android-licenses
   ```

2. **iOS/macOS:** Xcode **27.2** установлен, но система выбирает Command Line Tools; лицензия Xcode не принята и first-launch компоненты не настроены. Выполните в своём терминале:

   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -license
   sudo xcodebuild -runFirstLaunch
   ```

   Эти операции требуют системного пароля администратора. Не передавайте пароль агенту или в чат. Попытка переключения без интерактивного пароля завершилась `sudo: a password is required`.

3. Повторите `flutter doctor -v`. Проверка CocoaPods с полным Xcode тоже ожидает принятой лицензии: текущая ошибка `pod --version` с `DEVELOPER_DIR` вызвана именно этим условием, а не подтверждённой несовместимостью Ruby.

До выполнения этих шагов web-разработка и SDK/MCP доступны, готовность native-сборок не подтверждена. Сборки Linux и Windows проверяются на соответствующих хостах.

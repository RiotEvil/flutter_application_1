# Detailing Pro — Claude Code Instructions

## Обязательные правила

### Git: коммит и пуш после каждого изменения
После ЛЮБЫХ изменений в коде — сразу коммитить и пушить на GitHub:
```
git add -A
git commit -m "..."
git push
```
Не спрашивать подтверждения, делать автоматически после каждой сессии изменений.

### Flutter release build
ВСЕГДА собирать с ключами RevenueCat:
```
flutter build appbundle --release --dart-define-from-file=build_config.env
```
Без `--dart-define-from-file=build_config.env` подписки не работают (RevenueCat отключён).

## Стек
- Flutter 3.x / Dart, Firebase, RevenueCat, Hive (AES-256)
- Cloud Functions: Node.js, europe-west3
- 10 языков: en, pl, ru, uk, de, es, it, pt, tr, zh

## Структура
- `lib/core/` — сервисы и утилиты
- `lib/screens/` — экраны
- `lib/models/` — модели данных
- `functions/index.js` — Cloud Functions (~3100 строк)
- `build_config.env` — ключи сборки (в .gitignore, не коммитить)

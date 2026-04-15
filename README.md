# Stilp v1 (Flutter skeleton)

Initial Flutter app skeleton aligned to locked v1 scope:

- app shell
- local-first project store abstraction
- base navigation for locked screen flow
- empty screens for:
  - Projektliste
  - Ny opgave
  - Planvisning
  - Facadeeditor
  - Manuel pakkeliste
  - Eksport-preview

## Scope guardrails

This skeleton intentionally does **not** include:

- automatic BOM
- manufacturer catalogs
- backend APIs
- sync/auth
- pricing logic
- technical validation engines

## Structure

```txt
lib/src/app/                    App shell and navigation
lib/src/core/models/            Minimal local model(s)
lib/src/core/storage/           Local-first storage abstraction
lib/src/features/*              Screen modules for locked v1 flow
```

## Run

```bash
flutter pub get
flutter run
```

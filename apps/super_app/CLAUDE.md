# super_app (shell)

Flutter super-app shell. Runs on iOS and Android. This is the host that
loads mini-apps — individual verticals live in `packages/mini_apps/*` and
plug in through the `MiniApp` contract defined in `packages/mini_app_sdk`
(wired up in later migration steps).

## Scope

This app owns:

- The **launcher** (home grid of mini-apps)
- Global navigation shell (bottom nav, routing aggregation)
- Auth / session bootstrap — shared session for every mini-app
- Wiring of platform services into `MiniAppContext` for each mini-app
- Deep link dispatch, push-notification routing, in-app updates

Domain flows (ride, food, payments, etc.) do NOT live here — they live in
their own `packages/mini_apps/<name>` package.

## Architecture

Thin shell:

```
lib/
├── main.dart
├── app.dart                      // MaterialApp.router, ProviderScope
├── router/
│   └── app_router.dart           // go_router config
├── home/
│   └── launcher_screen.dart      // mini-app grid
├── shell/                        // (upcoming) bottom-nav scaffold
└── bootstrap/                    // (upcoming) DI + MiniAppContext factory
```

## Key Dependencies

- `flutter_riverpod` + `riverpod_generator` — state
- `go_router` — routing
- `package:core/core.dart`
- `package:shared_models/shared_models.dart`
- `package:shared_services/shared_services.dart` (to be split into
  `auth`, `networking`, `storage`, … in later steps)
- `package:shared_ui/shared_ui.dart`

## Specific Rules for the Shell

- Shell NEVER imports a mini-app package directly. Mini-apps are discovered
  through the registry once `mini_app_sdk` + `mini_app_registry` land.
- Shell NEVER owns domain state (rides, orders, wallet). It owns only
  cross-cutting state: session, theme, navigation.
- Platform service packages are wired here and handed to mini-apps via
  `MiniAppContext` — not via global singletons or direct imports.

## What This App Should NOT Contain

- ❌ Vertical-specific flows (taxi booking, food menus, etc.) → mini-app
- ❌ Reusable widgets that another app might want → promote to `shared_ui`
- ❌ HTTP calls outside of the `networking` platform package

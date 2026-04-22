# `tool/`

Pure Dart repo-level utilities. Nothing here depends on Flutter; everything
runs with `dart run`.

## `check_mini_app_imports.dart`

Enforces the mini-app import graph described in `CLAUDE.md` and
`ARCHITECTURE.md`. A mini-app (`packages/mini_apps/<name>/`) is only allowed to
depend on:

- `core`, `shared_models`, `shared_ui`, `mini_app_sdk`
- Flutter and neutral third-party libraries (`meta`, `freezed_annotation`,
  `intl`, etc.)

It MUST NOT depend on any platform-service package (`auth`, `networking`,
`payments`, `storage`, `analytics`, `feature_flags`, `notifications`,
`deep_links`, `permissions`, `event_bus`, `mini_app_registry`) or on vendor
SDKs that belong behind a service (`dio`, `flutter_secure_storage`,
`permission_handler`, `geolocator`, ...).

### Run

```bash
dart run tool/check_mini_app_imports.dart
# or via Melos:
melos run check:imports
```

Exit codes:

- `0` — clean.
- `1` — at least one violation was reported.
- `2` — configuration problem (e.g. `packages/mini_apps/` is missing).

### Example output (clean)

```
✓ Mini-app import graph clean (1 mini-app(s) checked: demo_mini_app)
```

### Example output (violation)

```
[ERROR] packages/mini_apps/demo_mini_app/lib/src/presentation/home.dart:12
  imports 'package:auth/...' which is a platform-service package and is not
  allowed in mini-apps.
  Allowed internal deps: core, shared_models, shared_ui, mini_app_sdk.
  Access platform services through MiniAppContext instead.
```

### What is checked

1. **`pubspec.yaml`** — each entry under `dependencies:` must be either in
   the allow-list, Flutter, or a neutral third-party.
2. **Every `*.dart` under `lib/`** (except generated files) — `package:<x>/`
   imports are matched against the same rules.

### Tests

The `analyzeMiniApps(String rootDir)` public function is covered by
`test/tool/check_mini_app_imports_test.dart`, which constructs synthetic
mini-apps in a temporary directory and asserts green/red outcomes.

Run just this test:

```bash
dart test test/tool/check_mini_app_imports_test.dart
```

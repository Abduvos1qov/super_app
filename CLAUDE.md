# Super-App Platform Monorepo

## Project Overview

Flutter monorepo for a **general-purpose super-app platform**. A thin shell hosts multiple independently-developed **mini-apps** (verticals such as food delivery, wallet, shipments, etc.) that communicate with the host through a single, well-typed contract. Architecture is inspired by the WeChat / Gojek / Grab model: one container, many pluggable experiences.

The repository is managed with **Dart Workspaces** (native, Dart 3.6+) for dependency resolution and **Melos** for workflow orchestration.

## Apps

- `apps/super_app` — the shell (iOS + Android). Owns bootstrapping, the mini-app registry, routing, auth session, and global chrome (tabs, search, notifications center).

Legacy app folders may exist on disk during migration but are not part of the shipped product.

## Packages

### Foundation
- `packages/core` — pure Dart primitives: `Result<T, AppError>`, `AppError`, `Money`, `Currency`, validators, `AppLogger`, config types, l10n keys. No Flutter.
- `packages/shared_models` — cross-domain immutable models (`User`, `Session`, `Address`, `Money`, `Notification`, etc.) via freezed + json_serializable.
- `packages/shared_ui` — design system: `AppTheme`, `AppSpacing`, `AppColors`, `AppRadii`, primitive/composite widgets. Zero I/O, zero state.

### Mini-App Platform
- `packages/mini_app_sdk` — **the contract** between the shell and mini-apps. Defines `MiniApp`, `MiniAppManifest`, `MiniAppContext`, `MiniAppVisibility`, and the abstract interfaces every platform service must satisfy (see `ARCHITECTURE.md` §5).
- `packages/mini_app_registry` — discovers, gates (visibility/feature flags), and exposes the list of installed mini-apps to the shell.

### Platform Services (implement `mini_app_sdk` interfaces)
- `packages/auth` — session lifecycle, token storage, refresh (implements `SessionController`).
- `packages/networking` — dio wrapper with interceptors (implements `NetworkGateway`).
- `packages/storage` — scoped key-value + secure storage (implements `StorageScope`).
- `packages/analytics` — fan-out tracker (implements `AnalyticsTracker`).
- `packages/feature_flags` — remote + local flag resolution (implements `FeatureFlagService`).
- `packages/payments` — payment orchestration (implements `PaymentGateway`).
- `packages/notifications` — push + in-app routing (implements `NotificationRouter`).
- `packages/deep_links` — URI parsing + dispatch (implements `DeepLinkDispatcher`).
- `packages/permissions` — runtime permission prompts (implements `PermissionBroker`).
- `packages/event_bus` — cross-mini-app pub/sub (implements `AppEventBus`).

### Mini-Apps (reference + product verticals)
- `packages/mini_apps/demo_mini_app` — reference implementation. Copy this when starting a new vertical.
- Additional vertical mini-apps live under `packages/mini_apps/<name>/`.

## Architecture

For the dependency graph, platform-service interfaces, mini-app lifecycle, routing, and error handling: @ARCHITECTURE.md

## Tech Stack

- Flutter **3.27+**, Dart **3.6+** (workspace support required)
- State management: **Riverpod** (`flutter_riverpod`, `riverpod_generator`)
- Routing: **go_router** (shell routes + per-mini-app sub-routes)
- HTTP: **dio** (only inside `packages/networking`)
- Serialization: **freezed** + **json_serializable**
- Logging: **logger** package wrapped by `AppLogger`
- Testing: **flutter_test** + **mocktail** + golden tests via `alchemist`
- Lints: **very_good_analysis**
- Monorepo: **melos** + **Dart Workspaces**

## Architecture Rules (NON-NEGOTIABLE)

These rules prevent the platform from rotting as verticals multiply. Never violate them without explicit approval.

1. **Shell and mini-app communicate only through `mini_app_sdk`.** A mini-app never imports a platform service package directly; it receives a `MiniAppContext` holding the interfaces it needs.
2. **Mini-app package dependencies are strictly limited** to: `core`, `shared_models`, `shared_ui`, `mini_app_sdk`. Importing `packages/networking`, `packages/auth`, `packages/payments`, etc. from a mini-app is **forbidden**.
3. **Platform service packages implement abstract interfaces** declared in `mini_app_sdk`. The implementation is injected at shell bootstrap time.
4. **Every mini-app is self-contained** with `data/`, `domain/`, `application/`, `presentation/` layers. No cross-mini-app imports.
5. **`shared_ui` is dumb**: zero network, zero storage, zero business logic, zero provider reads. UI primitives only.
6. **`core` is pure Dart**: no Flutter imports, no `dart:io`, no platform channels.
7. **No god packages**: prefer granular (`auth`, `networking`, `storage`) over dumping grounds like `common` or `utils`.
8. **Every package declares `resolution: workspace`** in its `pubspec.yaml`.
9. **No hardcoded strings in UI** — use `core/lib/l10n/` keys or ARB.
10. **No magic numbers or colors** in widgets — use `AppSpacing`, `AppColors`, `AppRadii` from `shared_ui`.
11. **Generated files** (`*.g.dart`, `*.freezed.dart`) are `.gitignore`d and regenerated via `melos run gen`.

## Commands

Always use these from the repo root. Do not invent alternatives.

| Task | Command |
|------|---------|
| Install all dependencies | `flutter pub get` (workspaces resolve the rest) |
| Bootstrap Melos scripts | `melos bootstrap` |
| Run all tests | `melos run test` |
| Test a specific package | `melos exec --scope="<name>" -- flutter test` |
| Static analysis everywhere | `melos run analyze` |
| Format everything | `melos run format` |
| Run code generation | `melos run gen` |
| Watch codegen | `melos run gen:watch` |
| Run the shell app (debug) | `cd apps/super_app && flutter run` |
| Clean everything | `melos run clean` |

Before any commit: `melos run analyze && melos run test`.

## Coding Conventions

- 2-space indentation, trailing commas on multi-arg constructors.
- File names: `snake_case.dart`. Class names: `PascalCase`. Private members prefixed with `_`.
- `final` for every local that isn't reassigned. `const` constructors wherever Flutter allows.
- Named parameters once a widget or function has 2+ args.
- Import order: `dart:*`, `package:flutter/*`, `package:*`, `package:<this_package>/*`, relative. Blank lines between groups.
- Expression bodies (`=>`) only for single-return one-liners.
- Generated files MUST NOT be hand-edited or committed.

Dart-specific rules: @.claude/rules/dart-conventions.md
Testing rules: @.claude/rules/testing.md
UI layer rules (scoped to `packages/shared_ui/`): @.claude/rules/ui-rules.md

## Git Workflow

- **Branch naming**: `feat/<scope>/<slug>`, `fix/<scope>/<slug>`, `chore/<slug>`. `<scope>` is usually the package or mini-app name.
- **Conventional Commits** — Melos parses these for automatic versioning per package.
  - `feat(mini_apps/demo_mini_app): add entry tile` → minor bump
  - `fix(networking): retry 5xx with backoff` → patch bump
  - `feat(mini_app_sdk)!: rename MiniApp.build to MiniApp.buildRoot` → major (breaking)
  - `chore: bump dio to 5.5.0`
- Keep commits atomic. Cross-package refactors are fine and encouraged when they belong to one logical change.
- Never commit secrets, `.env` files, or `CLAUDE.local.md`.

## How to Add a New Mini-App

1. Copy `packages/mini_apps/demo_mini_app/` to `packages/mini_apps/<your_mini_app>/`.
2. Update its `pubspec.yaml`: new package name, keep `resolution: workspace`, keep dependencies limited to `core`, `shared_models`, `shared_ui`, `mini_app_sdk`.
3. Register the new path in the root `pubspec.yaml` under `workspace:`.
4. Implement `MiniApp` — return a `MiniAppManifest` (id, title, icon, entry route, visibility) and build your root widget from the `MiniAppContext` you receive.
5. Register the mini-app in `apps/super_app/lib/bootstrap/mini_app_registry_provider.dart`.
6. From repo root: `flutter pub get && melos run gen && melos run analyze && melos run test`.
7. Add a `CLAUDE.md` to the new mini-app describing its domain, feature flags, and key contracts.

## How to Add a New Platform Service

1. If the capability is new, add an abstract interface to `packages/mini_app_sdk/lib/src/services/` (e.g. `MapsGateway`).
2. Create `packages/<service_name>/` with `resolution: workspace`. Dependencies: `core`, `shared_models`, `mini_app_sdk` (plus one vendor SDK if unavoidable).
3. Implement the interface. Keep vendor-specific code isolated behind the abstraction.
4. Register the Riverpod provider in `apps/super_app/lib/bootstrap/` and override it in `ProviderScope` at app start.
5. Thread the new interface into `MiniAppContext` (in `mini_app_sdk`) so mini-apps can opt into it.
6. Write contract tests in the service package and an `InMemory<Service>` fake in `mini_app_sdk` for mini-app tests.

## Common Mistakes to Avoid

- Importing a platform service package (`packages/networking`, `packages/auth`, ...) from a mini-app — **always** go through `MiniAppContext`.
- `import 'package:shared_ui/...'` inside `packages/core/` — `shared_ui` is Flutter, `core` is pure Dart.
- `Navigator.of(context).push(...)` anywhere — use `context.push()` / `context.go()` on the shared router, or `context.navigation.openMiniApp(...)` from inside a mini-app.
- Adding `dio`, `http`, or `shared_preferences` to `shared_ui`'s `pubspec.yaml`.
- Business logic inside widgets — extract to a Riverpod notifier in the mini-app's `application/` layer, or a pure function in `core`.
- Forgetting `resolution: workspace` in a new package's `pubspec.yaml` (causes resolution failures).
- Publishing any package to pub.dev — all packages are private and internal.
- Coupling two mini-apps by import. If they must share something, promote it to `shared_models` / `core`, or use `AppEventBus`.

## When Uncertain

- Read the relevant package's local `CLAUDE.md` (e.g. `packages/mini_app_sdk/CLAUDE.md`, `packages/shared_ui/CLAUDE.md`).
- Read `ARCHITECTURE.md` for the big picture and platform-service surface.
- Ask before introducing a new third-party dependency.
- Ask before creating a new top-level package or adding an interface to `mini_app_sdk`.

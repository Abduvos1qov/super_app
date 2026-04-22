# Architecture

This document describes the architecture of the super-app platform monorepo in depth. It is referenced from `CLAUDE.md` via `@ARCHITECTURE.md` and loaded lazily by Claude Code when relevant.

## 1. High-Level System

One shell hosts many mini-apps. The shell boots platform services, publishes them through `MiniAppContext`, and lets the `mini_app_registry` render the set of enabled mini-apps. Mini-apps never see each other and never see concrete service implementations.

```
                     ┌──────────────────────────┐
                     │     apps/super_app       │
                     │  (shell: bootstrap,      │
                     │   router, chrome, tabs)  │
                     └────────────┬─────────────┘
                                  │ registers + mounts
                                  ▼
                     ┌──────────────────────────┐
                     │   mini_app_registry      │
                     │  (discovery + gating)    │
                     └────────────┬─────────────┘
                                  │ builds with
                                  ▼
┌─────────────┐  ┌─────────────────────────────────────┐  ┌──────────────┐
│ demo_mini_  │  │    mini_apps/<vertical>             │  │ food, wallet │
│ app (ref)   │  │    (food, wallet, shipments, ...)   │  │ shipments... │
└─────────────┘  └────────────────┬────────────────────┘  └──────────────┘
                                  │ reads capabilities from
                                  ▼
                     ┌──────────────────────────┐
                     │   MiniAppContext         │
                     │ (from mini_app_sdk)      │
                     └────────────┬─────────────┘
                                  │ exposes interfaces implemented by
          ┌───────────────────────┼───────────────────────┐
          ▼                       ▼                       ▼
  ┌───────────────┐      ┌───────────────┐      ┌───────────────┐
  │ auth,         │      │ payments,     │      │ analytics,    │
  │ networking,   │      │ notifications,│      │ feature_flags,│
  │ storage       │      │ deep_links    │      │ event_bus,    │
  │               │      │ permissions   │      │               │
  └───────┬───────┘      └───────┬───────┘      └───────┬───────┘
          └──────────────────────┴──────────────────────┘
                                 │
                                 ▼
                    ┌──────────────────────┐
                    │ core + shared_models │
                    │ + shared_ui          │
                    └──────────────────────┘
```

## 2. Dependency Graph (strict rules)

| Package | Depends on (internal) | May use (external) |
|---|---|---|
| `core` | nothing | pure Dart only (no Flutter) |
| `shared_models` | `core` | freezed, json_annotation |
| `shared_ui` | `core` | flutter, google_fonts, flutter_svg |
| `mini_app_sdk` | `core`, `shared_models` | meta, flutter (widget types only) |
| `mini_app_registry` | `core`, `shared_models`, `mini_app_sdk` | flutter_riverpod |
| `auth` | `core`, `shared_models`, `mini_app_sdk` | flutter_secure_storage |
| `networking` | `core`, `shared_models`, `mini_app_sdk` | dio |
| `storage` | `core`, `mini_app_sdk` | shared_preferences, flutter_secure_storage |
| `analytics` | `core`, `shared_models`, `mini_app_sdk` | (vendor SDKs as vendor adapters) |
| `feature_flags` | `core`, `mini_app_sdk` | (remote config vendor SDK) |
| `payments` | `core`, `shared_models`, `mini_app_sdk` | (PSP SDKs) |
| `notifications` | `core`, `shared_models`, `mini_app_sdk` | firebase_messaging |
| `deep_links` | `core`, `shared_models`, `mini_app_sdk` | uni_links |
| `permissions` | `core`, `mini_app_sdk` | permission_handler |
| `event_bus` | `core`, `mini_app_sdk` | — |
| `mini_apps/<name>` | `core`, `shared_models`, `shared_ui`, `mini_app_sdk` | flutter_riverpod, go_router |
| `apps/super_app` | all of the above | flutter_riverpod, go_router, firebase_* |

**Violating this table is a merge-blocking issue.** A lint pass in CI enforces the mini-app rule (a mini-app that imports a platform service package fails the build).

## 3. Package Responsibilities

- **`core`** — pure Dart. `Result<T, AppError>`, sealed `AppError`, `Money` / `Currency`, validators, `AppLogger`, l10n keys, config types. No I/O.
- **`shared_models`** — immutable freezed models shared across domains. `User`, `Session`, `Address`, `Money`, `Notification`, `DeepLink`.
- **`shared_ui`** — design system tokens (`AppTheme`, `AppSpacing`, `AppColors`, `AppRadii`) plus stateless primitives (`AppButton`, `AppTextField`, `AppCard`, `LoadingOverlay`, `EmptyState`, `ErrorView`).
- **`mini_app_sdk`** — the contract: `MiniApp`, `MiniAppManifest`, `MiniAppContext`, `MiniAppVisibility`, and abstract platform-service interfaces (§5).
- **`mini_app_registry`** — holds registered `MiniApp` instances; filters by visibility / feature flag; exposes a Riverpod provider of the active list.
- **`auth`** — `SessionController` implementation: sign-in, refresh, logout, session stream.
- **`networking`** — `NetworkGateway` implementation: typed request builder over dio, auth interceptor, retry, logging.
- **`storage`** — `StorageScope` implementation: per-mini-app namespaced key-value and secure storage.
- **`analytics`** — `AnalyticsTracker` implementation: fan-out to one or more vendor adapters.
- **`feature_flags`** — `FeatureFlagService` implementation: local overrides + remote source, with a `Composite` pattern.
- **`payments`** — `PaymentGateway` implementation: initiate, confirm, refund. PSP-agnostic.
- **`notifications`** — `NotificationRouter` implementation: register for push, route incoming notifications to the correct mini-app via deep link.
- **`deep_links`** — `DeepLinkDispatcher` implementation: parse URI → resolve mini-app + route → dispatch.
- **`permissions`** — `PermissionBroker` implementation: request/status for platform permissions (camera, location, ...).
- **`event_bus`** — `AppEventBus` implementation: typed pub/sub for cross-mini-app signalling.
- **`mini_apps/demo_mini_app`** — reference vertical. Illustrates the full layer split (`data/`, `domain/`, `application/`, `presentation/`) and every `MiniAppContext` interface.

## 4. Mini-App Contract

Every mini-app implements a single interface from `mini_app_sdk`:

```dart
// packages/mini_app_sdk/lib/src/mini_app.dart
import 'package:flutter/widgets.dart';

import 'package:mini_app_sdk/src/mini_app_context.dart';
import 'package:mini_app_sdk/src/mini_app_manifest.dart';

abstract class MiniApp {
  const MiniApp();

  MiniAppManifest get manifest;

  /// Builds the root widget for this mini-app. The [context] exposes every
  /// platform capability the mini-app is allowed to use.
  Widget buildRoot(MiniAppContext context);
}
```

A manifest declares identity, entry route, icon, and visibility:

```dart
// packages/mini_app_sdk/lib/src/mini_app_manifest.dart
class MiniAppManifest {
  const MiniAppManifest({
    required this.id,
    required this.title,
    required this.icon,
    required this.entryRoute,
    required this.visibility,
    this.minShellVersion,
  });

  final String id;                 // 'demo', 'food', 'wallet'
  final String title;              // localization key, not raw text
  final String icon;               // asset key resolved by shared_ui
  final String entryRoute;         // '/m/demo', '/m/food'
  final MiniAppVisibility visibility;
  final String? minShellVersion;   // semver gate
}
```

Visibility is a sealed hierarchy — the registry uses it to decide whether to surface the mini-app:

```dart
// packages/mini_app_sdk/lib/src/mini_app_visibility.dart
sealed class MiniAppVisibility {
  const MiniAppVisibility();
}
class AlwaysVisible extends MiniAppVisibility {
  const AlwaysVisible();
}
class RequiresAuth extends MiniAppVisibility {
  const RequiresAuth();
}
class FeatureFlagGated extends MiniAppVisibility {
  const FeatureFlagGated(this.flagKey);
  final String flagKey;
}
class RoleGated extends MiniAppVisibility {
  const RoleGated(this.roles);
  final Set<String> roles;
}
```

The `MiniAppContext` is how a mini-app reaches the platform. It holds only the interfaces the mini-app has been granted:

```dart
// packages/mini_app_sdk/lib/src/mini_app_context.dart
class MiniAppContext {
  const MiniAppContext({
    required this.session,
    required this.network,
    required this.storage,
    required this.analytics,
    required this.featureFlags,
    required this.events,
    required this.navigation,
    this.payments,
    this.notifications,
    this.deepLinks,
    this.permissions,
  });

  final SessionController session;
  final NetworkGateway network;
  final StorageScope storage;        // pre-scoped to this mini-app's id
  final AnalyticsTracker analytics;
  final FeatureFlagService featureFlags;
  final AppEventBus events;
  final NavigationGateway navigation;

  final PaymentGateway? payments;
  final NotificationRouter? notifications;
  final DeepLinkDispatcher? deepLinks;
  final PermissionBroker? permissions;
}
```

Example mini-app implementation:

```dart
// packages/mini_apps/demo_mini_app/lib/src/demo_mini_app.dart
import 'package:flutter/widgets.dart';

import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_ui/shared_ui.dart';

import 'presentation/demo_home_screen.dart';

class DemoMiniApp implements MiniApp {
  const DemoMiniApp();

  @override
  MiniAppManifest get manifest => const MiniAppManifest(
        id: 'demo',
        title: 'miniapp.demo.title',
        icon: 'miniapp.demo.icon',
        entryRoute: '/m/demo',
        visibility: AlwaysVisible(),
      );

  @override
  Widget buildRoot(MiniAppContext context) => DemoHomeScreen(context: context);
}
```

## 5. Platform Service Surface

Every platform capability is an abstract interface in `mini_app_sdk`. Concrete implementations live in their own packages and are injected at bootstrap. Mini-apps depend only on the interface.

| Interface | Purpose | Implemented by |
|---|---|---|
| `SessionController` | Current session stream, sign-in, sign-out, token refresh. | `packages/auth` |
| `NetworkGateway` | Typed request/response over HTTP with interceptors; returns `Result`. | `packages/networking` |
| `PaymentGateway` | Initiate / confirm / refund a payment; returns a typed outcome. | `packages/payments` |
| `NotificationRouter` | Register device, receive pushes, dispatch to correct mini-app. | `packages/notifications` |
| `AnalyticsTracker` | `trackEvent`, `setUserProperty`, `timeOp` — fan-out to adapters. | `packages/analytics` |
| `FeatureFlagService` | `isOn(key)`, `valueOf<T>(key)`, change stream. | `packages/feature_flags` |
| `AppEventBus` | Typed pub/sub (`emit`, `on<T>()`) for cross-mini-app signals. | `packages/event_bus` |
| `DeepLinkDispatcher` | Parse incoming URI, resolve to mini-app + route, dispatch. | `packages/deep_links` |
| `PermissionBroker` | Check / request runtime permissions (camera, location, etc.). | `packages/permissions` |
| `StorageScope` | Namespaced key-value + secure storage, pre-scoped per mini-app. | `packages/storage` |
| `NavigationGateway` | `openMiniApp`, `push`, `go`, `pop` — abstraction over go_router. | `apps/super_app` (thin adapter) |

Every interface ships with an `InMemory<Interface>` fake in `mini_app_sdk/lib/src/testing/` so mini-app tests can run without spinning up the full shell.

## 6. State Management

**Riverpod** with code generation (`@riverpod`). Per-mini-app layout:

```
packages/mini_apps/demo_mini_app/lib/src/
├── data/
│   └── demo_repository.dart        // wraps NetworkGateway / StorageScope
├── domain/
│   └── demo_item.dart              // feature-local freezed models
├── application/
│   ├── demo_notifier.dart          // @riverpod AsyncNotifier
│   └── demo_state.dart             // freezed state
└── presentation/
    ├── demo_home_screen.dart
    └── widgets/
```

Rules:
- Providers live next to the feature, not in a global `providers/` folder.
- Platform capabilities are reached via `MiniAppContext`, never imported directly as packages.
- `AsyncNotifier` for loading/error states; widgets render `AsyncValue.when(...)`.
- Side effects via `ref.listen` (snackbars, navigation). Never in `build()`.
- Streams via `StreamProvider`, not a manual `StreamSubscription` in widgets.

## 7. Routing

A single `AppRouter` (go_router) is defined in `apps/super_app/lib/router/app_router.dart`. It owns:

- Shell routes for the host chrome (tabs, home, search, notifications).
- A single sub-tree for mini-apps under `/m/<miniAppId>/*`. Each mini-app owns everything below its prefix and registers its sub-routes through `MiniApp.buildRoot` / the registry.
- Auth redirect logic (one place, not scattered in widgets).
- Deep-link entry points wired to `DeepLinkDispatcher`.

Mini-apps never call `Navigator.of(context).push(...)`. They call `context.navigation.openMiniApp('wallet', subRoute: '/top-up')` or `context.push(...)` scoped to their sub-tree.

## 8. Error Handling

- Services return `Result<T, AppError>` (sealed, in `core`). They do not throw.
- `AppError` variants: `NetworkError`, `AuthError`, `ValidationError`, `ServerError`, `CancelledError`, `UnknownError`.
- Mini-apps handle errors explicitly via pattern matching:

```dart
switch (await context.network.get<CartDto>('/cart')) {
  case Ok(value: final cart):
    state = state.copyWith(cart: cart);
  case Err(error: final NetworkError error):
    state = state.copyWith(failure: error);
  case Err(error: final AppError error):
    logger.warning('Unexpected', error);
}
```

- Widgets read `AsyncValue` and render `ErrorView` from `shared_ui`. Bare `catch (_)` is forbidden.
- Fatal errors are reported via `AnalyticsTracker.reportError` which fans out to the configured crash-reporting adapter.

## 9. Testing

| Layer | Target coverage | Style |
|---|---|---|
| `core`, `shared_models` | 80%+ | pure unit tests |
| Platform services | 80%+ | unit + interface contract tests |
| `mini_app_sdk` | 80%+ | contract tests; every `InMemory*` fake is verified |
| `mini_apps/*` | 70%+ | notifier unit tests + screen smoke tests |
| `shared_ui` | golden-first | `alchemist` goldens for light + dark + edge |
| `apps/super_app` | 60%+ | integration tests for boot, routing, auth |

Every mini-app test constructs a `MiniAppContext` from `InMemorySessionController`, `InMemoryNetworkGateway`, etc. — no real network, no real storage.

Detailed conventions: @.claude/rules/testing.md

## 10. CI/CD

- GitHub Actions with these jobs:
  1. `analyze` — `melos run analyze`
  2. `test` — `melos run test` with coverage
  3. `import-graph-lint` — custom step that fails the build if a mini-app imports a platform service package.
  4. `build` — per-app build matrix using Melos `--diff` (only affected apps).
  5. `release` — on tag, `melos publish` internally and app-store upload via fastlane.
- PR checks must pass before merge.
- `melos version` is used for release cuts; never bump versions manually.

## 11. Feature Flags and Configuration

- Build-time: `--dart-define` for `API_BASE_URL`, `ENV`, `SENTRY_DSN`. Read through `core/lib/config/`.
- Runtime: `FeatureFlagService` exposes `isOn(key)` and a change stream.
- The service uses a **Composite** pattern: a local `StaticFeatureFlagSource` overlays a remote source (e.g. a Remote Config vendor) so developers can force a flag value without a remote push.
- `MiniAppVisibility.FeatureFlagGated('food.enabled')` is the primary gate for rolling out new mini-apps.

## 12. Versioning

- Each package has an independent semver managed by `melos version` from conventional commits.
- A mini-app MAY declare `minShellVersion` in its manifest. The registry refuses to surface a mini-app whose `minShellVersion` is greater than the running shell version.
- Breaking changes in `mini_app_sdk` require a coordinated major bump and migration notes in the package's `CHANGELOG.md`.

## 13. Known Future Work

- **Vendor adapters**: split vendor-specific code into `packages/analytics_firebase`, `packages/payments_<psp>`, `packages/notifications_fcm`, so the core platform packages stay vendor-neutral.
- **Dynamic mini-app installation**: deliver mini-apps as Flutter deferred components or as downloadable bundles, so the shell can ship without all verticals baked in.
- **`packages/design_tokens`**: extract raw tokens (colors, spacing, radii, typography) from `shared_ui` and sync them from Figma.
- **Shared test harness**: extract the `InMemory*` fakes and a `MiniAppContextFixture` builder into `packages/mini_app_sdk/test_harness/` for reuse across all mini-app test suites.
- **gRPC transport**: optional `NetworkGateway` backend for streaming updates once REST becomes a bottleneck.

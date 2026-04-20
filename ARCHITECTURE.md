# Architecture

This document describes the architecture of the ride-hailing monorepo in detail. It is referenced from `CLAUDE.md` via `@ARCHITECTURE.md`. Claude Code loads this lazily when relevant.

## 1. High-Level System

Three client applications share a common backend and a common set of Dart/Flutter packages:

```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  rider_app   │  │  driver_app  │  │  admin_web   │
│  (mobile)    │  │  (mobile)    │  │  (web)       │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                  │                  │
       └──────────────────┴──────────────────┘
                          │
         ┌────────────────┼────────────────┐
         │                │                │
         ▼                ▼                ▼
  ┌───────────┐   ┌──────────────┐  ┌────────────┐
  │ shared_ui │   │shared_services│  │   core     │
  │ (widgets, │   │ (api, auth,  │  │ (pure Dart │
  │  theme)   │   │  storage)    │  │  logic)    │
  └─────┬─────┘   └──────┬───────┘  └──────▲─────┘
        │                │                  │
        └────────────────┼──────────────────┘
                         ▼
                 ┌───────────────┐
                 │ shared_models │
                 │ (User, Trip,  │
                 │  Payment)     │
                 └───────┬───────┘
                         │
                         ▼
                    depends on core
```

## 2. Dependency Graph (strict rules)

| Package | Depends on (internal) | May use (external) |
|---------|----------------------|--------------------|
| `core` | nothing | pure Dart only (no Flutter) |
| `shared_models` | `core` | freezed, json_annotation |
| `shared_services` | `core`, `shared_models` | dio, shared_preferences, geolocator |
| `shared_ui` | `core` | flutter, google_fonts |
| `apps/*` | all four packages | flutter_riverpod, go_router, firebase_* |

**Violation of this table is a merge-blocking issue.**

## 3. Package Responsibilities

### `packages/core`
Pure Dart. No Flutter. No I/O.
- Fare calculation formulas
- Distance/geometry helpers (`Haversine`)
- Phone number validation (Uzbekistan-first)
- Money types and currency formatting (UZS primary)
- Date/time utilities (Asia/Tashkent tz)
- Error types and `Result<T, E>` wrapper
- L10n constants

### `packages/shared_models`
Immutable data classes via freezed.
- `User`, `Rider`, `Driver`, `Admin` (sealed union of actor types)
- `Trip`, `TripStatus` (requested → accepted → enroute → completed → cancelled)
- `Vehicle`, `LicensePlate`
- `Payment`, `Fare`, `Discount`
- `Location`, `Route`, `Waypoint`
- All models JSON-serializable. Codegen via `build_runner`.

### `packages/shared_services`
All I/O lives here. No widgets.
- `ApiClient` — dio instance with auth, retry, logging interceptors
- `AuthService` — login, refresh, logout, token storage
- `TripService` — CRUD for trips, WebSocket updates
- `LocationService` — GPS, background tracking, geocoding
- `StorageService` — secure storage, preferences, cache
- `PushService` — FCM registration, notification handling
- Each service exposes a Riverpod provider for consumers

### `packages/shared_ui`
Design system. Flutter-only. No business logic, no I/O.
- `AppTheme` — single source of truth for colors, typography, spacing, radii
- `AppSpacing` constants: xs=4, sm=8, md=16, lg=24, xl=32, xxl=48
- Primitive widgets: `PrimaryButton`, `SecondaryButton`, `AppTextField`, `AppCard`
- Composite widgets: `LoadingOverlay`, `EmptyState`, `ErrorView`
- `AppIcons` — typed icon constants
- Every public widget needs a golden test + example in `/example`

### `apps/rider_app`
Passenger-facing. Features:
- Onboarding, phone auth
- Request ride, live driver tracking, ETA
- Fare estimate, payment
- Trip history, ratings
- Promo codes

### `apps/driver_app`
Driver-facing. Features:
- Driver onboarding (documents, vehicle registration)
- Online/offline toggle
- Ride acceptance with timeout
- Navigation handoff (external maps)
- Earnings, payouts
- Support chat

### `apps/admin_web`
Operations dashboard (web-only). Features:
- User/driver management, KYC approval
- Trip monitoring, dispute resolution
- Pricing & surge configuration
- Analytics (trips/hour, revenue, cancellation rate)
- Role-based access (ops, finance, admin)

## 4. State Management Strategy

**Riverpod** with code generation (`@riverpod`). Structure per feature:

```
features/ride_request/
├── data/
│   └── ride_request_repository.dart    // thin wrapper over shared_services
├── domain/
│   └── ride_request.dart               // feature-local model if needed
├── application/
│   ├── ride_request_notifier.dart      // @riverpod AsyncNotifier
│   └── ride_request_state.dart         // freezed state class
└── presentation/
    ├── ride_request_screen.dart
    └── widgets/
```

Rules:
- Providers live close to the feature, not in a global `providers/` folder
- Services are injected via providers, never imported directly in widgets
- Use `AsyncNotifier` for anything with loading/error states
- Use `ref.listen` for side effects (snackbars, navigation)

## 5. Routing Strategy

Single `AppRouter` per app using `go_router`. Location: `apps/<app>/lib/router/app_router.dart`.

- Type-safe routes via `go_router_builder`
- Auth redirect logic in the router config, not scattered in widgets
- Deep links configured in native projects (iOS/Android)
- Shell routes for bottom navigation

Never call `Navigator.of(context).push(...)` — always use `context.go(...)` / `context.push(...)` with named routes.

## 6. Error Handling

- Services return `Result<T, AppError>` (sealed class in `core`)
- `AppError` variants: `NetworkError`, `AuthError`, `ValidationError`, `ServerError`, `UnknownError`
- Widgets never catch exceptions; they read `AsyncValue` from providers and render `ErrorView` from `shared_ui`
- Global error reporting via Sentry (configured in each app's `main.dart`)

## 7. Testing Strategy

- **Unit tests**: every function in `core`, every service, every notifier. Target 80%+ coverage.
- **Widget tests**: every screen has at least a smoke test.
- **Golden tests**: every widget in `shared_ui` has goldens for light + dark themes.
- **Integration tests**: critical user flows (book-a-ride, accept-a-ride) via `integration_test`.
- Run everything in CI via `melos run test`.

## 8. CI/CD

- GitHub Actions (or equivalent) with these jobs:
  1. `analyze` — `melos run analyze`
  2. `test` — `melos run test` with coverage
  3. `build` — per-app build matrix (only affected apps, using Melos `--diff`)
  4. `release` — on tag, `melos publish` + app store uploads via fastlane
- PR checks must pass before merge
- `melos version` is used for release cuts; never bump versions manually

## 9. Feature Flags & Configuration

- Environment config via `--dart-define` at build time (`API_BASE_URL`, `ENV`)
- Feature flags at runtime via Firebase Remote Config
- Never hardcode environment URLs — always read from `core/lib/config/`

## 10. Why Not Alternatives

- **Not Bloc** — Riverpod is chosen for conciseness, codegen, and compile-time safety. Consistency matters; don't mix patterns.
- **Not Provider** — superseded by Riverpod in modern Flutter.
- **Not MobX** — not idiomatic in Flutter.
- **Not separate repos** — see `CLAUDE.md` and the article referenced there for the monorepo rationale.
- **Not Bazel** — our scale does not justify the overhead. Dart Workspaces + Melos cover us.

## 11. Known Future Work

- Migrate from REST to gRPC for trip updates (lower latency, streaming)
- Add a `packages/feature_flags` to wrap Remote Config
- Split `shared_services` into `auth`, `networking`, `location` once it exceeds ~15 files
- Introduce a design-tokens package synced from Figma

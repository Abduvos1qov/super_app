# event_bus

Default implementation of the `AppEventBus` contract declared in
`mini_app_sdk`. Enables cross-mini-app choreography: one vertical publishes an
`AppEvent` (e.g. `payment.succeeded`), others subscribe and react.

## Purpose

- Provide the shell with a single, process-wide broadcast bus.
- Keep mini-apps decoupled from the concrete transport: they depend only on
  the `AppEventBus` interface from `mini_app_sdk`.
- Ship a small, test-covered default so teams don't reinvent pub/sub.

## Rules

- Pure Dart logic; no Flutter widgets are imported. The pubspec lists Flutter
  only because workspace packaging expects it.
- Thread-safety is free: Dart is single-threaded per isolate, so a single
  `StreamController.broadcast()` is sufficient.
- Subscribers own their `StreamSubscription` lifecycle — always cancel on
  dispose to avoid leaks.
- Do NOT add vendor SDK integrations (Firebase, Segment, etc.) here. This is
  core infra. Analytics and telemetry belong behind `AnalyticsTracker`.
- Only the shell should construct `StreamAppEventBus` and provide it to
  mini-apps via `MiniAppContext`. Mini-apps must not import this package.

## Structure

```
lib/
├── event_bus.dart               // barrel
└── src/
    └── stream_event_bus.dart    // StreamAppEventBus
test/
└── stream_event_bus_test.dart
```

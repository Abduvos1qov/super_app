# mini_app_sdk

This package defines the contract between the super-app shell and mini-apps.
It is **pure contract** — abstract classes, sealed unions, and value types.
No concrete implementations live here.

## Rules

- NO concrete implementations of any service interface
- NO network calls, no storage, no platform channels
- Depends only on: `core`, `shared_models`, flutter widgets (for `BuildContext` / `Widget`)
- Every service interface returns `Result<T, AppError>` or `Stream<T>` — never throws
- Additions to interfaces are breaking changes: bump version when adding getters

## Structure

```
lib/
├── mini_app_sdk.dart               // barrel
└── src/
    ├── mini_app.dart               // abstract MiniApp base class
    ├── mini_app_route.dart         // lightweight route descriptor
    ├── manifest/
    │   ├── mini_app_manifest.dart
    │   ├── mini_app_category.dart
    │   ├── mini_app_permission.dart
    │   └── mini_app_visibility.dart   // sealed
    ├── context/
    │   └── mini_app_context.dart      // abstract host facade
    ├── events/
    │   └── app_event.dart             // cross-mini-app event base
    └── services/
        ├── session_controller.dart
        ├── network_gateway.dart
        ├── payment_gateway.dart
        ├── notification_router.dart
        ├── analytics_tracker.dart
        ├── feature_flag_service.dart
        ├── app_event_bus.dart
        ├── deep_link_dispatcher.dart
        ├── permission_broker.dart
        ├── storage_scope.dart
        └── navigation_gateway.dart
```

## For mini-app authors

Implement `MiniApp` in your mini-app package. Your package may depend ONLY on
`mini_app_sdk`, `shared_ui`, `shared_models`, `core`. Importing a platform
service package directly (auth, payments, networking) is forbidden.

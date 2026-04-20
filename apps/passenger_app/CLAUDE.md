# Passenger Super App

Flutter mobile super app for passengers. Runs on iOS + Android. This is the
"shell" — individual services (Taxi, Food, Delivery) live in
`packages/feature_*` and plug in through the launcher's route registry.

## Scope

This app owns:

- The **launcher** (home grid of services)
- Shared routing (`go_router`) across all feature modules
- Phone-number + OTP authentication (onboarding) — shared session for every module
- Profile, wallet, trip/order history — cross-module concerns
- Push notifications, deep links, in-app updates

Domain-specific flows do NOT live here — they live in their own `feature_*`
package (e.g. `packages/feature_taxi`). When adding a new service:

1. Create `packages/feature_<name>/` with `<Name>Feature.route`, `.label`, `.buildEntry()`
2. Register the route in `apps/passenger_app/lib/router/app_router.dart`
3. Add a card in `apps/passenger_app/lib/home/launcher_screen.dart`

## Architecture

Thin shell — domain flows live in `packages/feature_*`:

```
lib/
├── main.dart
├── app.dart                      // MaterialApp.router, ProviderScope
├── router/
│   └── app_router.dart           // go_router config + feature routes
├── home/
│   └── launcher_screen.dart      // service grid
└── shared/                       // app-local cross-cutting (auth, session)
    ├── providers/
    └── widgets/
```

Each `packages/feature_*` owns its own `data/`, `application/`, `presentation/` (see ARCHITECTURE.md §4).

## Key Dependencies

- `flutter_riverpod` + `riverpod_generator` — state
- `go_router` — routing
- `google_maps_flutter` — map
- `geolocator` — current location (wrapped by `shared_services`)
- `flutter_polyline_points` — route rendering
- `firebase_messaging` — push notifications
- `url_launcher` — phone dial, external links
- `intl` — localization
- `package:shared_ui/shared_ui.dart`
- `package:shared_services/shared_services.dart`
- `package:shared_models/shared_models.dart`
- `package:core/core.dart`

## Specific Rules for Passenger Super App

- **Location permissions**: always explain why before the system prompt. Use `shared_services`'s `LocationPermissionService` helper.
- **Backgrounding**: when a ride is active, show an ongoing notification and continue tracking. Never stop the location stream mid-ride.
- **Offline handling**: the map must show "No connection" banner when offline. Ride requesting is disabled offline.
- **Deep links**: `uz.myride.passenger://taxi/trip/<id>` opens a specific taxi trip; analogous schemes per feature. Configure in `ios/Runner/Info.plist` and `android/app/src/main/AndroidManifest.xml`.

## Screens That Require Extra Care

- **Ride request screen**: the most used screen. Keep it under 300ms to interactive on cold launch.
- **In-trip screen**: must handle driver cancellations, trip completion, and network drops gracefully.
- **Payment screen**: never store card numbers, CVV, or any PCI data. Use the provider's SDK with tokenization.

## What This App Should NOT Contain

- ❌ Any driver-specific logic (goes in `apps/driver_app`)
- ❌ Admin operations (goes in `apps/admin_web`)
- ❌ Feature-specific flows (taxi booking, food menus, etc.) — those go in `packages/feature_*`
- ❌ Reusable widgets that another app might want — promote to `shared_ui`
- ❌ HTTP calls outside of `shared_services`

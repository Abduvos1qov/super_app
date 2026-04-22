# demo_mini_app

Reference implementation of the `MiniApp` contract defined by
`packages/mini_app_sdk`. This package ships with every super-app release as a
sanity check that the shell wiring (registration, routing, context injection)
works end-to-end.

## Purpose

1. **Template**: copy this package as a starting point when creating a new
   mini-app (food, wallet, delivery, …). The directory layout, dependency
   surface and lifecycle hook usage are the conventions other verticals follow.
2. **Contract smoke test**: if the shell can launch `DemoMiniApp` and its three
   action tiles work, the `MiniAppContext` facade is plumbed correctly.
3. **Demo surface**: product can screenshot it during design reviews without
   touching a production vertical.

## Allowed dependencies

Exactly these four internal packages — nothing else:

- `core`
- `mini_app_sdk`
- `shared_models`
- `shared_ui`

**Forbidden**: `shared_services`, any platform-service package, `dio`, storage
plugins, Riverpod, `go_router`. Every capability is reached through
`MiniAppContext`.

## What this demonstrates

- A `MiniAppManifest` with a `reverse.dns.style` id, category, icon asset and
  default `.always()` visibility.
- `MiniApp.routes` returning a single root route; the shell mounts it under
  the mini-app namespace.
- `MiniApp.buildLauncherTile` rendered on the shell home screen.
- Using `MiniAppContext` from a screen:
  - `context.analytics.track(...)`
  - `context.permissions.request(...)`
  - `context.events.publish(...)`
- Clean Architecture layering (`domain/`, `application/`, `presentation/`) even
  for a trivial feature, so new authors see the shape.

## What this does NOT yet demonstrate

- `context.network` / `context.storage` (no I/O here by design)
- `context.payments` (requires a `Money` flow and a receipt surface)
- Deep links (`context.deepLinks.linksFor(id)`) — covered in a later step
- Lifecycle hooks (`onBootstrap`, `onActivate`) — default no-ops for now

## Coding rules reminder

- No `print` / `debugPrint`
- No `!` null assertion
- All colors and spacing via `AppTheme` extensions from `shared_ui`
- All interactive widgets have a `Semantics` label

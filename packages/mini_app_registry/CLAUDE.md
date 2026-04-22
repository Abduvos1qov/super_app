# mini_app_registry

Holds the compile-time list of `MiniApp`s the shell ships with and filters
them by the visibility rules declared in each manifest.

## Purpose

Two responsibilities, nothing else:

1. **Registry** — immutable collection of `MiniApp` instances, with lookup
   by id.
2. **Visibility filtering** — pure evaluation of `MiniAppVisibility` against
   `SessionState` + `FeatureFlagService` to decide which mini-apps to surface.

## Why separate from `mini_app_sdk`?

`mini_app_sdk` is a **pure contract** package: abstract classes, sealed
unions, value types. Adding logic there would make it non-trivial to evolve
and would force every mini-app to depend on host-side decisions. This
package holds the logic; the SDK holds the shape.

## Usage (shell bootstrap)

```dart
final registry = MiniAppRegistry(const [
  TaxiMiniApp(),
  FoodMiniApp(),
  PaymentsMiniApp(),
]);

// Later, when rendering the launcher or building the router:
final visible = registry.allVisible(
  session: sessionController.current ?? const SessionAnonymous(),
  featureFlags: featureFlagService,
);
```

`allVisible` is a pure function of its inputs — call it again whenever the
session or flag snapshot changes.

## Why compile-time?

The MVP ships one fixed set of mini-apps per build; there is no dynamic
download/install pipeline yet. Keeping the list compile-time lets tree
shaking drop unused code and gives us static guarantees about id uniqueness
at code-review time. When dynamic registries land, this package grows a new
`DynamicMiniAppRegistry` alongside the compile-time one — the SDK contract
will not change.

## Rules

- NO network, NO storage, NO platform channels here.
- Depends only on `core`, `shared_models`, `mini_app_sdk`.
- `VisibilityEvaluator` is a pure function; keep it that way so it remains
  exhaustively unit-testable without the registry.

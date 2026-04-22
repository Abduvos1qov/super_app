# feature_flags

Vendor-agnostic feature flag platform service. Provides default
implementations of the `FeatureFlagService` contract declared in
`mini_app_sdk`, so the shell can compose static defaults, runtime overrides
and remote sources behind a single facade.

## Purpose

- Offer a compile-time `StaticFeatureFlagService` for build-variant defaults.
- Offer an `InMemoryFeatureFlagService` for tests and debug/QA overrides.
- Offer a `CompositeFeatureFlagService` that stacks sources by priority
  (override -> remote -> local -> static) and emits a merged change stream.
- Offer a `TypedFlag<T>` descriptor so callers declare key, fallback and
  decoder in one place and evaluate the flag as `flag.read(service)`.

## Rules

- Never depend on a vendor SDK directly (`firebase_remote_config`,
  `launchdarkly_flutter_client_sdk`, `split`, `unleash`, ...). Each vendor
  integration MUST live in its own adapter package (e.g.
  `feature_flags_firebase`, `feature_flags_launchdarkly`) and be composed at
  the shell layer.
- No Flutter widgets, no navigation, no storage — this package is pure
  orchestration over the interface from `mini_app_sdk`.
- Do NOT modify the `FeatureFlagService` interface in `mini_app_sdk`; any
  new capability (e.g. `has(key)`) must go through the SDK with a version
  bump.
- Flag keys follow `<domain>.<flag_name>` in `snake_case`, e.g.
  `ui.wallet_tab_enabled`, `payments.surge_pricing`.

## Composite priority

`CompositeFeatureFlagService` walks sources in declaration order and picks
the first source that declares the key. Typical shell composition:

```dart
CompositeFeatureFlagService([
  debugOverrides,     // InMemoryFeatureFlagService, highest priority
  remoteConfig,       // vendor adapter (e.g. feature_flags_firebase)
  localCache,         // another in-memory or persisted layer
  staticDefaults,     // StaticFeatureFlagService, lowest priority
]);
```

## Known limitation

`FeatureFlagService` has no `has(key)` method. The composite detects key
ownership via:

- a fast path for `StaticFeatureFlagService` and `InMemoryFeatureFlagService`
  (both expose `has`),
- a sentinel-fallback probe for `boolFlag` and `stringFlag` against every
  other implementation (two calls with distinct fallbacks; equal results
  mean the source owns the key).

`jsonFlag` cannot be probed reliably through the public interface because
the decoder and fallback are caller-supplied. For JSON flags, the composite
resolves against the first source that exposes `has` — so vendor adapters
should either implement `has` through an extension or register JSON flag
defaults in `StaticFeatureFlagService` for safe fallbacks.

## Structure

```
lib/
├── feature_flags.dart                   // barrel
└── src/
    ├── composite_feature_flag_service.dart
    ├── in_memory_feature_flag_service.dart
    ├── static_feature_flag_service.dart
    └── typed_flag.dart
test/
├── composite_feature_flag_service_test.dart
├── in_memory_feature_flag_service_test.dart
├── static_feature_flag_service_test.dart
└── typed_flag_test.dart
```

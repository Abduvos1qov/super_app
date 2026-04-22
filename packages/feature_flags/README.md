# feature_flags

Vendor-agnostic implementations of the `FeatureFlagService` contract from
`mini_app_sdk`.

See `CLAUDE.md` for full rules and composition guidance.

## Quick start

```dart
import 'package:feature_flags/feature_flags.dart';

final defaults = const StaticFeatureFlagService({
  'ui.wallet_tab_enabled': false,
  'payments.max_amount_uzs': 50000000,
});

final overrides = InMemoryFeatureFlagService();

final service = CompositeFeatureFlagService([
  overrides,   // debug/QA overrides (highest priority)
  // remoteConfigAdapter,
  defaults,    // build-variant defaults (lowest priority)
]);

if (service.boolFlag('ui.wallet_tab_enabled')) {
  // render tab
}

overrides.set('ui.wallet_tab_enabled', true); // QA tool
```

## Typed flags

```dart
bool _decodeBool(Object? raw) => raw is bool ? raw : false;

const showWalletTab = TypedFlag<bool>(
  key: 'ui.wallet_tab_enabled',
  fallback: false,
  decode: _decodeBool,
);

if (showWalletTab.read(service)) { /* ... */ }
```

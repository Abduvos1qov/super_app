---
paths:
  - "packages/shared_ui/**/*.dart"
---

# shared_ui Rules

These rules apply only when working inside `packages/shared_ui/`.

## The One Rule

**shared_ui is a pure presentation layer.** Violating this rule is worse than any other violation in this repo, because it corrupts the dependency graph and forces business logic into widgets across every mini-app.

## Forbidden in shared_ui

- ❌ `import 'package:dio/...'` or any HTTP library
- ❌ `import 'package:shared_preferences/...'`, `flutter_secure_storage`, or any storage
- ❌ `import 'package:auth/...'`, `package:networking/...`, `package:payments/...`, or any other platform service package
- ❌ `import 'package:mini_app_sdk/...'` — shared_ui is lower in the graph than the SDK
- ❌ `import 'package:flutter_riverpod/...'` — widgets here must be framework-agnostic
- ❌ Async work, timers, streams
- ❌ Navigation (`Navigator`, `go_router`) — emit callbacks instead
- ❌ Platform channels, `dart:io` (breaks web)

## Allowed

- ✅ `flutter/material.dart`, `flutter/cupertino.dart`
- ✅ `google_fonts`, `flutter_svg`, `cached_network_image`
- ✅ `package:core/core.dart` for formatters, constants, types
- ✅ Animation packages (Lottie, Rive) used purely for visuals

## Widget API Design

- Every public widget takes its data as parameters. No reading from providers.
- Callbacks for user actions: `onPressed`, `onChanged`, `onSubmitted`. Never perform actions internally.
- Loading/error states are passed in, not computed:

```dart
// Good
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({
    required this.total,
    required this.onConfirm,
    this.isLoading = false,
    super.key,
  });

  final Money total;
  final VoidCallback onConfirm;
  final bool isLoading;
  // ...
}

// Bad — widget fetches its own data
class OrderSummaryCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(currentOrderTotalProvider); // ❌
  }
}
```

## Theming

- All colors come from `AppTheme.colors.*`. Never `Color(0xFF...)` in widget code.
- All spacing uses `AppSpacing.md`, `AppSpacing.lg`, etc. Never raw numbers.
- All text styles come from `AppTheme.typography.*`. Never inline `TextStyle(...)`.
- All border radii come from `AppRadii.*`. Never raw `BorderRadius.circular(12)`.
- Dark mode is not optional. Every widget must look correct in both themes.

## Examples & Goldens

- Every public widget has an entry in `example/lib/main.dart` showing common states
- Every public widget has golden tests in `test/goldens/` for light + dark
- Run `flutter test --update-goldens` only for intentional visual changes

## Localization

- Widgets accept already-localized strings as parameters, they do NOT look up translations internally
- Exception: widgets for very-common UI chrome (empty states, error views) may use the localization stream injected from app level

## Accessibility

- Every interactive widget has a `Semantics` label
- Minimum tap target: 48×48 logical pixels
- Text scales with system font size (no hardcoded text scale factor)
- Color contrast meets WCAG AA minimum

## Before Adding a Widget

Ask: is this widget used (or likely to be used) in 2+ mini-apps or in shell chrome? If only one mini-app uses it, it belongs in that mini-app's `presentation/widgets/`, not in `shared_ui`. Moving to `shared_ui` is a deliberate promotion, not a default.

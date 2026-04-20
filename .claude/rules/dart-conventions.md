---
paths:
  - "**/*.dart"
---

# Dart Conventions

These rules apply to every `.dart` file across the monorepo.

## Null Safety & Immutability

- Never use `!` (null assertion) in production code. If you can't prove non-null statically, handle it with `if (x case final y?)` or `switch`.
- Prefer `final` for all locals that aren't reassigned. Prefer `const` constructors wherever Flutter allows.
- Fields in model classes are always `final`. Mutability lives in Riverpod notifiers, not in data.

## Pattern Matching (Dart 3+)

Prefer pattern matching over manual type checks:

```dart
// Good
final result = switch (trip.status) {
  TripStatus.requested => 'Finding driver…',
  TripStatus.enroute => 'Driver on the way',
  TripStatus.completed => 'Trip complete',
  _ => 'Unknown',
};

// Avoid
String getLabel(TripStatus s) {
  if (s == TripStatus.requested) return 'Finding driver…';
  if (s == TripStatus.enroute) return 'Driver on the way';
  // ...
}
```

Use `if-case` for null destructuring:

```dart
if (response.body case final Map<String, dynamic> json) {
  return User.fromJson(json);
}
```

## Import Order

Exactly this order, separated by blank lines:

1. `dart:*`
2. `package:flutter/*`
3. `package:*` (third-party)
4. `package:<this_package>/*` (internal absolute)
5. Relative imports (`./...`, `../...`)

Example:
```dart
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';
import 'package:shared_ui/shared_ui.dart';

import '../widgets/fare_display.dart';
```

## Async

- Use `await` at every async call. Never return a `Future` and hope it completes.
- Wrap async UI operations with `AsyncValue` from Riverpod — don't manage loading booleans manually.
- Stream subscriptions must be cancelled. Prefer `StreamProvider` over manual `StreamSubscription` in widgets.

## Error Handling

- Never `catch (e)` without handling or rethrowing. Bare catches swallow bugs.
- Services return `Result<T, AppError>`, not throw. Throwing is for programmer errors only.
- In widgets, read `AsyncValue` and render `ErrorView` from `shared_ui` on failure.

## Logging

- Use the `logger` package via `AppLogger` in `core`. No `print()`, no `debugPrint()` in non-test code.
- Log levels: `trace`, `debug`, `info`, `warning`, `error`. In release, only `warning` and above.

## Documentation Comments

- Every public API in `packages/` has a `///` dartdoc comment.
- App-internal code does not require docs but benefits from them on non-obvious logic.
- Start doc comments with a full sentence that summarizes what the symbol does, not what it is.

## Generated Code

- Never hand-edit `*.g.dart`, `*.freezed.dart`, `*.gr.dart` files.
- Regenerate via `melos run gen` (which runs `dart run build_runner build --delete-conflicting-outputs`).
- Generated files are `.gitignore`d.

## Avoid These Anti-Patterns

- `dynamic` types in public APIs — always use concrete or generic types
- `late` fields for anything that isn't truly initialized later (DI fields)
- `var` at class-level — use `final` or explicit type
- `context.read` inside `build()` methods — use `ref.watch`
- `setState` in stateful widgets when a Riverpod provider would do the job

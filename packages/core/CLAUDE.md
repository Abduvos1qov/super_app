# core Package

Pure Dart. No Flutter. No I/O. This package is the foundation everything else depends on.

## Purpose

Shared, deterministic, side-effect-free logic used by every app and every other package.

## Contents

```
lib/
├── core.dart                     // public barrel
├── src/
│   ├── config/                   // AppConfig, Environment
│   ├── errors/                   // AppError sealed class, Result<T, E>
│   ├── formatters/               // money, phone, distance, datetime
│   ├── geometry/                 // Haversine, bbox, polyline utils
│   ├── logging/                  // AppLogger wrapper over `logger`
│   ├── money/                    // Money type, UZS formatter
│   ├── pricing/                  // FareCalculator (pure function)
│   ├── time/                     // Tashkent tz helpers
│   └── validators/               // phone, email, license plate (UZ)
```

## Strict Rules

- ❌ NO `package:flutter/...` imports. If you need `BuildContext`, this isn't the right package.
- ❌ NO `dart:io` (breaks web). Use `dart:core` and `dart:async` only.
- ❌ NO HTTP, no file access, no database, no platform channels.
- ❌ NO global state. Everything is a pure function or an immutable value.
- ❌ NO dependencies on other internal packages. `core` is the leaf of the dependency tree.

## Allowed Dependencies

Only tiny, pure-Dart utilities:

- `collection` (from Dart team)
- `meta`
- `decimal` (for money arithmetic)
- `timezone` (tz data)

If you're about to add a new dependency, ask whether it pulls in Flutter or I/O. If yes, it doesn't belong here.

## API Design

- Every public API has a dartdoc comment
- Prefer **named constructors** for variants: `Money.uzs(1000)`, `Money.usd(10)`
- Return `Result<T, AppError>` from anything that could fail, not exceptions
- Freeze classes with `@immutable` (from `meta`), not freezed (freezed adds codegen, `core` stays lean)

## Testing

100% coverage is realistic here because everything is pure. Run:

```
melos exec --scope="core" -- flutter test --coverage
```

Every formatter, validator, and calculator has exhaustive tests including boundary cases and error inputs.

## Example: FareCalculator

```dart
/// Calculates the fare for a given trip in UZS.
///
/// Formula: base + (distanceKm × perKm) + (minutes × perMinute), times surge.
/// Guarantees: result ≥ [FareConfig.minimumFare].
Money calculateFare({
  required double distanceKm,
  required int minutes,
  required double surgeMultiplier,
  required FareConfig config,
}) {
  // Pure. Deterministic. Testable.
}
```

Consumers in apps wrap this in a Riverpod provider; `core` stays Flutter-free.

# core Package

Pure Dart. No Flutter. No I/O. This package is the foundation everything else
depends on. It is **domain-neutral** — nothing here should assume a specific
vertical (ride-hailing, delivery, payments) or a specific locale.

## Purpose

Shared, deterministic, side-effect-free primitives used by every app and every
other package.

## Contents

```
lib/
├── core.dart                     // public barrel
└── src/
    ├── errors/                   // AppError sealed class, Result<T, E>
    ├── logging/                  // AppLogger wrapper over `logger`
    └── money/                    // Currency (ISO-4217), Money value object
```

Planned (not yet landed): `validators/` (general E.164 phone, email),
`formatters/` (distance, datetime), `geometry/` (Haversine, bbox), `time/`
(ISO timezone helpers), `config/` (environment).

## Strict Rules

- NO `package:flutter/...` imports. If you need `BuildContext`, this isn't
  the right package.
- NO `dart:io` (breaks web). Use `dart:core` and `dart:async` only.
- NO HTTP, no file access, no database, no platform channels.
- NO global state. Everything is a pure function or an immutable value.
- NO dependencies on other internal packages. `core` is the leaf of the
  dependency tree.
- NO hardcoded locale, currency, or regional assumption. Callers pass in a
  `Currency`, a `Locale`, or a timezone explicitly.

## Allowed Dependencies

Only tiny, pure-Dart utilities:

- `collection` (from Dart team)
- `meta`
- `decimal` (for money arithmetic)
- `timezone` (tz data, kept for future `time/` helpers)

If you're about to add a new dependency, ask whether it pulls in Flutter or
I/O. If yes, it doesn't belong here.

## API Design

- Every public API has a dartdoc comment.
- Prefer **named constructors** for common variants: `Money.usd(10)`,
  `Money.uzs(12500)`. Keep a generic factory alongside (`Money.of(...)`) so
  callers can mint values for arbitrary currencies.
- Return `Result<T, AppError>` from anything that could fail, not exceptions.
- Freeze classes with `@immutable` (from `meta`), not freezed (freezed adds
  codegen, `core` stays lean).
- Value objects use their business identity for equality — e.g. two
  `Currency` instances with the same ISO code are equal regardless of symbol.

## Testing

100% coverage is realistic here because everything is pure. Run:

```
melos exec --scope="core" -- flutter test --coverage
```

Every formatter, validator, and calculator has exhaustive tests including
boundary cases and error inputs.

## Example: Money across currencies

```dart
import 'package:core/core.dart';

final fee = Money.usd(9.99);                              // 999 minor units
final sum = fee + Money.of(amount: 1, currency: Currency.usd);
print(sum.format());                                       // '10.99 $'

// Non-standard currencies are first-class.
const points = Currency.custom(
  code: 'XPT',
  decimals: 0,
  symbol: 'pts',
);
final reward = Money.of(amount: 1500, currency: points);
print(reward.format());                                    // '1 500 pts'

// Cross-currency arithmetic throws — convert explicitly at call sites.
// fee + reward;  // ArgumentError: Cannot combine USD with XPT
```

Consumers in apps wrap domain-specific logic (pricing, rewards, payouts) in
Riverpod providers; `core` stays Flutter-free and vertical-agnostic.

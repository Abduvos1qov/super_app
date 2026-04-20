# shared_models Package

Domain models used across the entire system. Immutable. JSON-serializable.

## Purpose

Single source of truth for what a `User`, `Trip`, `Driver`, `Vehicle`, `Payment` looks like. When the backend contract changes, this is the only package that needs to change.

## Contents

```
lib/
├── shared_models.dart            // barrel
├── src/
│   ├── actors/                   // User, Rider, Driver, Admin
│   ├── trip/                     // Trip, TripStatus, Waypoint
│   ├── vehicle/                  // Vehicle, VehicleType, LicensePlate
│   ├── payment/                  // Payment, PaymentMethod, Fare
│   ├── location/                 // Location, Route, BoundingBox
│   └── common/                   // pagination envelopes, enums
```

## Rules

- **Every model uses freezed** — `@freezed` class, `factory _.fromJson`
- **Every field is `final`** (freezed enforces this)
- **Every model has exhaustive JSON round-trip tests**: `Model.fromJson(model.toJson())` equals the original
- **Enums use `@JsonEnum(alwaysCreate: true)`** so unknown values decode to a fallback, not throw
- **Actors are a sealed union**:
  ```dart
  @freezed
  sealed class User with _$User {
    const factory User.rider({...}) = Rider;
    const factory User.driver({...}) = Driver;
    const factory User.admin({...}) = Admin;
  }
  ```
- **Dates are `DateTime` in UTC**. Apps convert to Tashkent time for display using `core`'s helpers.
- **Money fields use `Money` from `core`**, never raw `int` or `double`.

## Dependencies

- `freezed_annotation`
- `json_annotation`
- `core` (for `Money`, `Result`, etc.)

Dev dependencies:

- `freezed`
- `json_serializable`
- `build_runner`

## Codegen

After editing any model:

```
melos run gen
```

Never hand-edit `*.freezed.dart` or `*.g.dart`.

## API Evolution

- Adding a new field: make it nullable or provide a `@Default(...)` value
- Removing a field: mark it `@Deprecated(...)` for at least one release before removing
- Renaming: use `@JsonKey(name: 'old_name')` on the new field name to keep JSON stable
- Never change a field's type in a backwards-incompatible way without a major version bump in Melos

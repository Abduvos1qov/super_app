# shared_models Package

Cross-vertical domain models used across the entire super-app shell.
Immutable. JSON-serializable.

## Purpose

Single source of truth for identity and other concepts that every mini-app
shares (User, Address, Money). Feature-specific models — ride trips, food
orders, parcel deliveries, merchant storefronts — live **inside each
mini-app's own package**, not here. When the super-app backend changes a
cross-vertical contract, this is the only package that needs to change.

## Contents

```
lib/
├── shared_models.dart            // barrel
├── src/
│   ├── actors/                   // User, AccountRole, KycLevel
│   └── common/                   // (future) pagination envelopes, enums
```

Other cross-vertical models (Address, Money wrappers if not in `core`) land
under their own folder as they are introduced. Do NOT add vertical-specific
models here — reject that in review and push them into the mini-app package.

## Rules

- **Every model uses freezed** — `@freezed` class, `factory _.fromJson`
- **Every field is `final`** (freezed enforces this)
- **Every model has exhaustive JSON round-trip tests**: `Model.fromJson(model.toJson())` equals the original
- **Enums use `@JsonEnum(alwaysCreate: true)`** and each enum has an
  `unknown` variant. Fields reference it with
  `@JsonKey(unknownEnumValue: MyEnum.unknown)` so unseen backend values decode
  to the fallback instead of throwing.
- **Dates are `DateTime` in UTC**. Apps convert to Tashkent time for display using `core`'s helpers.
- **Money fields use `Money` from `core`**, never raw `int` or `double`.

## Scope (what belongs here vs. a mini-app)

- In: `User`, `AccountRole`, `KycLevel`, `Address`, shared pagination/error
  envelopes, anything more than one mini-app reads.
- Out: anything specific to one vertical. A `RideTrip`, `FoodOrder`,
  `ParcelShipment`, or `MerchantPayout` belongs inside that mini-app's
  package, not here.

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

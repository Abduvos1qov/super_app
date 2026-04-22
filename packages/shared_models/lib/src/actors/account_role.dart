import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_role.g.dart';

/// Super-app account roles. A single `User` may hold multiple roles at once —
/// e.g. a person can be both a [consumer] (orders food, books rides) and an
/// [operator] (drives, delivers, runs a merchant storefront).
///
/// [unknown] exists for forward-compatibility: when the backend introduces a
/// new role the client hasn't shipped yet, decoding falls back here instead of
/// throwing. Consumers MUST pattern-match on [unknown] explicitly.
@JsonEnum(alwaysCreate: true)
enum AccountRole {
  /// End-user buying services inside a mini-app (ride, food, parcel, …).
  consumer,

  /// Mini-app operator: driver, courier, merchant staff, etc. Domain-neutral
  /// label for anyone fulfilling orders on behalf of a mini-app.
  operator,

  /// Internal operations / back-office access to the admin surface.
  admin,

  /// Unrecognised role received from the backend. Always handle defensively.
  unknown,
}

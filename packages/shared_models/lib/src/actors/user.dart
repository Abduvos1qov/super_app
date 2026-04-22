import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:shared_models/src/actors/account_role.dart';
import 'package:shared_models/src/actors/kyc_level.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// Domain-neutral identity used across every mini-app in the super-app.
///
/// The super-app shell owns one [User] object per authenticated session.
/// Mini-apps (ride, food, parcel, …) read it to personalise flows but MUST
/// NOT extend it with vertical-specific fields. Vertical data (ride rating,
/// merchant payout account, …) lives inside each mini-app's own package.
///
/// [roles] is a [Set] because a single person can simultaneously act as a
/// consumer and an operator (e.g. a driver who also orders food).
@freezed
class User with _$User {
  /// Creates a [User] with the given identity fields.
  const factory User({
    required String id,
    required String phone,
    required String displayName,
    String? email,
    String? avatarUrl,
    @Default(<AccountRole>{AccountRole.consumer})
    @JsonKey(unknownEnumValue: AccountRole.unknown)
    Set<AccountRole> roles,
    @Default(KycLevel.none)
    @JsonKey(unknownEnumValue: KycLevel.unknown)
    KycLevel kycLevel,
    @Default(false) bool isActive,
  }) = _User;

  /// Decodes a [User] from its JSON representation.
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

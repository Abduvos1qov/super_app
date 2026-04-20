import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// Admin permission roles. Unknown decodes to [AdminRole.unknown] instead of
/// throwing — the `alwaysCreate` option generates a resilient enum decoder.
@JsonEnum(alwaysCreate: true)
enum AdminRole { ops, finance, superadmin, unknown }

/// Sealed union of every actor type in the system. Apps pattern-match on
/// variants instead of branching on string discriminators.
@Freezed(unionKey: 'type')
sealed class User with _$User {
  const factory User.rider({
    required String id,
    required String phone,
    required String displayName,
    String? avatarUrl,
  }) = Rider;

  const factory User.driver({
    required String id,
    required String phone,
    required String displayName,
    required String licenseNumber,
    @Default(0.0) double rating,
  }) = Driver;

  const factory User.admin({
    required String id,
    required String email,
    @Default(AdminRole.unknown) AdminRole role,
  }) = Admin;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

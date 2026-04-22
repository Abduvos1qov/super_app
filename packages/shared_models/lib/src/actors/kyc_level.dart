import 'package:freezed_annotation/freezed_annotation.dart';

part 'kyc_level.g.dart';

/// Universal KYC ladder for the super-app. Each mini-app decides which level
/// gates which feature (e.g. enhanced required for payouts, verified for
/// high-value rides).
///
/// [unknown] exists for forward-compatibility: unseen backend values decode
/// here instead of throwing.
@JsonEnum(alwaysCreate: true)
enum KycLevel {
  /// No verification performed yet.
  none,

  /// Phone verified via OTP.
  basic,

  /// Government-issued ID scanned and validated.
  verified,

  /// Face-match + address proof completed on top of [verified].
  enhanced,

  /// Unrecognised level received from the backend. Always handle defensively.
  unknown,
}

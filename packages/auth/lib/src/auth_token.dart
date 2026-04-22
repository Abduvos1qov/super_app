import 'package:meta/meta.dart';

/// An immutable bearer-token pair used to authorise super-app requests.
///
/// The [accessToken] is attached to API calls by `AuthInterceptor`; the
/// [refreshToken] is used only by [AuthService.refresh] when the access
/// token is close to (or past) [expiresAt]. The token carries no profile
/// information — user identity is fetched separately via `/me`, which keeps
/// sensitive fields out of persistent storage.
@immutable
class AuthToken {
  /// Creates an [AuthToken]. All three fields are required because a token
  /// without an expiry cannot be refreshed safely.
  const AuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  /// Decodes an [AuthToken] from its JSON representation.
  ///
  /// Throws [FormatException] when [json] is not a JSON object or a field is
  /// missing. Callers persisting tokens via [SecureTokenStorage] see this as
  /// a [ValidationError] rather than an exception.
  factory AuthToken.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('AuthToken JSON must be an object');
    }
    final access = json['accessToken'];
    final refresh = json['refreshToken'];
    final expiresAt = json['expiresAt'];
    if (access is! String || refresh is! String || expiresAt is! String) {
      throw const FormatException('AuthToken JSON is missing required fields');
    }
    return AuthToken(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: DateTime.parse(expiresAt),
    );
  }

  /// The short-lived bearer credential attached to outbound requests.
  final String accessToken;

  /// The long-lived credential exchanged for a new access token when the
  /// current one is close to expiry.
  final String refreshToken;

  /// Absolute expiry timestamp of [accessToken], always stored in UTC when
  /// round-tripped through JSON.
  final DateTime expiresAt;

  /// Returns `true` when the access token has expired, with an optional
  /// [skew] to refresh proactively a little before the hard expiry.
  bool isExpired({DateTime? now, Duration skew = const Duration(seconds: 30)}) {
    final current = now ?? DateTime.now();
    return !current.isBefore(expiresAt.subtract(skew));
  }

  /// Returns the canonical JSON representation persisted to secure storage.
  Map<String, Object?> toJson() => <String, Object?>{
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthToken &&
          other.accessToken == accessToken &&
          other.refreshToken == refreshToken &&
          other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(accessToken, refreshToken, expiresAt);

  @override
  String toString() =>
      'AuthToken(accessToken: <redacted>, refreshToken: <redacted>, '
      'expiresAt: ${expiresAt.toIso8601String()})';
}

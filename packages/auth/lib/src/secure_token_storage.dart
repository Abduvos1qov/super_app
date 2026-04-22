import 'dart:convert';

import 'package:core/core.dart';
import 'package:storage/storage.dart';

import 'package:auth/src/auth_token.dart';

/// Persists the current [AuthToken] to [SecureStorage] under a single
/// well-known key.
///
/// Values are serialised as JSON so we can evolve [AuthToken] over time
/// without changing the storage contract. A decode failure is surfaced as
/// [ValidationError] — which the caller typically treats as a tampering
/// signal: clear the entry and force re-auth.
class SecureTokenStorage {
  /// Wraps the supplied [SecureStorage] backend. In production the shell
  /// injects `FlutterSecureStorageImpl`; tests pass `InMemorySecureStorage`.
  SecureTokenStorage(this._secure);

  final SecureStorage _secure;

  /// The single key under which the token JSON is stored.
  static const String storageKey = 'auth.token';

  /// Reads the persisted token, if any.
  ///
  /// Returns `Ok(null)` when nothing has been stored, `Ok(token)` on a
  /// successful round-trip, and [ValidationError] when the stored JSON can
  /// no longer be decoded.
  Future<Result<AuthToken?, AppError>> read() async {
    final raw = await _secure.read(storageKey);
    return switch (raw) {
      Err<String?, AppError>(:final error) => Err<AuthToken?, AppError>(error),
      Ok<String?, AppError>(value: null) => const Ok<AuthToken?, AppError>(null),
      Ok<String?, AppError>(:final value) => _decode(value),
    };
  }

  Result<AuthToken?, AppError> _decode(String? raw) {
    if (raw == null) {
      return const Ok<AuthToken?, AppError>(null);
    }
    try {
      final token = AuthToken.fromJson(jsonDecode(raw));
      return Ok<AuthToken?, AppError>(token);
    } on FormatException catch (error) {
      return Err<AuthToken?, AppError>(
        ValidationError(
          message: 'secure_token_storage.read: malformed token JSON',
          field: storageKey,
          cause: error,
        ),
      );
    }
  }

  /// Persists [token], replacing any previous value.
  Future<Result<void, AppError>> write(AuthToken token) {
    return _secure.write(storageKey, jsonEncode(token.toJson()));
  }

  /// Removes the persisted token. Safe to call when no token is stored.
  Future<Result<void, AppError>> clear() => _secure.delete(storageKey);
}

import 'dart:convert';

import 'package:core/core.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:storage/src/preferences_storage.dart';

/// Implementation of [StorageScope] backed by a [PreferencesStorage].
///
/// Every write goes to `"<miniAppId>.<key>"`, guaranteeing that two mini-apps
/// with different IDs cannot read each other's data. Values are JSON-encoded
/// so callers can store arbitrary JSON-serializable payloads and decode via
/// their own typed factory.
///
/// Use for non-sensitive per-mini-app data (last selected city, UI flags).
/// For tokens or credentials, use `ScopedSecureStorage` instead.
class ScopedStorage implements StorageScope {
  ScopedStorage({
    required this.miniAppId,
    required PreferencesStorage backend,
  }) : _backend = backend;

  final String miniAppId;
  final PreferencesStorage _backend;

  String _prefix() => '$miniAppId.';
  String _k(String key) => '$miniAppId.$key';

  @override
  Future<Result<T?, AppError>> read<T>(
    String key, {
    required T Function(Object? json) decode,
  }) async {
    final readResult = await _backend.readString(_k(key));
    return switch (readResult) {
      Err<String?, AppError>(:final error) => Err<T?, AppError>(error),
      Ok<String?, AppError>(:final value) => value == null
          ? Ok<T?, AppError>(null)
          : _decode<T>(key, value, decode),
    };
  }

  Result<T?, AppError> _decode<T>(
    String key,
    String raw,
    T Function(Object? json) decode,
  ) {
    try {
      final json = jsonDecode(raw);
      return Ok(decode(json));
    } on FormatException catch (error) {
      return Err(
        ValidationError(
          message: 'scoped_storage.read: malformed JSON at "$key": ${error.message}',
          field: key,
          cause: error,
        ),
      );
    } on Object catch (error) {
      return Err(
        ValidationError(
          message: 'scoped_storage.read: decode failed at "$key": $error',
          field: key,
          cause: error,
        ),
      );
    }
  }

  @override
  Future<Result<void, AppError>> write(String key, Object? value) async {
    try {
      final encoded = jsonEncode(value);
      return _backend.writeString(_k(key), encoded);
    } on Object catch (error) {
      return Err(
        ValidationError(
          message: 'scoped_storage.write: value at "$key" is not JSON-encodable: $error',
          field: key,
          cause: error,
        ),
      );
    }
  }

  @override
  Future<void> delete(String key) async {
    await _backend.delete(_k(key));
  }

  @override
  Future<void> clear() async {
    final keysResult = await _backend.keys();
    if (keysResult case Ok<Set<String>, AppError>(:final value)) {
      final prefix = _prefix();
      for (final k in value.where((k) => k.startsWith(prefix))) {
        await _backend.delete(k);
      }
    }
  }
}

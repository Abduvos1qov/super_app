import 'dart:convert';

import 'package:core/core.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:storage/src/secure_storage.dart';

/// Implementation of [StorageScope] backed by [SecureStorage].
///
/// Use when a mini-app needs to persist per-scope **sensitive** data
/// (OAuth tokens, payment handles, PII). Keys are namespaced as
/// `"<miniAppId>.<key>"`, matching [ScopedStorage], so one mini-app cannot
/// read another's secrets.
///
/// Because `flutter_secure_storage` does not expose a "list all keys" API
/// portably, [ScopedSecureStorage] tracks its own per-scope key index under
/// `"<miniAppId>.__keys__"`. `clear` walks this index and removes each entry.
class ScopedSecureStorage implements StorageScope {
  ScopedSecureStorage({
    required this.miniAppId,
    required SecureStorage backend,
  }) : _backend = backend;

  final String miniAppId;
  final SecureStorage _backend;

  String _k(String key) => '$miniAppId.$key';
  String get _indexKey => '$miniAppId.__keys__';

  @override
  Future<Result<T?, AppError>> read<T>(
    String key, {
    required T Function(Object? json) decode,
  }) async {
    final readResult = await _backend.read(_k(key));
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
          message: 'scoped_secure_storage.read: malformed JSON at "$key": ${error.message}',
          field: key,
          cause: error,
        ),
      );
    } on Object catch (error) {
      return Err(
        ValidationError(
          message: 'scoped_secure_storage.read: decode failed at "$key": $error',
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
      final writeResult = await _backend.write(_k(key), encoded);
      if (writeResult case Err<void, AppError>(:final error)) {
        return Err(error);
      }
      return _recordKey(key);
    } on Object catch (error) {
      return Err(
        ValidationError(
          message: 'scoped_secure_storage.write: value at "$key" is not JSON-encodable: $error',
          field: key,
          cause: error,
        ),
      );
    }
  }

  @override
  Future<void> delete(String key) async {
    await _backend.delete(_k(key));
    await _forgetKey(key);
  }

  @override
  Future<void> clear() async {
    final keys = await _loadIndex();
    for (final k in keys) {
      await _backend.delete(_k(k));
    }
    await _backend.delete(_indexKey);
  }

  Future<Set<String>> _loadIndex() async {
    final readResult = await _backend.read(_indexKey);
    if (readResult case Ok<String?, AppError>(:final value) when value != null) {
      try {
        final decoded = jsonDecode(value);
        if (decoded case final List<dynamic> list) {
          return list.whereType<String>().toSet();
        }
      } on FormatException {
        return <String>{};
      }
    }
    return <String>{};
  }

  Future<Result<void, AppError>> _recordKey(String key) async {
    final index = await _loadIndex();
    index.add(key);
    return _backend.write(_indexKey, jsonEncode(index.toList()));
  }

  Future<void> _forgetKey(String key) async {
    final index = await _loadIndex();
    if (!index.remove(key)) return;
    await _backend.write(_indexKey, jsonEncode(index.toList()));
  }
}

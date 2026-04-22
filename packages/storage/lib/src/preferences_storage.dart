import 'dart:convert';

import 'package:core/core.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive, typed key-value storage.
///
/// Use for user settings, flags, feature toggles, last-selected filters. Do
/// NOT store tokens, credentials, or PII here — use `SecureStorage` instead.
///
/// Lists and maps are JSON-encoded transparently. Decoding errors are
/// surfaced as [ValidationError] so callers can distinguish "bad stored
/// data" from "backend failure".
abstract class PreferencesStorage {
  Future<Result<String?, AppError>> readString(String key);
  Future<Result<void, AppError>> writeString(String key, String value);

  Future<Result<bool?, AppError>> readBool(String key);
  Future<Result<void, AppError>> writeBool(String key, bool value);

  Future<Result<int?, AppError>> readInt(String key);
  Future<Result<void, AppError>> writeInt(String key, int value);

  Future<Result<double?, AppError>> readDouble(String key);
  Future<Result<void, AppError>> writeDouble(String key, double value);

  Future<Result<List<String>?, AppError>> readStringList(String key);
  Future<Result<void, AppError>> writeStringList(String key, List<String> value);

  /// Reads a JSON-encoded map under [key]. Returns [ValidationError] if the
  /// stored blob cannot be decoded.
  Future<Result<Map<String, Object?>?, AppError>> readJson(String key);
  Future<Result<void, AppError>> writeJson(String key, Map<String, Object?> value);

  Future<Result<void, AppError>> delete(String key);
  Future<Result<void, AppError>> clear();

  /// Returns every key currently stored. Used by scoped-storage to implement
  /// per-prefix `clear`.
  Future<Result<Set<String>, AppError>> keys();
}

/// [PreferencesStorage] backed by `shared_preferences`.
class SharedPreferencesImpl implements PreferencesStorage {
  SharedPreferencesImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<Result<String?, AppError>> readString(String key) async => _read<String>(
        key,
        (k) => _prefs.getString(k),
      );

  @override
  Future<Result<void, AppError>> writeString(String key, String value) =>
      _write(key, () => _prefs.setString(key, value));

  @override
  Future<Result<bool?, AppError>> readBool(String key) async => _read<bool>(
        key,
        (k) => _prefs.getBool(k),
      );

  @override
  Future<Result<void, AppError>> writeBool(String key, bool value) =>
      _write(key, () => _prefs.setBool(key, value));

  @override
  Future<Result<int?, AppError>> readInt(String key) async => _read<int>(
        key,
        (k) => _prefs.getInt(k),
      );

  @override
  Future<Result<void, AppError>> writeInt(String key, int value) =>
      _write(key, () => _prefs.setInt(key, value));

  @override
  Future<Result<double?, AppError>> readDouble(String key) async => _read<double>(
        key,
        (k) => _prefs.getDouble(k),
      );

  @override
  Future<Result<void, AppError>> writeDouble(String key, double value) =>
      _write(key, () => _prefs.setDouble(key, value));

  @override
  Future<Result<List<String>?, AppError>> readStringList(String key) async =>
      _read<List<String>>(key, (k) => _prefs.getStringList(k));

  @override
  Future<Result<void, AppError>> writeStringList(String key, List<String> value) =>
      _write(key, () => _prefs.setStringList(key, value));

  @override
  Future<Result<Map<String, Object?>?, AppError>> readJson(String key) async {
    try {
      final raw = _prefs.getString(key);
      if (raw == null) return const Ok(null);
      final decoded = jsonDecode(raw);
      if (decoded case final Map<String, Object?> map) {
        return Ok(map);
      }
      return Err(
        ValidationError(
          message: 'preferences_storage.readJson: value at "$key" is not a JSON object',
          field: key,
        ),
      );
    } on FormatException catch (error) {
      return Err(
        ValidationError(
          message: 'preferences_storage.readJson: malformed JSON at "$key": ${error.message}',
          field: key,
          cause: error,
        ),
      );
    } on Object catch (error) {
      return Err(_wrap(error, 'preferences_storage.readJson'));
    }
  }

  @override
  Future<Result<void, AppError>> writeJson(String key, Map<String, Object?> value) async {
    try {
      final encoded = jsonEncode(value);
      await _prefs.setString(key, encoded);
      return const Ok(null);
    } on Object catch (error) {
      return Err(_wrap(error, 'preferences_storage.writeJson'));
    }
  }

  @override
  Future<Result<void, AppError>> delete(String key) async {
    try {
      await _prefs.remove(key);
      return const Ok(null);
    } on Object catch (error) {
      return Err(_wrap(error, 'preferences_storage.delete'));
    }
  }

  @override
  Future<Result<void, AppError>> clear() async {
    try {
      await _prefs.clear();
      return const Ok(null);
    } on Object catch (error) {
      return Err(_wrap(error, 'preferences_storage.clear'));
    }
  }

  @override
  Future<Result<Set<String>, AppError>> keys() async {
    try {
      return Ok(_prefs.getKeys());
    } on Object catch (error) {
      return Err(_wrap(error, 'preferences_storage.keys'));
    }
  }

  Future<Result<T?, AppError>> _read<T>(
    String key,
    T? Function(String key) getter,
  ) async {
    try {
      return Ok(getter(key));
    } on Object catch (error) {
      return Err(_wrap(error, 'preferences_storage.read'));
    }
  }

  Future<Result<void, AppError>> _write(String key, Future<bool> Function() setter) async {
    try {
      await setter();
      return const Ok(null);
    } on Object catch (error) {
      return Err(_wrap(error, 'preferences_storage.write'));
    }
  }

  AppError _wrap(Object error, String op) =>
      UnknownError(message: '$op failed: $error', cause: error);
}

/// In-memory [PreferencesStorage] for unit tests. Never use in production.
@visibleForTesting
class InMemoryPreferencesStorage implements PreferencesStorage {
  final Map<String, Object?> _data = <String, Object?>{};

  /// Read-only snapshot of the underlying map.
  @visibleForTesting
  Map<String, Object?> get snapshot => Map<String, Object?>.unmodifiable(_data);

  @override
  Future<Result<String?, AppError>> readString(String key) async => _typed<String>(key);

  @override
  Future<Result<void, AppError>> writeString(String key, String value) async {
    _data[key] = value;
    return const Ok(null);
  }

  @override
  Future<Result<bool?, AppError>> readBool(String key) async => _typed<bool>(key);

  @override
  Future<Result<void, AppError>> writeBool(String key, bool value) async {
    _data[key] = value;
    return const Ok(null);
  }

  @override
  Future<Result<int?, AppError>> readInt(String key) async => _typed<int>(key);

  @override
  Future<Result<void, AppError>> writeInt(String key, int value) async {
    _data[key] = value;
    return const Ok(null);
  }

  @override
  Future<Result<double?, AppError>> readDouble(String key) async => _typed<double>(key);

  @override
  Future<Result<void, AppError>> writeDouble(String key, double value) async {
    _data[key] = value;
    return const Ok(null);
  }

  @override
  Future<Result<List<String>?, AppError>> readStringList(String key) async {
    final value = _data[key];
    if (value == null) return const Ok(null);
    if (value case final List<String> list) {
      return Ok(List<String>.unmodifiable(list));
    }
    return Err(
      ValidationError(
        message: 'preferences_storage.readStringList: value at "$key" is not List<String>',
        field: key,
      ),
    );
  }

  @override
  Future<Result<void, AppError>> writeStringList(String key, List<String> value) async {
    _data[key] = List<String>.unmodifiable(value);
    return const Ok(null);
  }

  @override
  Future<Result<Map<String, Object?>?, AppError>> readJson(String key) async {
    final value = _data[key];
    if (value == null) return const Ok(null);
    if (value case final Map<String, Object?> map) {
      return Ok(Map<String, Object?>.unmodifiable(map));
    }
    if (value case final String raw) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded case final Map<String, Object?> map) {
          return Ok(map);
        }
        return Err(
          ValidationError(
            message: 'preferences_storage.readJson: value at "$key" is not a JSON object',
            field: key,
          ),
        );
      } on FormatException catch (error) {
        return Err(
          ValidationError(
            message: 'preferences_storage.readJson: malformed JSON at "$key"',
            field: key,
            cause: error,
          ),
        );
      }
    }
    return Err(
      ValidationError(
        message: 'preferences_storage.readJson: value at "$key" is not a map',
        field: key,
      ),
    );
  }

  @override
  Future<Result<void, AppError>> writeJson(String key, Map<String, Object?> value) async {
    _data[key] = Map<String, Object?>.unmodifiable(value);
    return const Ok(null);
  }

  @override
  Future<Result<void, AppError>> delete(String key) async {
    _data.remove(key);
    return const Ok(null);
  }

  @override
  Future<Result<void, AppError>> clear() async {
    _data.clear();
    return const Ok(null);
  }

  @override
  Future<Result<Set<String>, AppError>> keys() async =>
      Ok(Set<String>.unmodifiable(_data.keys));

  Result<T?, AppError> _typed<T>(String key) {
    final value = _data[key];
    if (value == null) return const Ok(null);
    if (value is T) return Ok<T?, AppError>(value as T);
    return Err(
      ValidationError(
        message:
            'preferences_storage.read<$T>: value at "$key" is ${value.runtimeType}',
        field: key,
      ),
    );
  }
}

import 'package:core/core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:meta/meta.dart';

/// Platform-neutral key-value secure storage.
///
/// Use for secrets that must never leak to disk in plaintext: auth tokens,
/// refresh tokens, credentials, PII. All operations return [Result] rather
/// than throwing so callers are forced to acknowledge failure at compile
/// time.
abstract class SecureStorage {
  /// Reads the value for [key]. Returns `Ok(null)` when absent.
  Future<Result<String?, AppError>> read(String key);

  /// Writes [value] under [key].
  Future<Result<void, AppError>> write(String key, String value);

  /// Deletes [key] if present. No-op when absent.
  Future<Result<void, AppError>> delete(String key);

  /// Removes every key owned by this storage.
  Future<Result<void, AppError>> clear();
}

/// [SecureStorage] backed by `flutter_secure_storage` (Keychain / Keystore).
class FlutterSecureStorageImpl implements SecureStorage {
  FlutterSecureStorageImpl({FlutterSecureStorage? backend})
      : _backend = backend ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _backend;

  @override
  Future<Result<String?, AppError>> read(String key) async {
    try {
      final value = await _backend.read(key: key);
      return Ok(value);
    } on Object catch (error) {
      return Err(_wrap(error, 'secure_storage.read'));
    }
  }

  @override
  Future<Result<void, AppError>> write(String key, String value) async {
    try {
      await _backend.write(key: key, value: value);
      return const Ok(null);
    } on Object catch (error) {
      return Err(_wrap(error, 'secure_storage.write'));
    }
  }

  @override
  Future<Result<void, AppError>> delete(String key) async {
    try {
      await _backend.delete(key: key);
      return const Ok(null);
    } on Object catch (error) {
      return Err(_wrap(error, 'secure_storage.delete'));
    }
  }

  @override
  Future<Result<void, AppError>> clear() async {
    try {
      await _backend.deleteAll();
      return const Ok(null);
    } on Object catch (error) {
      return Err(_wrap(error, 'secure_storage.clear'));
    }
  }

  AppError _wrap(Object error, String op) =>
      UnknownError(message: '$op failed: $error', cause: error);
}

/// In-memory [SecureStorage] for unit tests. Never use in production.
@visibleForTesting
class InMemorySecureStorage implements SecureStorage {
  final Map<String, String> _data = <String, String>{};

  /// Read-only snapshot of the underlying map, exposed for assertions.
  @visibleForTesting
  Map<String, String> get snapshot => Map<String, String>.unmodifiable(_data);

  @override
  Future<Result<String?, AppError>> read(String key) async => Ok(_data[key]);

  @override
  Future<Result<void, AppError>> write(String key, String value) async {
    _data[key] = value;
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
}

import 'package:core/core.dart';

/// Per-mini-app, shell-mediated key-value store.
///
/// The shell isolates each mini-app's storage namespace so one vertical can
/// never read another vertical's data. Backing implementation (secure
/// storage, disk cache, in-memory) is a shell-side concern. All operations
/// return [Result] instead of throwing.
abstract class StorageScope {
  /// Reads the value for [key] and decodes it via [decode].
  ///
  /// Returns `Ok(null)` when the key is absent.
  Future<Result<T?, AppError>> read<T>(
    String key, {
    required T Function(Object? json) decode,
  });

  /// Writes [value] under [key]. [value] must be JSON-encodable; encoding is
  /// performed by the shell.
  Future<Result<void, AppError>> write(String key, Object? value);

  /// Removes [key] if present. No-op when absent.
  Future<void> delete(String key);

  /// Clears every key owned by the calling mini-app's scope.
  Future<void> clear();
}

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

/// A [FeatureFlagService] backed by an immutable compile-time map.
///
/// Suitable for build-variant defaults (dev/staging/prod) and as the
/// lowest-priority source inside a [FeatureFlagService] composite. The flag
/// snapshot never changes, so `changes` returns an empty stream.
///
/// Values may be `bool`, `String`, or any JSON-compatible `Object?` for
/// `jsonFlag`. Values of the wrong type are treated as missing and the
/// caller-supplied fallback is returned.
@immutable
class StaticFeatureFlagService implements FeatureFlagService {
  /// Creates a static service from the given `flags` map.
  const StaticFeatureFlagService(this._flags);

  final Map<String, Object?> _flags;

  /// An unmodifiable view of the underlying flag map. Intended for debugging
  /// and tests, not for hot-path lookups.
  Map<String, Object?> get snapshot =>
      Map<String, Object?>.unmodifiable(_flags);

  /// Whether this service has an entry for [key]. Used by composite sources
  /// to skip past this layer when the key is undefined here.
  bool has(String key) => _flags.containsKey(key);

  @override
  bool boolFlag(String key, {bool fallback = false}) {
    final value = _flags[key];
    return value is bool ? value : fallback;
  }

  @override
  String stringFlag(String key, {String fallback = ''}) {
    final value = _flags[key];
    return value is String ? value : fallback;
  }

  @override
  T jsonFlag<T>(
    String key, {
    required T Function(Object? json) decode,
    required T fallback,
  }) {
    if (!_flags.containsKey(key)) {
      return fallback;
    }
    try {
      return decode(_flags[key]);
    } on Object {
      return fallback;
    }
  }

  @override
  Stream<void> changes() => const Stream<void>.empty();
}

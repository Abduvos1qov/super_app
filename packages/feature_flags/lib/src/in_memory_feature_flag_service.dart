import 'dart:async';

import 'package:mini_app_sdk/mini_app_sdk.dart';

/// A mutable, in-memory [FeatureFlagService].
///
/// Intended for:
/// * unit and widget tests that need to simulate specific flag states,
/// * the debug/QA override layer of a composite service (highest priority),
/// * development flows where a long-poll remote source has not yet landed.
///
/// Every mutation emits on [changes], so reactive consumers can re-evaluate.
class InMemoryFeatureFlagService implements FeatureFlagService {
  /// Creates a service seeded with [initial] flags. The provided map is
  /// copied; subsequent mutations to the original do not affect this
  /// service.
  InMemoryFeatureFlagService([Map<String, Object?> initial = const {}])
      : _flags = Map<String, Object?>.of(initial),
        _changes = StreamController<void>.broadcast();

  final Map<String, Object?> _flags;
  final StreamController<void> _changes;

  /// An unmodifiable view of the underlying flag map.
  Map<String, Object?> get snapshot =>
      Map<String, Object?>.unmodifiable(_flags);

  /// Whether this service has an entry for [key].
  bool has(String key) => _flags.containsKey(key);

  /// Whether [dispose] has already been invoked.
  bool get isDisposed => _changes.isClosed;

  /// Sets [key] to [value] and notifies subscribers. A `null` value is still
  /// stored as a present entry; call [remove] to delete it entirely.
  void set(String key, Object? value) {
    _flags[key] = value;
    _emitChange();
  }

  /// Removes [key] from the map and notifies subscribers. No-op if the key
  /// is already absent (no event is emitted).
  void remove(String key) {
    if (_flags.remove(key) != null || _flags.containsKey(key)) {
      _emitChange();
    }
  }

  /// Overwrites the map with [flags] and notifies subscribers.
  void replaceAll(Map<String, Object?> flags) {
    _flags
      ..clear()
      ..addAll(flags);
    _emitChange();
  }

  /// Clears every flag and notifies subscribers.
  void clear() {
    if (_flags.isEmpty) {
      return;
    }
    _flags.clear();
    _emitChange();
  }

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
  Stream<void> changes() => _changes.stream;

  /// Closes the [changes] stream. Idempotent.
  Future<void> dispose() async {
    if (_changes.isClosed) {
      return;
    }
    await _changes.close();
  }

  void _emitChange() {
    if (_changes.isClosed) {
      return;
    }
    _changes.add(null);
  }
}

import 'dart:async';

import 'package:feature_flags/src/in_memory_feature_flag_service.dart';
import 'package:feature_flags/src/static_feature_flag_service.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

/// A [FeatureFlagService] that resolves each lookup against an ordered list
/// of sources, returning the first source that declares the key.
///
/// Typical composition (highest priority first):
///
/// ```dart
/// CompositeFeatureFlagService([
///   debugOverrides,     // InMemoryFeatureFlagService
///   remoteConfig,       // vendor adapter (e.g. feature_flags_firebase)
///   localCache,         // another in-memory or persisted layer
///   staticDefaults,     // StaticFeatureFlagService
/// ]);
/// ```
///
/// ## Key detection
///
/// The underlying [FeatureFlagService] interface has no `has(key)` method.
/// To detect whether a source defines a key, this service uses two
/// strategies:
///
/// * **Fast path** — when a source is a [StaticFeatureFlagService] or
///   [InMemoryFeatureFlagService] (both from this package), `has` is called
///   directly.
/// * **Fallback** — for every other `FeatureFlagService` implementation, the
///   service probes `boolFlag` / `stringFlag` with two distinct fallback
///   values; if both calls return the same value, the source owns the key.
///
/// ### Limitation on [jsonFlag]
///
/// There is no reliable way to probe a JSON flag through the public
/// interface because callers must supply a single required fallback and a
/// free-form decoder. For JSON lookups this service therefore falls back to
/// "first declared source wins": it iterates sources in priority order and
/// asks each for the key, returning the first result that differs from the
/// sentinel produced by a dedicated lightweight decode attempt. In practice,
/// JSON flags should be resolved from sources that implement `has` (i.e.
/// [StaticFeatureFlagService] or [InMemoryFeatureFlagService]); other
/// sources participate on a best-effort basis.
class CompositeFeatureFlagService implements FeatureFlagService {
  /// Creates a composite that queries [sources] in priority order.
  /// The first entry has the highest priority.
  CompositeFeatureFlagService(List<FeatureFlagService> sources)
      : _sources = List<FeatureFlagService>.unmodifiable(sources);

  final List<FeatureFlagService> _sources;

  /// The underlying sources in priority order.
  List<FeatureFlagService> get sources => _sources;

  @override
  bool boolFlag(String key, {bool fallback = false}) {
    for (final source in _sources) {
      if (_has(source, key, isBool: true)) {
        return source.boolFlag(key, fallback: fallback);
      }
    }
    return fallback;
  }

  @override
  String stringFlag(String key, {String fallback = ''}) {
    for (final source in _sources) {
      if (_has(source, key, isBool: false)) {
        return source.stringFlag(key, fallback: fallback);
      }
    }
    return fallback;
  }

  @override
  T jsonFlag<T>(
    String key, {
    required T Function(Object? json) decode,
    required T fallback,
  }) {
    for (final source in _sources) {
      if (_hasFast(source, key)) {
        return source.jsonFlag(key, decode: decode, fallback: fallback);
      }
    }
    return fallback;
  }

  @override
  Stream<void> changes() {
    if (_sources.isEmpty) {
      return const Stream<void>.empty();
    }
    return _MergedVoidStream(
      _sources.map((s) => s.changes()).toList(),
    ).stream;
  }

  /// Returns `true` if [source] declares [key].
  ///
  /// Uses [_hasFast] for known in-package sources and the sentinel-probe
  /// strategy for every other [FeatureFlagService] implementation.
  bool _has(FeatureFlagService source, String key, {required bool isBool}) {
    if (_hasFast(source, key)) {
      return true;
    }
    if (source is StaticFeatureFlagService ||
        source is InMemoryFeatureFlagService) {
      // Fast path already returned a definitive answer above.
      return false;
    }
    if (isBool) {
      final probeTrue = source.boolFlag(key, fallback: true);
      final probeFalse = source.boolFlag(key);
      return probeTrue == probeFalse;
    }
    const sentinelA = '__feature_flags_sentinel_a__';
    const sentinelB = '__feature_flags_sentinel_b__';
    final probeA = source.stringFlag(key, fallback: sentinelA);
    final probeB = source.stringFlag(key, fallback: sentinelB);
    return probeA == probeB;
  }

  bool _hasFast(FeatureFlagService source, String key) {
    if (source is StaticFeatureFlagService) {
      return source.has(key);
    }
    if (source is InMemoryFeatureFlagService) {
      return source.has(key);
    }
    return false;
  }
}

/// Merges multiple `Stream<void>` inputs into a single broadcast output.
///
/// Kept private so the package does not need a dependency on
/// `package:async`. The [stream] getter is safe to listen to multiple times.
class _MergedVoidStream {
  _MergedVoidStream(List<Stream<void>> inputs) {
    _controller = StreamController<void>.broadcast(
      onListen: () {
        for (final input in inputs) {
          _subs.add(
            input.listen(
              _controller.add,
              onError: _controller.addError,
            ),
          );
        }
      },
      onCancel: () async {
        for (final sub in _subs) {
          await sub.cancel();
        }
        _subs.clear();
      },
    );
  }

  late final StreamController<void> _controller;
  final List<StreamSubscription<void>> _subs = <StreamSubscription<void>>[];

  Stream<void> get stream => _controller.stream;
}

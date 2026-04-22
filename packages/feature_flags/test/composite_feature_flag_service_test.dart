import 'dart:async';

import 'package:feature_flags/feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

/// Adapter that wraps a plain [Map] without exposing a `has()` method, to
/// exercise the composite's sentinel-probe fallback path.
class _OpaqueFeatureFlagService implements FeatureFlagService {
  _OpaqueFeatureFlagService(this._flags);

  final Map<String, Object?> _flags;

  @override
  bool boolFlag(String key, {bool fallback = false}) {
    final v = _flags[key];
    return v is bool ? v : fallback;
  }

  @override
  String stringFlag(String key, {String fallback = ''}) {
    final v = _flags[key];
    return v is String ? v : fallback;
  }

  @override
  T jsonFlag<T>(
    String key, {
    required T Function(Object? json) decode,
    required T fallback,
  }) {
    if (!_flags.containsKey(key)) return fallback;
    try {
      return decode(_flags[key]);
    } on Object {
      return fallback;
    }
  }

  @override
  Stream<void> changes() => const Stream<void>.empty();
}

void main() {
  group('CompositeFeatureFlagService', () {
    test('returns higher-priority source when both define the key', () {
      const high = StaticFeatureFlagService({'ui.tab': true});
      const low = StaticFeatureFlagService({'ui.tab': false});
      final sut = CompositeFeatureFlagService([high, low]);
      expect(sut.boolFlag('ui.tab'), isTrue);
    });

    test('falls through to lower-priority source when higher lacks key', () {
      const high = StaticFeatureFlagService(<String, Object?>{});
      const low = StaticFeatureFlagService({'ui.tab': true});
      final sut = CompositeFeatureFlagService([high, low]);
      expect(sut.boolFlag('ui.tab'), isTrue);
    });

    test('returns fallback when no source declares the key', () {
      const a = StaticFeatureFlagService(<String, Object?>{});
      const b = StaticFeatureFlagService(<String, Object?>{});
      final sut = CompositeFeatureFlagService([a, b]);
      expect(sut.boolFlag('missing', fallback: true), isTrue);
      expect(sut.stringFlag('missing', fallback: 'x'), 'x');
    });

    test('string flag resolves by priority order', () {
      const high = StaticFeatureFlagService({'greeting': 'hi'});
      const low = StaticFeatureFlagService({'greeting': 'bye'});
      final sut = CompositeFeatureFlagService([high, low]);
      expect(sut.stringFlag('greeting'), 'hi');
    });

    test('jsonFlag resolves from first source that has the key', () {
      const high = StaticFeatureFlagService(<String, Object?>{});
      const low = StaticFeatureFlagService({'limit': 9});
      final sut = CompositeFeatureFlagService([high, low]);
      final v = sut.jsonFlag<int>(
        'limit',
        decode: (raw) => raw is int ? raw : 0,
        fallback: 0,
      );
      expect(v, 9);
    });

    test('detects keys from opaque sources via sentinel probing (bool)', () {
      final opaque = _OpaqueFeatureFlagService({'feature.x': false});
      const statics = StaticFeatureFlagService({'feature.x': true});
      // Opaque is higher priority; it owns feature.x with value `false`.
      final sut = CompositeFeatureFlagService([opaque, statics]);
      expect(sut.boolFlag('feature.x'), isFalse);
    });

    test('detects keys from opaque sources via sentinel probing (string)', () {
      final opaque = _OpaqueFeatureFlagService({'copy': 'opaque'});
      const statics = StaticFeatureFlagService({'copy': 'static'});
      final sut = CompositeFeatureFlagService([opaque, statics]);
      expect(sut.stringFlag('copy'), 'opaque');
    });

    test('changes() merges emissions from every mutable source', () async {
      final a = InMemoryFeatureFlagService();
      final b = InMemoryFeatureFlagService();
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      final sut = CompositeFeatureFlagService([a, b]);

      final events = <void>[];
      final sub = sut.changes().listen(events.add);

      a.set('k', 1);
      b.set('k', 2);
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(2));
      await sub.cancel();
    });

    test('changes() of empty composite is an empty stream', () async {
      final sut = CompositeFeatureFlagService(const []);
      expect(await sut.changes().isEmpty, isTrue);
    });

    test('sources getter returns unmodifiable list', () {
      final sut = CompositeFeatureFlagService(
        [const StaticFeatureFlagService(<String, Object?>{})],
      );
      expect(
        () => sut.sources.add(
          const StaticFeatureFlagService(<String, Object?>{}),
        ),
        throwsUnsupportedError,
      );
    });
  });
}

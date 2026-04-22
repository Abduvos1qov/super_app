import 'package:feature_flags/feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StaticFeatureFlagService', () {
    test('returns bool flag when key exists and value is bool', () {
      const sut = StaticFeatureFlagService({'feature.a': true});
      expect(sut.boolFlag('feature.a'), isTrue);
    });

    test('returns fallback for bool flag when key is missing', () {
      const sut = StaticFeatureFlagService(<String, Object?>{});
      expect(sut.boolFlag('missing', fallback: true), isTrue);
      expect(sut.boolFlag('missing'), isFalse);
    });

    test('returns fallback for bool flag when value type mismatches', () {
      const sut = StaticFeatureFlagService({'feature.a': 'yes'});
      expect(sut.boolFlag('feature.a', fallback: true), isTrue);
    });

    test('returns string flag when key exists and value is string', () {
      const sut = StaticFeatureFlagService({'greeting': 'hi'});
      expect(sut.stringFlag('greeting'), 'hi');
    });

    test('returns fallback for string flag when missing or wrong type', () {
      const sut = StaticFeatureFlagService({'n': 42});
      expect(sut.stringFlag('n', fallback: 'def'), 'def');
      expect(sut.stringFlag('missing', fallback: 'def'), 'def');
    });

    test('decodes json flag through caller-supplied decoder', () {
      const sut = StaticFeatureFlagService({
        'limit': 5,
      });
      final result = sut.jsonFlag<int>(
        'limit',
        decode: (raw) => raw is int ? raw : 0,
        fallback: 0,
      );
      expect(result, 5);
    });

    test('returns fallback when decoder throws', () {
      const sut = StaticFeatureFlagService({'limit': 'not-a-number'});
      final result = sut.jsonFlag<int>(
        'limit',
        decode: (raw) => throw StateError('boom'),
        fallback: 99,
      );
      expect(result, 99);
    });

    test('returns fallback when json key is missing', () {
      const sut = StaticFeatureFlagService(<String, Object?>{});
      final result = sut.jsonFlag<int>(
        'missing',
        decode: (raw) => 0,
        fallback: -1,
      );
      expect(result, -1);
    });

    test('changes() is empty stream', () async {
      const sut = StaticFeatureFlagService(<String, Object?>{});
      expect(await sut.changes().isEmpty, isTrue);
    });

    test('has() reports whether a key is defined', () {
      const sut = StaticFeatureFlagService({'a': 1, 'b': null});
      expect(sut.has('a'), isTrue);
      expect(sut.has('b'), isTrue); // null-valued entries still count
      expect(sut.has('missing'), isFalse);
    });

    test('snapshot is unmodifiable', () {
      const sut = StaticFeatureFlagService({'a': 1});
      expect(
        () => sut.snapshot['b'] = 2,
        throwsUnsupportedError,
      );
    });
  });
}

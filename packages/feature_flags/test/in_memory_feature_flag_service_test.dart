import 'package:feature_flags/feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryFeatureFlagService', () {
    late InMemoryFeatureFlagService sut;

    setUp(() {
      sut = InMemoryFeatureFlagService();
    });

    tearDown(() async {
      await sut.dispose();
    });

    test('accepts an initial map and copies it defensively', () {
      final seed = <String, Object?>{'a': true};
      final service = InMemoryFeatureFlagService(seed);
      seed['a'] = false;
      expect(service.boolFlag('a'), isTrue);
    });

    test('set() stores a value and emits on changes()', () async {
      final events = <void>[];
      final sub = sut.changes().listen(events.add);
      sut.set('feature.a', true);
      await Future<void>.delayed(Duration.zero);
      expect(sut.boolFlag('feature.a'), isTrue);
      expect(events, hasLength(1));
      await sub.cancel();
    });

    test('remove() deletes the key and emits on changes()', () async {
      sut.set('feature.a', true);
      final events = <void>[];
      final sub = sut.changes().listen(events.add);
      sut.remove('feature.a');
      await Future<void>.delayed(Duration.zero);
      expect(sut.has('feature.a'), isFalse);
      expect(events, hasLength(1));
      await sub.cancel();
    });

    test('remove() is silent when the key is absent', () async {
      final events = <void>[];
      final sub = sut.changes().listen(events.add);
      sut.remove('missing');
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
      await sub.cancel();
    });

    test('replaceAll() swaps the snapshot and emits once', () async {
      sut.set('a', 1);
      final events = <void>[];
      final sub = sut.changes().listen(events.add);
      sut.replaceAll({'b': 'x'});
      await Future<void>.delayed(Duration.zero);
      expect(sut.has('a'), isFalse);
      expect(sut.stringFlag('b'), 'x');
      expect(events, hasLength(1));
      await sub.cancel();
    });

    test('clear() empties the map and emits when non-empty', () async {
      sut.set('a', 1);
      final events = <void>[];
      final sub = sut.changes().listen(events.add);
      sut.clear();
      await Future<void>.delayed(Duration.zero);
      expect(sut.snapshot, isEmpty);
      expect(events, hasLength(1));
      await sub.cancel();
    });

    test('clear() is silent when already empty', () async {
      final events = <void>[];
      final sub = sut.changes().listen(events.add);
      sut.clear();
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
      await sub.cancel();
    });

    test('jsonFlag decodes and respects fallback on error', () {
      sut.set('cfg', {'limit': 7});
      final decoded = sut.jsonFlag<int>(
        'cfg',
        decode: (raw) => (raw! as Map<String, Object?>)['limit']! as int,
        fallback: 0,
      );
      expect(decoded, 7);

      final onMissing = sut.jsonFlag<int>(
        'missing',
        decode: (raw) => 0,
        fallback: -1,
      );
      expect(onMissing, -1);
    });

    test('dispose() closes the stream and becomes idempotent', () async {
      expect(sut.isDisposed, isFalse);
      await sut.dispose();
      expect(sut.isDisposed, isTrue);
      await sut.dispose();
      // set after dispose does not throw; just has no subscribers.
      sut.set('a', 1);
    });
  });
}

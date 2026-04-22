import 'package:analytics/analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

class _ThrowingTracker implements AnalyticsTracker {
  int trackCalls = 0;
  int userPropertyCalls = 0;
  int flushCalls = 0;

  @override
  void track(String event, {Map<String, Object?> props = const {}}) {
    trackCalls++;
    throw StateError('boom-track');
  }

  @override
  void setUserProperty(String key, Object? value) {
    userPropertyCalls++;
    throw StateError('boom-user');
  }

  @override
  Future<void> flush() async {
    flushCalls++;
    throw StateError('boom-flush');
  }
}

class _SlowTracker implements AnalyticsTracker {
  int flushCalls = 0;
  bool flushResolved = false;

  @override
  void track(String event, {Map<String, Object?> props = const {}}) {}

  @override
  void setUserProperty(String key, Object? value) {}

  @override
  Future<void> flush() async {
    flushCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    flushResolved = true;
  }
}

void main() {
  group('FanoutAnalyticsTracker', () {
    late InMemoryAnalyticsTracker a;
    late InMemoryAnalyticsTracker b;
    late FanoutAnalyticsTracker sut;

    setUp(() {
      a = InMemoryAnalyticsTracker();
      b = InMemoryAnalyticsTracker();
      sut = FanoutAnalyticsTracker([a, b]);
    });

    test('forwards track to every tracker in order', () {
      sut.track('demo.tap', props: const {'x': 1});

      expect(a.events, hasLength(1));
      expect(b.events, hasLength(1));
      expect(a.events.single.name, 'demo.tap');
      expect(a.events.single.props, {'x': 1});
      expect(b.events.single.props, {'x': 1});
    });

    test('forwards setUserProperty to every tracker', () {
      sut.setUserProperty('tier', 'gold');

      expect(a.userProperties, equals({'tier': 'gold'}));
      expect(b.userProperties, equals({'tier': 'gold'}));
    });

    test('flush awaits every underlying flush', () async {
      final slow = _SlowTracker();
      final fanout = FanoutAnalyticsTracker([a, slow, b]);

      await fanout.flush();

      expect(a.flushCount, 1);
      expect(b.flushCount, 1);
      expect(slow.flushCalls, 1);
      expect(slow.flushResolved, isTrue);
    });

    test('track is best-effort: a throwing tracker does not skip the others',
        () {
      final bad = _ThrowingTracker();
      FanoutAnalyticsTracker([a, bad, b]).track('demo.tap');

      expect(bad.trackCalls, 1);
      expect(a.events, hasLength(1));
      expect(b.events, hasLength(1));
    });

    test(
      'setUserProperty is best-effort: a throwing tracker does not skip '
      'the others',
      () {
        final bad = _ThrowingTracker();
        FanoutAnalyticsTracker([a, bad, b]).setUserProperty('tier', 'gold');

        expect(bad.userPropertyCalls, 1);
        expect(a.userProperties, equals({'tier': 'gold'}));
        expect(b.userProperties, equals({'tier': 'gold'}));
      },
    );

    test('flush is best-effort: throwing tracker does not abort others',
        () async {
      final bad = _ThrowingTracker();
      final fanout = FanoutAnalyticsTracker([a, bad, b]);

      await expectLater(fanout.flush(), completes);

      expect(bad.flushCalls, 1);
      expect(a.flushCount, 1);
      expect(b.flushCount, 1);
    });

    test('trackers getter exposes an unmodifiable list', () {
      expect(
        () => sut.trackers.add(InMemoryAnalyticsTracker()),
        throwsUnsupportedError,
      );
    });

    test('works with an empty tracker list', () async {
      final empty = FanoutAnalyticsTracker(const [])
        ..track('demo.tap')
        ..setUserProperty('tier', 'gold');

      await expectLater(empty.flush(), completes);
    });
  });
}

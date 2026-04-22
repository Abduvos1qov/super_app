import 'package:analytics/analytics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryAnalyticsTracker', () {
    late InMemoryAnalyticsTracker sut;

    setUp(() {
      sut = InMemoryAnalyticsTracker();
    });

    test('records tracked events with defensive copies of props', () {
      final props = <String, Object?>{'x': 1};

      sut.track('demo.tap', props: props);
      props['x'] = 99;

      expect(sut.events, hasLength(1));
      expect(sut.events.single.name, 'demo.tap');
      expect(sut.events.single.props, equals({'x': 1}));
    });

    test('records multiple events in call order', () {
      sut
        ..track('a')
        ..track('b')
        ..track('c');

      expect(sut.events.map((e) => e.name), ['a', 'b', 'c']);
    });

    test('stores user properties', () {
      sut
        ..setUserProperty('tier', 'gold')
        ..setUserProperty('lang', 'uz');

      expect(sut.userProperties, equals({'tier': 'gold', 'lang': 'uz'}));
    });

    test('removes user property when set to null', () {
      sut
        ..setUserProperty('tier', 'gold')
        ..setUserProperty('tier', null);

      expect(sut.userProperties, isEmpty);
    });

    test('flush increments flushCount', () async {
      await sut.flush();
      await sut.flush();

      expect(sut.flushCount, 2);
    });

    test('clear resets events, userProperties, and flushCount', () async {
      sut
        ..track('demo.tap')
        ..setUserProperty('tier', 'gold');
      await sut.flush();

      sut.clear();

      expect(sut.events, isEmpty);
      expect(sut.userProperties, isEmpty);
      expect(sut.flushCount, 0);
    });

    group('TrackedEvent equality', () {
      test('equals another event with the same name and props', () {
        const a = TrackedEvent('demo.tap', {'x': 1});
        const b = TrackedEvent('demo.tap', {'x': 1});

        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('differs when the name differs', () {
        const a = TrackedEvent('demo.tap', {'x': 1});
        const b = TrackedEvent('demo.swipe', {'x': 1});

        expect(a, isNot(equals(b)));
      });

      test('differs when a prop value differs', () {
        const a = TrackedEvent('demo.tap', {'x': 1});
        const b = TrackedEvent('demo.tap', {'x': 2});

        expect(a, isNot(equals(b)));
      });

      test('toString includes name and props', () {
        const event = TrackedEvent('demo.tap', {'x': 1});

        expect(event.toString(), contains('demo.tap'));
        expect(event.toString(), contains('x'));
      });
    });
  });
}

import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

/// A concrete [AppEvent] used exclusively in tests.
class TestEventA extends AppEvent {
  const TestEventA(this.payload);

  final String payload;

  @override
  String get topic => 'test.a';
}

/// A second concrete [AppEvent] used exclusively in tests.
class TestEventB extends AppEvent {
  const TestEventB(this.value);

  final int value;

  @override
  String get topic => 'test.b';
}

void main() {
  group('StreamAppEventBus', () {
    late StreamAppEventBus sut;

    setUp(() {
      sut = StreamAppEventBus();
    });

    tearDown(() async {
      if (!sut.isDisposed) {
        await sut.dispose();
      }
    });

    test('delivers a published event to a registered subscriber', () async {
      final received = <TestEventA>[];
      final sub = sut.on<TestEventA>().listen(received.add);

      sut.publish(const TestEventA('hello'));
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single.payload, equals('hello'));
      await sub.cancel();
    });

    test('on<T>() filters out events of other types', () async {
      final receivedA = <TestEventA>[];
      final subA = sut.on<TestEventA>().listen(receivedA.add);

      sut
        ..publish(const TestEventB(1))
        ..publish(const TestEventA('match'))
        ..publish(const TestEventB(2));
      await Future<void>.delayed(Duration.zero);

      expect(receivedA, hasLength(1));
      expect(receivedA.single.payload, equals('match'));
      await subA.cancel();
    });

    test('broadcasts a single event to multiple subscribers', () async {
      final first = <TestEventA>[];
      final second = <TestEventA>[];
      final subOne = sut.on<TestEventA>().listen(first.add);
      final subTwo = sut.on<TestEventA>().listen(second.add);

      sut.publish(const TestEventA('broadcast'));
      await Future<void>.delayed(Duration.zero);

      expect(first, hasLength(1));
      expect(second, hasLength(1));
      expect(first.single.payload, equals('broadcast'));
      expect(second.single.payload, equals('broadcast'));
      await subOne.cancel();
      await subTwo.cancel();
    });

    test('events published before subscription are not replayed', () async {
      sut.publish(const TestEventA('before'));
      await Future<void>.delayed(Duration.zero);

      final received = <TestEventA>[];
      final sub = sut.on<TestEventA>().listen(received.add);
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);
      await sub.cancel();
    });

    test('cancelled listeners stop receiving further events', () async {
      final received = <TestEventA>[];
      final sub = sut.on<TestEventA>().listen(received.add);

      sut.publish(const TestEventA('first'));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      sut.publish(const TestEventA('second'));
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single.payload, equals('first'));
    });

    test('publish after dispose is a no-op and does not throw', () async {
      await sut.dispose();

      expect(() => sut.publish(const TestEventA('ignored')), returnsNormally);
    });

    test('dispose signals onDone to existing subscribers', () async {
      final doneCompleter = Completer<void>();
      final sub = sut
          .on<TestEventA>()
          .listen((_) {}, onDone: doneCompleter.complete);

      await sut.dispose();

      await doneCompleter.future.timeout(const Duration(seconds: 1));
      await sub.cancel();
    });

    test(
      'two event types reach only their own subscribers with no crosstalk',
      () async {
        final receivedA = <TestEventA>[];
        final receivedB = <TestEventB>[];
        final subA = sut.on<TestEventA>().listen(receivedA.add);
        final subB = sut.on<TestEventB>().listen(receivedB.add);

        sut
          ..publish(const TestEventA('a1'))
          ..publish(const TestEventB(42))
          ..publish(const TestEventA('a2'));
        await Future<void>.delayed(Duration.zero);

        expect(receivedA.map((e) => e.payload), equals(['a1', 'a2']));
        expect(receivedB.map((e) => e.value), equals([42]));
        await subA.cancel();
        await subB.cancel();
      },
    );

    test('calling dispose twice does not throw', () async {
      await sut.dispose();

      await expectLater(sut.dispose(), completes);
      expect(sut.isDisposed, isTrue);
    });

    test('on<AppEvent>() receives every published event regardless of type',
        () async {
      final received = <AppEvent>[];
      final sub = sut.on<AppEvent>().listen(received.add);

      sut
        ..publish(const TestEventA('a'))
        ..publish(const TestEventB(7));
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(2));
      expect(received[0], isA<TestEventA>());
      expect(received[1], isA<TestEventB>());
      await sub.cancel();
    });
  });
}

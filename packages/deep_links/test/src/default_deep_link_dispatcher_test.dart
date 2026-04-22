import 'dart:async';

import 'package:deep_links/deep_links.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

void main() {
  group('DefaultDeepLinkDispatcher', () {
    late DefaultDeepLinkDispatcher sut;

    setUp(() {
      sut = DefaultDeepLinkDispatcher(
        parser: const DeepLinkParser(
          DeepLinkSchemeConfig(
            allowedHttpsHosts: {'super.app'},
          ),
        ),
      );
    });

    tearDown(() async {
      if (!sut.isDisposed) {
        await sut.dispose();
      }
    });

    test('delivers a parsed link to the matching mini-app subscriber',
        () async {
      final received = <DeepLink>[];
      final sub = sut.linksFor('taxi').listen(received.add);

      sut.submit(Uri.parse('superapp://taxi/ride/42?ref=home'));
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single.miniAppId, equals('taxi'));
      expect(received.single.path, equals('/ride/42'));
      expect(received.single.params, equals({'ref': 'home'}));
      await sub.cancel();
    });

    test('does not cross-talk between mini-apps', () async {
      final taxi = <DeepLink>[];
      final food = <DeepLink>[];
      final subTaxi = sut.linksFor('taxi').listen(taxi.add);
      final subFood = sut.linksFor('food').listen(food.add);

      sut
        ..submit(Uri.parse('superapp://taxi/ride/1'))
        ..submit(Uri.parse('superapp://food/menu'))
        ..submit(Uri.parse('superapp://taxi/ride/2'));
      await Future<void>.delayed(Duration.zero);

      expect(taxi.map((l) => l.path), equals(['/ride/1', '/ride/2']));
      expect(food.map((l) => l.path), equals(['/menu']));
      await subTaxi.cancel();
      await subFood.cancel();
    });

    test('silently drops URIs that the parser rejects', () async {
      final received = <DeepLink>[];
      final sub = sut.linksFor('taxi').listen(received.add);

      sut
        ..submit(Uri.parse('rogue://taxi/ride/1'))
        ..submit(Uri.parse('https://evil.example/taxi/ride/1'))
        ..submit(Uri.parse('superapp://'));
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);
      await sub.cancel();
    });

    test('drops a link when no subscriber is registered for the mini-app',
        () async {
      // Subscribe only to `taxi`, but push a `food` link.
      final taxi = <DeepLink>[];
      final sub = sut.linksFor('taxi').listen(taxi.add);

      sut.submit(Uri.parse('superapp://food/menu'));
      await Future<void>.delayed(Duration.zero);

      expect(taxi, isEmpty);
      await sub.cancel();
    });

    test('broadcasts to multiple subscribers for the same mini-app', () async {
      final first = <DeepLink>[];
      final second = <DeepLink>[];
      final subOne = sut.linksFor('taxi').listen(first.add);
      final subTwo = sut.linksFor('taxi').listen(second.add);

      sut.submit(Uri.parse('superapp://taxi/ride/7'));
      await Future<void>.delayed(Duration.zero);

      expect(first, hasLength(1));
      expect(second, hasLength(1));
      expect(first.single.path, equals('/ride/7'));
      expect(second.single.path, equals('/ride/7'));
      await subOne.cancel();
      await subTwo.cancel();
    });

    test('routes https universal links when the host is whitelisted',
        () async {
      final received = <DeepLink>[];
      final sub = sut.linksFor('taxi').listen(received.add);

      sut.submit(Uri.parse('https://super.app/taxi/ride/42?ref=share'));
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single.path, equals('/ride/42'));
      expect(received.single.params, equals({'ref': 'share'}));
      await sub.cancel();
    });

    test('dispose closes every stream and signals onDone', () async {
      final doneCompleter = Completer<void>();
      final sub =
          sut.linksFor('taxi').listen((_) {}, onDone: doneCompleter.complete);

      await sut.dispose();

      await doneCompleter.future.timeout(const Duration(seconds: 1));
      expect(sut.isDisposed, isTrue);
      await sub.cancel();
    });

    test('submit after dispose is a no-op', () async {
      await sut.dispose();

      expect(
        () => sut.submit(Uri.parse('superapp://taxi/ride/1')),
        returnsNormally,
      );
    });

    test('calling dispose twice is idempotent', () async {
      await sut.dispose();

      await expectLater(sut.dispose(), completes);
      expect(sut.isDisposed, isTrue);
    });
  });
}

import 'package:deep_links/deep_links.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

void main() {
  group('DeepLinkParser', () {
    group('custom scheme', () {
      late DeepLinkParser sut;

      setUp(() {
        sut = const DeepLinkParser(DeepLinkSchemeConfig());
      });

      test('parses superapp://taxi/ride/42?ref=home into a DeepLink', () {
        final uri = Uri.parse('superapp://taxi/ride/42?ref=home');

        final link = sut.parse(uri);

        expect(link, isNotNull);
        expect(link, isA<DeepLink>());
        expect(link?.miniAppId, equals('taxi'));
        expect(link?.path, equals('/ride/42'));
        expect(link?.params, equals({'ref': 'home'}));
        expect(link?.uri, equals(uri));
      });

      test('defaults path to "/" when the URI has no path segments', () {
        final link = sut.parse(Uri.parse('superapp://foo'));

        expect(link, isNotNull);
        expect(link?.miniAppId, equals('foo'));
        expect(link?.path, equals('/'));
        expect(link?.params, isEmpty);
      });

      test('returns null when host is missing', () {
        final link = sut.parse(Uri.parse('superapp://'));

        expect(link, isNull);
      });

      test('returns null for unknown schemes (http, custom)', () {
        expect(sut.parse(Uri.parse('http://taxi/ride/42')), isNull);
        expect(sut.parse(Uri.parse('rogue://taxi/ride/42')), isNull);
      });

      test('returns null when scheme is stripped from config allow-list', () {
        const restricted = DeepLinkParser(
          DeepLinkSchemeConfig(allowedSchemes: {'otherscheme'}),
        );

        expect(restricted.parse(Uri.parse('superapp://taxi/ride')), isNull);
      });

      test('preserves multi-value query parameters via queryParameters', () {
        final link = sut.parse(
          Uri.parse('superapp://delivery/track?id=99&src=push'),
        );

        expect(link?.params, equals({'id': '99', 'src': 'push'}));
      });

      test('returns null for empty URIs', () {
        expect(sut.parse(Uri.parse('')), isNull);
      });
    });

    group('https universal links', () {
      late DeepLinkParser sut;

      setUp(() {
        sut = const DeepLinkParser(
          DeepLinkSchemeConfig(
            allowedHttpsHosts: {'super.app'},
          ),
        );
      });

      test('parses https://super.app/taxi/ride/42?ref=home', () {
        final link = sut.parse(
          Uri.parse('https://super.app/taxi/ride/42?ref=home'),
        );

        expect(link, isNotNull);
        expect(link?.miniAppId, equals('taxi'));
        expect(link?.path, equals('/ride/42'));
        expect(link?.params, equals({'ref': 'home'}));
      });

      test('returns null when the host is not in allowedHttpsHosts', () {
        final link = sut.parse(
          Uri.parse('https://evil.app/taxi/ride/42'),
        );

        expect(link, isNull);
      });

      test('returns null for https://host/ without a mini-app segment', () {
        final link = sut.parse(Uri.parse('https://super.app/'));

        expect(link, isNull);
      });

      test('defaults path to "/" when only the mini-app segment is present',
          () {
        final link = sut.parse(Uri.parse('https://super.app/taxi'));

        expect(link, isNotNull);
        expect(link?.miniAppId, equals('taxi'));
        expect(link?.path, equals('/'));
      });
    });
  });
}

import 'package:feature_flags/feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';

bool _decodeBool(Object? raw) => raw is bool && raw;
int _decodeInt(Object? raw) => raw is int ? raw : 0;

void main() {
  group('TypedFlag', () {
    test('read() resolves through the service', () {
      const flag = TypedFlag<bool>(
        key: 'ui.wallet_tab_enabled',
        fallback: false,
        decode: _decodeBool,
      );
      const service = StaticFeatureFlagService({
        'ui.wallet_tab_enabled': true,
      });
      expect(flag.read(service), isTrue);
    });

    test('returns fallback when the key is absent', () {
      const flag = TypedFlag<int>(
        key: 'payments.limit',
        fallback: 42,
        decode: _decodeInt,
      );
      const service = StaticFeatureFlagService(<String, Object?>{});
      expect(flag.read(service), 42);
    });

    test('returns fallback when decoder throws', () {
      const flag = TypedFlag<int>(
        key: 'payments.limit',
        fallback: -1,
        decode: _throwingInt,
      );
      const service = StaticFeatureFlagService({'payments.limit': 'bad'});
      expect(flag.read(service), -1);
    });

    test('toString exposes the flag key for debugging', () {
      const flag = TypedFlag<bool>(
        key: 'a.b',
        fallback: false,
        decode: _decodeBool,
      );
      expect(flag.toString(), contains('a.b'));
    });
  });
}

int _throwingInt(Object? raw) => throw StateError('boom');

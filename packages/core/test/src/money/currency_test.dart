import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Currency', () {
    test('exposes canonical ISO codes', () {
      expect(Currency.usd.code, 'USD');
      expect(Currency.eur.code, 'EUR');
      expect(Currency.uzs.code, 'UZS');
      expect(Currency.gbp.code, 'GBP');
      expect(Currency.rub.code, 'RUB');
      expect(Currency.kzt.code, 'KZT');
    });

    test('assigns correct decimals', () {
      expect(Currency.usd.decimals, 2);
      expect(Currency.uzs.decimals, 0);
      expect(Currency.eur.decimals, 2);
    });

    test('equality is code-based regardless of symbol', () {
      const a = Currency.usd;
      const b = Currency(code: 'USD', decimals: 2, symbol: r'US$');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different codes are not equal', () {
      expect(Currency.usd, isNot(equals(Currency.eur)));
    });

    test('custom factory creates non-standard currencies', () {
      const points = Currency.custom(
        code: 'XPT',
        decimals: 0,
        symbol: 'pts',
      );
      expect(points.code, 'XPT');
      expect(points.decimals, 0);
      expect(points.symbol, 'pts');
    });

    test('toString exposes code', () {
      expect(Currency.usd.toString(), 'Currency(USD)');
    });
  });
}

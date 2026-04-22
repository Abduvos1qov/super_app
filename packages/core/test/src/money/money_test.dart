import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Money construction', () {
    test('Money.of converts human amount to minor units via decimals', () {
      final usd = Money.of(amount: 10.50, currency: Currency.usd);
      expect(usd.amountMinor, 1050);
      expect(usd.currency, Currency.usd);
    });

    test('Money.of rounds to the nearest minor unit', () {
      final usd = Money.of(amount: 1.005, currency: Currency.usd);
      expect(usd.amountMinor, anyOf(100, 101)); // bankers rounding
    });

    test('Money.uzs uses 0 decimals', () {
      final uzs = Money.uzs(12500);
      expect(uzs.amountMinor, 12500);
      expect(uzs.currency, Currency.uzs);
    });

    test('Money.usd round-trips via Money.of', () {
      final a = Money.usd(10.50);
      final b = Money.of(amount: 10.50, currency: Currency.usd);
      expect(a, equals(b));
    });

    test('Money.fromMinor skips rounding', () {
      const m = Money.fromMinor(amountMinor: 1234, currency: Currency.usd);
      expect(m.amountMinor, 1234);
    });

    test('Money.zero', () {
      final z = Money.zero(Currency.eur);
      expect(z.isZero, isTrue);
      expect(z.amountMinor, 0);
    });
  });

  group('Money arithmetic', () {
    test('addition keeps currency', () {
      final result = Money.usd(2) + Money.usd(3);
      expect(result.amountMinor, 500);
      expect(result.currency, Currency.usd);
    });

    test('subtraction can go negative', () {
      final result = Money.usd(1) - Money.usd(3);
      expect(result.amountMinor, -200);
      expect(result.isNegative, isTrue);
    });

    test('multiplication by scalar rounds to minor unit', () {
      final result = Money.usd(10) * 1.5;
      expect(result.amountMinor, 1500);
    });

    test('multiplication on UZS (0 decimals)', () {
      final result = Money.uzs(10000) * 1.2;
      expect(result.amountMinor, 12000);
    });

    test('comparison operators', () {
      expect(Money.usd(5) < Money.usd(10), isTrue);
      expect(Money.usd(10) <= Money.usd(10), isTrue);
      expect(Money.usd(11) > Money.usd(10), isTrue);
      expect(Money.usd(10) >= Money.usd(10), isTrue);
    });

    test('max and min select by amount', () {
      final a = Money.usd(5);
      final b = Money.usd(10);
      expect(Money.max(a, b), equals(b));
      expect(Money.min(a, b), equals(a));
    });

    test('cross-currency addition throws', () {
      expect(
        () => Money.usd(1) + Money.eur(1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('cross-currency subtraction throws', () {
      expect(
        () => Money.usd(1) - Money.uzs(100),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('cross-currency comparison throws', () {
      expect(
        () => Money.usd(1) < Money.eur(1),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Money.format', () {
    test('formats USD with 2 decimals', () {
      expect(Money.usd(1234.5).format(), r'1 234.50 $');
    });

    test('formats UZS with 0 decimals and symbol suffix', () {
      expect(Money.uzs(12500).format(), '12 500 UZS');
    });

    test('omits symbol when requested', () {
      expect(Money.usd(9.9).format(symbol: false), '9.90');
    });

    test('omits grouping when requested', () {
      expect(
        Money.uzs(1234567).format(grouping: false, symbol: false),
        '1234567',
      );
    });

    test('handles amounts smaller than one major unit', () {
      expect(Money.usd(0.05).format(symbol: false), '0.05');
    });

    test('formats negative values with leading minus', () {
      expect(Money.usd(-1.25).format(symbol: false), '-1.25');
    });

    test('formats zero', () {
      expect(Money.zero(Currency.usd).format(symbol: false), '0.00');
      expect(Money.zero(Currency.uzs).format(symbol: false), '0');
    });

    test('formats custom currency with its own symbol', () {
      const points = Currency.custom(
        code: 'XPT',
        decimals: 0,
        symbol: 'pts',
      );
      final reward = Money.of(amount: 1500, currency: points);
      expect(reward.format(), '1 500 pts');
    });

    test('formats currency with 3 decimals', () {
      const kwd = Currency.custom(
        code: 'KWD',
        decimals: 3,
        symbol: 'د.ك',
      );
      final m = Money.of(amount: 12.345, currency: kwd);
      expect(m.amountMinor, 12345);
      expect(m.format(symbol: false), '12.345');
    });
  });

  group('Money equality and toString', () {
    test('equal values compare equal', () {
      expect(Money.usd(1), equals(Money.usd(1)));
      expect(Money.usd(1).hashCode, equals(Money.usd(1).hashCode));
    });

    test('different currencies are not equal even with same minor units', () {
      const a = Money.fromMinor(amountMinor: 100, currency: Currency.usd);
      const b = Money.fromMinor(amountMinor: 100, currency: Currency.eur);
      expect(a.amountMinor, equals(b.amountMinor));
      expect(a, isNot(equals(b)));
    });

    test('toString exposes minor units and code', () {
      expect(Money.usd(1).toString(), 'Money(100 USD)');
      expect(Money.uzs(500).toString(), 'Money(500 UZS)');
    });
  });
}

import 'package:decimal/decimal.dart';
import 'package:meta/meta.dart';

/// Supported fiat currencies. UZS is the monorepo's primary currency.
enum Currency { uzs, usd }

/// Immutable money value. Arithmetic goes through [Decimal] so rounding is
/// exact — never use `double` for money.
@immutable
class Money {
  const Money._(this.minorUnits, this.currency);

  /// Constructs a UZS amount. `amount` is in whole soum — UZS has no
  /// practical sub-unit, so minor units equal major units.
  factory Money.uzs(int amount) => Money._(BigInt.from(amount), Currency.uzs);

  /// Constructs a USD amount from cents (1 USD == 100 cents).
  factory Money.usdCents(int cents) => Money._(BigInt.from(cents), Currency.usd);

  factory Money.zero(Currency currency) => Money._(BigInt.zero, currency);

  /// The smallest indivisible unit of [currency].
  final BigInt minorUnits;
  final Currency currency;

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money._(minorUnits + other.minorUnits, currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money._(minorUnits - other.minorUnits, currency);
  }

  /// Multiplies by a [Decimal] factor (e.g. surge multiplier). Rounded to the
  /// nearest minor unit (banker's rounding via [Decimal.toBigInt]).
  Money scale(Decimal factor) {
    final product = (Decimal.fromBigInt(minorUnits) * factor).round();
    return Money._(product.toBigInt(), currency);
  }

  bool get isZero => minorUnits == BigInt.zero;
  bool get isNegative => minorUnits < BigInt.zero;

  static Money max(Money a, Money b) {
    a._assertSameCurrency(b);
    return a.minorUnits >= b.minorUnits ? a : b;
  }

  /// Renders the amount with a non-breaking space as thousands separator:
  /// `Money.uzs(12500).formatUzs()` → `12 500 UZS`.
  String formatUzs() {
    assert(currency == Currency.uzs, 'formatUzs called on $currency');
    final digits = minorUnits.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final sign = isNegative ? '-' : '';
    return '$sign$buffer UZS';
  }

  void _assertSameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError('Cannot combine $currency with ${other.currency}');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money && other.minorUnits == minorUnits && other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => 'Money($minorUnits ${currency.name})';
}

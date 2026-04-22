import 'package:core/src/money/currency.dart';
import 'package:decimal/decimal.dart';
import 'package:meta/meta.dart';

/// An immutable monetary value expressed in the minor unit of [currency].
///
/// Arithmetic operations preserve the currency. Cross-currency math throws
/// [ArgumentError] — conversion must go through an explicit exchange rate at
/// the call site. Never back money with `double`; use the [Money.of] factory
/// which rounds to the minor unit via [Decimal].
@immutable
class Money {
  const Money._({required this.amountMinor, required this.currency});

  /// Creates a [Money] value from a human-facing amount (e.g. `10.50`) in the
  /// given [currency]. The amount is converted to the minor unit using the
  /// currency's [Currency.decimals] and banker's rounding.
  factory Money.of({required num amount, required Currency currency}) {
    final factor = _pow10(currency.decimals);
    final scaled = Decimal.parse(amount.toString()) * Decimal.fromInt(factor);
    final minor = scaled.round().toBigInt().toInt();
    return Money._(amountMinor: minor, currency: currency);
  }

  /// Creates a [Money] value directly from its integer minor-unit amount.
  /// Prefer [Money.of] unless you already have minor units (e.g. from an
  /// API response).
  const factory Money.fromMinor({
    required int amountMinor,
    required Currency currency,
  }) = Money._;

  /// Convenience factory for US dollars from a human amount (e.g. `10.50`).
  factory Money.usd(num amount) =>
      Money.of(amount: amount, currency: Currency.usd);

  /// Convenience factory for Uzbekistani som.
  factory Money.uzs(num amount) =>
      Money.of(amount: amount, currency: Currency.uzs);

  /// Convenience factory for euros.
  factory Money.eur(num amount) =>
      Money.of(amount: amount, currency: Currency.eur);

  /// Zero amount in [currency].
  factory Money.zero(Currency currency) =>
      Money._(amountMinor: 0, currency: currency);

  /// The amount in minor units (e.g. cents for USD, whole soum for UZS).
  final int amountMinor;

  /// The currency of this amount.
  final Currency currency;

  bool get isZero => amountMinor == 0;
  bool get isNegative => amountMinor < 0;

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money._(
      amountMinor: amountMinor + other.amountMinor,
      currency: currency,
    );
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money._(
      amountMinor: amountMinor - other.amountMinor,
      currency: currency,
    );
  }

  /// Multiplies the amount by a scalar [multiplier], rounding to the nearest
  /// minor unit (banker's rounding).
  Money operator *(num multiplier) {
    final factor = Decimal.parse(multiplier.toString());
    final product = (Decimal.fromInt(amountMinor) * factor).round();
    return Money._(
      amountMinor: product.toBigInt().toInt(),
      currency: currency,
    );
  }

  bool operator <(Money other) {
    _assertSameCurrency(other);
    return amountMinor < other.amountMinor;
  }

  bool operator <=(Money other) {
    _assertSameCurrency(other);
    return amountMinor <= other.amountMinor;
  }

  bool operator >(Money other) {
    _assertSameCurrency(other);
    return amountMinor > other.amountMinor;
  }

  bool operator >=(Money other) {
    _assertSameCurrency(other);
    return amountMinor >= other.amountMinor;
  }

  /// Returns the larger of [a] and [b]. Both must share the same currency.
  static Money max(Money a, Money b) => a >= b ? a : b;

  /// Returns the smaller of [a] and [b]. Both must share the same currency.
  static Money min(Money a, Money b) => a <= b ? a : b;

  /// Renders the value for display. Uses the currency's [Currency.symbol]
  /// suffix when [symbol] is true, groups whole digits with a non-breaking
  /// space when [grouping] is true, and emits [Currency.decimals] fractional
  /// digits separated by `.`.
  ///
  /// Examples:
  /// - `Money.usd(1234.5).format()` → `1 234.50 $`
  /// - `Money.uzs(12500).format()` → `12 500 UZS`
  /// - `Money.usd(9.9).format(symbol: false, grouping: false)` → `9.90`
  String format({bool symbol = true, bool grouping = true}) {
    final negative = amountMinor < 0;
    final absMinor = negative ? -amountMinor : amountMinor;
    final absStr = absMinor.toString();
    final decimals = currency.decimals;

    final String wholePart;
    final String fractionPart;
    if (decimals == 0) {
      wholePart = absStr;
      fractionPart = '';
    } else if (absStr.length <= decimals) {
      wholePart = '0';
      fractionPart = absStr.padLeft(decimals, '0');
    } else {
      wholePart = absStr.substring(0, absStr.length - decimals);
      fractionPart = absStr.substring(absStr.length - decimals);
    }

    final grouped = grouping ? _groupThousands(wholePart) : wholePart;
    final buffer = StringBuffer();
    if (negative) buffer.write('-');
    buffer.write(grouped);
    if (fractionPart.isNotEmpty) {
      buffer
        ..write('.')
        ..write(fractionPart);
    }
    if (symbol) {
      buffer
        ..write(' ')
        ..write(currency.symbol);
    }
    return buffer.toString();
  }

  void _assertSameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError(
        'Cannot combine ${currency.code} with ${other.currency.code}',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          other.amountMinor == amountMinor &&
          other.currency == currency;

  @override
  int get hashCode => Object.hash(amountMinor, currency);

  @override
  String toString() => 'Money($amountMinor ${currency.code})';
}

String _groupThousands(String digits) {
  if (digits.length <= 3) return digits;
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

int _pow10(int exponent) {
  var result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}

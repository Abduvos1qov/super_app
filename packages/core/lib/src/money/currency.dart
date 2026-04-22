import 'package:meta/meta.dart';

/// An ISO-4217 currency descriptor.
///
/// Currency is an immutable value object — not an enum — so apps can mint
/// custom currencies (loyalty points, in-game tokens) without patching this
/// package. Equality and hashing use [code] only; two instances with the
/// same `code` are considered the same currency regardless of symbol.
@immutable
class Currency {
  /// Creates a currency with an ISO-4217 [code], fractional [decimals]
  /// (e.g. 2 for USD, 0 for UZS), and a display [symbol].
  const Currency({
    required this.code,
    required this.decimals,
    required this.symbol,
  })  : assert(decimals >= 0, 'decimals must be non-negative'),
        assert(code.length > 0, 'code must not be empty');

  /// Creates a non-standard currency. Useful for test doubles, loyalty
  /// points, or currencies outside the static table below.
  const Currency.custom({
    required String code,
    required int decimals,
    required String symbol,
  }) : this(code: code, decimals: decimals, symbol: symbol);

  /// ISO-4217 alphabetic code (e.g. `USD`, `UZS`, `EUR`).
  final String code;

  /// Number of fractional digits in the minor unit (e.g. 2 for cents, 0 for
  /// a currency without sub-units).
  final int decimals;

  /// Display symbol used when formatting a `Money` for this currency
  /// (e.g. `$`, `UZS`, `€`).
  final String symbol;

  /// United States dollar.
  static const usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

  /// Euro.
  static const eur = Currency(code: 'EUR', decimals: 2, symbol: '€');

  /// Pound sterling.
  static const gbp = Currency(code: 'GBP', decimals: 2, symbol: '£');

  /// Russian ruble.
  static const rub = Currency(code: 'RUB', decimals: 2, symbol: '₽');

  /// Kazakhstani tenge.
  static const kzt = Currency(code: 'KZT', decimals: 2, symbol: '₸');

  /// Uzbekistani som. No fractional unit in practice.
  static const uzs = Currency(code: 'UZS', decimals: 0, symbol: 'UZS');

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Currency($code)';
}

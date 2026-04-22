import 'dart:async';

import 'package:core/core.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

/// [PaymentGateway] implementation that delegates every call to an abstract
/// [NetworkGateway] from `mini_app_sdk`.
///
/// This adapter is transport-agnostic: the shell injects a concrete
/// `NetworkGateway` (typically `NetworkGatewayImpl` from the `networking`
/// package) and this class only speaks JSON. Endpoint paths are injectable
/// so the same gateway targets dev, staging and production without code
/// changes.
///
/// The wire format is intentionally simple and documented inline — the SDK
/// data classes ([CheckoutRequest], [PaymentReceipt], [WalletBalance]) do
/// not own JSON mappings to keep them I/O-free, so the mapping lives here.
class RemotePaymentGateway implements PaymentGateway {
  /// Creates a remote gateway.
  ///
  /// [gateway] is the transport. [checkoutPath] and [walletPath] default to
  /// `/payments/checkout` and `/payments/wallet` respectively. The wallet
  /// is polled every [walletPollInterval] (default 30 s); callers that want
  /// push updates can wrap [watchWallet] in their own merge with a
  /// server-sent-events stream.
  RemotePaymentGateway({
    required NetworkGateway gateway,
    this.checkoutPath = '/payments/checkout',
    this.walletPath = '/payments/wallet',
    Duration walletPollInterval = const Duration(seconds: 30),
  })  : _gateway = gateway,
        _pollInterval = walletPollInterval;

  final NetworkGateway _gateway;

  /// POST endpoint consulted for [checkout].
  final String checkoutPath;

  /// GET endpoint consulted for [watchWallet].
  final String walletPath;

  final Duration _pollInterval;

  @override
  Future<Result<PaymentReceipt, AppError>> checkout(
    CheckoutRequest req,
  ) {
    return _gateway.post<PaymentReceipt>(
      checkoutPath,
      body: _checkoutRequestToJson(req),
      decode: _decodeReceipt,
    );
  }

  @override
  Stream<WalletBalance> watchWallet() async* {
    while (true) {
      final result = await _gateway.get<WalletBalance>(
        walletPath,
        decode: _decodeWallet,
      );
      switch (result) {
        case Ok<WalletBalance, AppError>(:final value):
          yield value;
        case Err<WalletBalance, AppError>():
          // Swallow the error — callers that need failure signals should
          // observe the underlying network gateway directly. Polling
          // continues so transient failures self-heal.
          break;
      }
      await Future<void>.delayed(_pollInterval);
    }
  }
}

Map<String, Object?> _checkoutRequestToJson(CheckoutRequest r) =>
    <String, Object?>{
      'miniAppId': r.miniAppId,
      'amount': <String, Object?>{
        'amountMinor': r.amount.amountMinor,
        'currency': r.amount.currency.code,
      },
      'description': r.description,
      if (r.preferredMethod case final PaymentMethodToken token)
        'preferredMethod': token.value,
      if (r.idempotencyKey case final String key) 'idempotencyKey': key,
      'metadata': r.metadata,
    };

PaymentReceipt _decodeReceipt(Object? json) {
  if (json case final Map<String, Object?> map) {
    return PaymentReceipt(
      id: map['id']! as String,
      amount: _decodeMoney(map['amount']),
      method: PaymentMethodToken(map['method']! as String),
      completedAt: DateTime.parse(map['completedAt']! as String).toUtc(),
    );
  }
  throw const FormatException('PaymentReceipt JSON must be an object');
}

WalletBalance _decodeWallet(Object? json) {
  if (json case final Map<String, Object?> map) {
    return WalletBalance(
      available: _decodeMoney(map['available']),
      updatedAt: DateTime.parse(map['updatedAt']! as String).toUtc(),
    );
  }
  throw const FormatException('WalletBalance JSON must be an object');
}

Money _decodeMoney(Object? json) {
  if (json case final Map<String, Object?> map) {
    final code = map['currency']! as String;
    final decimals = map['decimals'] as int?;
    final symbol = map['symbol'] as String?;
    final currency = _knownCurrency(code) ??
        Currency(
          code: code,
          decimals: decimals ?? 2,
          symbol: symbol ?? code,
        );
    return Money.fromMinor(
      amountMinor: (map['amountMinor']! as num).toInt(),
      currency: currency,
    );
  }
  throw const FormatException('Money JSON must be an object');
}

/// Resolves a [Currency] from a wire ISO-4217 code when it matches one of
/// the static constants declared in `core`. Unknown codes fall back to a
/// synthesised [Currency] using wire-supplied `decimals`/`symbol`.
Currency? _knownCurrency(String code) => switch (code) {
      'USD' => Currency.usd,
      'EUR' => Currency.eur,
      'GBP' => Currency.gbp,
      'RUB' => Currency.rub,
      'KZT' => Currency.kzt,
      'UZS' => Currency.uzs,
      _ => null,
    };

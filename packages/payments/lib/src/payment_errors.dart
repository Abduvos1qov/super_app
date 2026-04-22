import 'package:core/core.dart';

/// Message used when a checkout is rejected because the wallet balance is
/// below the requested amount. Callers can pattern-match on the message or
/// on [ValidationError.field] (set to `balance`).
const String insufficientFundsMessage = 'Insufficient wallet balance';

/// Canonical [ValidationError] emitted by the in-memory gateway when a
/// checkout is attempted against an under-funded wallet. Extracted as a
/// helper so tests and consumers can rely on a stable message/field pair.
AppError insufficientFundsError() => const ValidationError(
      message: insufficientFundsMessage,
      field: 'balance',
    );

/// Canonical [ValidationError] emitted when a checkout is attempted with an
/// amount in a currency that does not match the wallet currency. Cross-
/// currency checkouts must convert explicitly at the call site first.
AppError currencyMismatchError({
  required String walletCurrency,
  required String requestCurrency,
}) =>
    ValidationError(
      message: 'Checkout currency $requestCurrency does not match '
          'wallet currency $walletCurrency',
      field: 'amount',
    );

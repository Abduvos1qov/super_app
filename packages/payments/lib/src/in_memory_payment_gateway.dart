import 'dart:async';

import 'package:core/core.dart';
import 'package:meta/meta.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

import 'package:payments/src/payment_errors.dart';

/// Signature for an injectable clock. Returns the current UTC time.
@visibleForTesting
typedef Clock = DateTime Function();

/// Signature for a deterministic receipt-id generator.
typedef ReceiptIdGenerator = String Function();

/// Deterministic, fully in-memory `PaymentGateway` used for development and
/// tests.
///
/// Behaviour:
///
/// * `checkout` debits the wallet when funds are sufficient and emits a
///   fresh `WalletBalance` on the stream returned by `watchWallet`.
/// * `checkout` returns a `ValidationError` (`insufficientFundsMessage`)
///   when the wallet cannot cover the requested amount; the balance is
///   never partially debited.
/// * `checkout` returns a `ValidationError` when the request currency does
///   not match the wallet currency.
/// * Every successful request is appended to `completedCheckouts` so tests
///   can assert on the captured input.
///
/// The gateway uses an injectable [Clock] and [ReceiptIdGenerator] so
/// `PaymentReceipt.completedAt` and `PaymentReceipt.id` are deterministic in
/// tests. Defaults to wall-clock time and an auto-incrementing id.
class InMemoryPaymentGateway implements PaymentGateway {
  /// Creates an in-memory gateway initialised with [initialBalance].
  ///
  /// [clock] defaults to [DateTime.now] (UTC). [idGenerator] defaults to a
  /// monotonically-increasing `rcpt_<n>` sequence starting at 1.
  InMemoryPaymentGateway({
    required WalletBalance initialBalance,
    Clock? clock,
    ReceiptIdGenerator? idGenerator,
  })  : _balance = initialBalance,
        _clock = clock ?? _defaultClock,
        _idGenerator = idGenerator ?? _sequentialGenerator(),
        _balanceController = StreamController<WalletBalance>.broadcast();

  static DateTime _defaultClock() => DateTime.now().toUtc();

  static ReceiptIdGenerator _sequentialGenerator() {
    var n = 0;
    return () {
      n += 1;
      return 'rcpt_$n';
    };
  }

  WalletBalance _balance;
  final Clock _clock;
  final ReceiptIdGenerator _idGenerator;
  final StreamController<WalletBalance> _balanceController;

  /// Every [CheckoutRequest] passed to [checkout] that completed
  /// successfully, in insertion order. Cleared only by disposing the
  /// gateway and creating a new one.
  final List<CheckoutRequest> completedCheckouts = <CheckoutRequest>[];

  /// Current snapshot of the in-memory wallet. Exposed for tests and for
  /// consumers that want a synchronous read without subscribing to the
  /// stream.
  WalletBalance get currentBalance => _balance;

  @override
  Future<Result<PaymentReceipt, AppError>> checkout(
    CheckoutRequest req,
  ) async {
    if (req.amount.currency != _balance.available.currency) {
      return Err<PaymentReceipt, AppError>(
        currencyMismatchError(
          walletCurrency: _balance.available.currency.code,
          requestCurrency: req.amount.currency.code,
        ),
      );
    }

    if (req.amount > _balance.available) {
      return Err<PaymentReceipt, AppError>(insufficientFundsError());
    }

    final now = _clock();
    final receipt = PaymentReceipt(
      id: _idGenerator(),
      amount: req.amount,
      method: req.preferredMethod ??
          const PaymentMethodToken('in_memory_wallet'),
      completedAt: now,
    );

    _balance = WalletBalance(
      available: _balance.available - req.amount,
      updatedAt: now,
    );
    completedCheckouts.add(req);
    _balanceController.add(_balance);

    return Ok<PaymentReceipt, AppError>(receipt);
  }

  @override
  Stream<WalletBalance> watchWallet() async* {
    yield _balance;
    yield* _balanceController.stream;
  }

  /// Test helper: credits [amount] to the wallet and emits a new snapshot.
  /// Throws [ArgumentError] if [amount] is in a different currency.
  void creditBalance(Money amount) {
    if (amount.currency != _balance.available.currency) {
      throw ArgumentError(
        'creditBalance currency ${amount.currency.code} does not match '
        'wallet currency ${_balance.available.currency.code}',
      );
    }
    _balance = WalletBalance(
      available: _balance.available + amount,
      updatedAt: _clock(),
    );
    _balanceController.add(_balance);
  }

  /// Closes the internal broadcast stream. After disposal, [watchWallet]
  /// will emit only the current snapshot and then close.
  Future<void> dispose() => _balanceController.close();
}

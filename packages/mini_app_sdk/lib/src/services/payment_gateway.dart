import 'package:core/core.dart';
import 'package:meta/meta.dart';

/// Opaque identifier for a saved payment method (card, wallet, BNPL plan).
///
/// The raw token shape is a shell-internal concern; mini-apps treat it as an
/// opaque string.
@immutable
class PaymentMethodToken {
  /// Wraps a shell-issued payment method identifier.
  const PaymentMethodToken(this.value);

  /// The opaque token value.
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMethodToken && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'PaymentMethodToken($value)';
}

/// Request describing a single checkout attempt initiated by a mini-app.
@immutable
class CheckoutRequest {
  /// Creates a checkout request.
  const CheckoutRequest({
    required this.miniAppId,
    required this.amount,
    required this.description,
    this.preferredMethod,
    this.idempotencyKey,
    this.metadata = const <String, String>{},
  });

  /// Identifier of the mini-app initiating the checkout.
  final String miniAppId;

  /// Amount to charge.
  final Money amount;

  /// Short human-readable description shown to the user.
  final String description;

  /// Optionally pre-selects a saved payment method.
  final PaymentMethodToken? preferredMethod;

  /// Optional idempotency key. When supplied the shell de-duplicates
  /// concurrent or retried checkouts for the same key.
  final String? idempotencyKey;

  /// Arbitrary string metadata forwarded to the payment processor for
  /// reconciliation. Do not put PII here.
  final Map<String, String> metadata;
}

/// Receipt returned by a successful checkout.
@immutable
class PaymentReceipt {
  /// Creates a receipt.
  const PaymentReceipt({
    required this.id,
    required this.amount,
    required this.method,
    required this.completedAt,
  });

  /// Shell-assigned receipt identifier (also used for refunds).
  final String id;

  /// Final charged amount.
  final Money amount;

  /// Token of the payment method that was charged.
  final PaymentMethodToken method;

  /// UTC timestamp at which the payment was confirmed.
  final DateTime completedAt;
}

/// Snapshot of the user's wallet balance exposed to mini-apps.
@immutable
class WalletBalance {
  /// Creates a wallet balance snapshot.
  const WalletBalance({required this.available, required this.updatedAt});

  /// Funds currently available to spend.
  final Money available;

  /// UTC timestamp at which the snapshot was produced.
  final DateTime updatedAt;
}

/// Shell-side payment facade exposed to mini-apps.
///
/// Mini-apps never talk to payment providers directly; the shell orchestrates
/// checkout UI (method selection, 3-D Secure, biometric confirmation) and
/// returns a typed [Result].
abstract class PaymentGateway {
  /// Runs a checkout flow for [req] and returns a [PaymentReceipt] on
  /// success.
  Future<Result<PaymentReceipt, AppError>> checkout(CheckoutRequest req);

  /// Observes the current wallet balance for the signed-in user.
  Stream<WalletBalance> watchWallet();
}

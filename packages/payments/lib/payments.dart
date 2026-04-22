/// Vendor-agnostic implementations of the `PaymentGateway` contract defined
/// in `mini_app_sdk`.
///
/// Two gateways are shipped out of the box:
///
/// * `InMemoryPaymentGateway` — deterministic fake used for development and
///   tests. Holds a wallet balance and captured checkouts in memory.
/// * `RemotePaymentGateway` — thin adapter over an abstract `NetworkGateway`
///   from `mini_app_sdk`. Endpoint paths are injectable so the same adapter
///   targets dev, staging, and production without code changes.
///
/// Vendor-specific adapters (Click, Payme, Stripe) live in dedicated packages
/// and wrap the same `PaymentGateway` interface.
library;

export 'src/in_memory_payment_gateway.dart';
export 'src/payment_errors.dart';
export 'src/remote_payment_gateway.dart';

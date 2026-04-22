# payments

Vendor-agnostic implementations of the `PaymentGateway` contract defined in
`mini_app_sdk/lib/src/services/payment_gateway.dart`. The shell injects one
of these gateways into `MiniAppContext.payments` so mini-apps talk to a
single stable interface regardless of backend or processor.

## Public surface

- `InMemoryPaymentGateway` — deterministic fake with an in-memory wallet,
  used in dev builds and tests. Exposes `creditBalance`, `currentBalance`,
  `completedCheckouts` for assertions.
- `RemotePaymentGateway` — thin adapter over the abstract `NetworkGateway`
  from `mini_app_sdk`. Endpoint paths (`checkoutPath`, `walletPath`) and
  the wallet poll interval are injectable.
- `insufficientFundsError()`, `currencyMismatchError(...)` — canonical
  `ValidationError` builders used by the in-memory gateway and available
  to other gateways (and tests) that want stable message/field pairs.

## Composition

The shell chooses a gateway based on environment:

- **dev / widget tests / golden tests** → `InMemoryPaymentGateway` with a
  seeded wallet. Fast, offline, deterministic.
- **staging / production** → `RemotePaymentGateway` bound to the shared
  `NetworkGatewayImpl` from `networking`.

The swap happens exactly once at boot; mini-apps never see the difference.

## Vendor adapter roadmap

This package intentionally has **no** vendor SDK dependencies. Future
processor-specific adapters live in their own packages and implement the
same `PaymentGateway` interface:

- `payments_click` — Click (Uzbekistan) native SDK
- `payments_payme` — Payme (Uzbekistan) native SDK
- `payments_stripe` — Stripe (international) native SDK

A composite `RoutingPaymentGateway` can be added later to pick the right
adapter per request (by currency, by user preference, by A/B flag) without
touching mini-app code.

## Strict rules

- **Never store card PAN, CVV, or expiry in any Dart layer.** The payment
  instrument is always a `PaymentMethodToken` issued by the backend or the
  vendor SDK's hosted UI. If you are tempted to add a `cardNumber` field,
  stop and ask.
- No vendor SDK dependencies here (`click_flutter`, `payme_flutter`,
  `stripe_flutter`) — those belong in the adapter packages.
- No direct dependency on `networking`. `RemotePaymentGateway` talks to the
  abstract `NetworkGateway` from `mini_app_sdk` so tests can inject a
  mock without pulling Dio.
- SDK data classes (`CheckoutRequest`, `PaymentReceipt`, `WalletBalance`)
  are intentionally I/O-free and do not own `toJson` / `fromJson`. The JSON
  mapping lives inline in `remote_payment_gateway.dart` — keep it there;
  do not push it back into the SDK.

## Testing

Both gateways are covered by `test/src/*_test.dart`. `RemotePaymentGateway`
uses a `mocktail` `MockNetworkGateway`; the in-memory gateway is tested
against its own observable state. No real sockets, no real clock.

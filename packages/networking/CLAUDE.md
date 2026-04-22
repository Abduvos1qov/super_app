# networking

The transport-layer platform service. Implements `NetworkGateway` from
`mini_app_sdk` on top of a single shared `Dio` instance wired with the stock
interceptor stack (auth, logging, retry).

## Purpose

- Single, well-tested HTTP client for the entire super-app shell.
- The concrete `NetworkGatewayImpl` the shell injects into every mini-app
  via `MiniAppContext`. Mini-apps never import this package; they depend on
  the abstract `NetworkGateway` only.
- All fallible calls return `Result<T, AppError>` — this package never
  throws across its public surface.

## Why `TokenProvider` is abstract

`networking` must not depend on `auth`: the auth package itself needs to
make HTTP calls (sign-in, refresh), so that direction of coupling would
produce a cycle. Instead, networking defines a minimal
`TokenProvider` port. The shell wires a concrete secure-storage-backed
implementation from the auth package at startup.

This keeps networking reusable in tests and in apps that authenticate
differently (e.g. admin_web with web-only SSO).

## Interceptor order

`ApiClient` installs interceptors in a deliberate order:

1. `AuthInterceptor` — attaches the bearer token and invalidates it on 401.
2. `LoggingInterceptor` — logs method, URL, status, and duration via
   `AppLogger` from `core`. Bodies are NOT logged (they frequently contain
   PII or tokens).
3. `RetryInterceptor` — last in the chain so a successful retry does not
   double-log the original failure or re-attach a stale token.

## AppError mapping

`NetworkGatewayImpl` translates every `DioException` into an `AppError`
variant. The full table lives in the class's dartdoc; summary:

- Timeouts / connection errors → `NetworkError`
- 401 / 403 → `AuthError` (kinds: `expiredToken`, `forbidden`)
- Other 4xx → `ValidationError`
- 5xx → `ServerError(statusCode)`
- `cancel` → `UnknownError`
- JSON decode failure → `ValidationError`

## Retry policy

- Only `GET`, `PUT`, `DELETE` (idempotent by HTTP spec).
- Only on network/timeout errors or 5xx responses.
- Max 3 retries with exponential backoff: 100 ms, 200 ms, 400 ms.
- `POST` is never retried automatically. If a vertical needs retryable
  creates, it must supply its own idempotency key and handle retries at the
  repository layer.

## Testing

- Tests inject canned responses via custom `Interceptor`s that short-circuit
  requests without touching the network — no real sockets are opened.
- `RetryInterceptor` accepts an injectable `delay` function so tests run in
  milliseconds of wall time.
- `mocktail` is used for `TokenProvider`.

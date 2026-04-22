# auth

Single sign-on platform for the super-app. Owns session state, OTP-based
authentication, secure token persistence, and the bridge that plugs the
auth package into the networking package without creating a dependency
cycle.

## Public surface

- `DefaultSessionController` — concrete `SessionController` from
  `mini_app_sdk`. Exposes the `SessionState` stream mini-apps subscribe to
  via `MiniAppContext.session`.
- `AuthService` + `OtpAuthService` — OTP flow over `NetworkGateway`.
- `SecureTokenStorage` — typed wrapper around `SecureStorage` keyed at
  `auth.token`.
- `AuthTokenProviderAdapter` — implements networking's `TokenProvider` by
  reading from `SecureTokenStorage` and calling `SessionController.signOut`
  on invalidation.
- `AuthToken` — immutable value object with `isExpired({skew})`.
- `Clock` — injectable time source for deterministic tests.

## Architecture

```
        mini-app ──▶ SessionController (abstract, in mini_app_sdk)
                             ▲
                             │  implements
                             │
              DefaultSessionController
                 │            │
                 ▼            ▼
            AuthService    SecureTokenStorage
                 │            │
                 ▼            ▼
          NetworkGateway   SecureStorage
            (networking)   (storage)
```

Networking only sees `TokenProvider` — the adapter lives here because auth
is the one who knows where tokens are persisted.

## Rules

- Never store profile fields on `AuthToken`. Call `/me` separately.
- Token storage read failures are forced to a `ValidationError` — the shell
  treats that as a tampering signal and clears the entry.
- `requireAuthenticated({min})` compares KYC levels by rank; `KycLevel.unknown`
  fails closed (rank 0).
- `DefaultSessionController` is a small state machine — if you find yourself
  adding flags like `isLoading` on top of `SessionState`, add a new sealed
  subclass instead.

## Bootstrap recipe (shell)

```dart
final secure = FlutterSecureStorageImpl();
final tokenStorage = SecureTokenStorage(secure);

final session = DefaultSessionController(
  authService: OtpAuthService(gateway: gateway),
  tokenStorage: tokenStorage,
);
final tokenProvider = AuthTokenProviderAdapter(
  sessionController: session,
  tokenStorage: tokenStorage,
);

// Now build ApiClient with tokenProvider, then call:
await session.bootstrap();
```

## Testing

Use `InMemorySecureStorage` from the `storage` package. The recording fake
`AuthService` in `test/src/session_controller_impl_test.dart` is the
standard pattern.

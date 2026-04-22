# storage Package

Persistent key-value storage primitives for the super-app shell and mini-apps.

## Purpose

Two layers live here:

1. **`SecureStorage`** (flutter_secure_storage) — tokens, refresh tokens,
   credentials, anything sensitive. Backed by Keychain on iOS and
   EncryptedSharedPreferences on Android.
2. **`PreferencesStorage`** (shared_preferences) — user settings, flags,
   last-selected filters, non-sensitive JSON blobs.

On top of both sits **`StorageScope`** (from `mini_app_sdk`), implemented by
`ScopedStorage` and `ScopedSecureStorage`. Every key is prefixed with the
owning mini-app's ID so one mini-app cannot read another's data. `clear`
only wipes keys within the caller's scope.

## Why scoped

Mini-apps are loaded into the shell as first-class modules. Without a
per-mini-app prefix, a key collision or a malicious lookup would let one
vertical read another's data. `ScopedStorage` enforces the boundary at the
API level: the mini-app never sees raw keys, only its own scope.

## Layers

| API | Backend | Returns | Use case |
|-----|---------|---------|----------|
| `SecureStorage` | Keychain / EncryptedSharedPreferences | `Result<T, AppError>` | Tokens, PII, credentials |
| `PreferencesStorage` | shared_preferences | `Result<T, AppError>` | Settings, flags, JSON |
| `ScopedStorage` | any `PreferencesStorage` | `Result<T, AppError>` | Per-mini-app non-sensitive data |
| `ScopedSecureStorage` | any `SecureStorage` | `Result<T, AppError>` | Per-mini-app sensitive data |

## Rules

- Every operation returns `Result<T, AppError>` — no throwing.
- `SecureStorage` and `PreferencesStorage` are abstract; callers depend on
  the abstraction, the shell wires up the concrete impl.
- `ScopedStorage` / `ScopedSecureStorage` both implement `StorageScope` from
  `mini_app_sdk` so mini-apps see a single uniform interface.
- JSON encoding lives at the scope boundary. `write` accepts any
  JSON-encodable value; `read` takes a `decode` callback. Decode failures
  surface as `ValidationError`, not `UnknownError`, so callers can
  distinguish bad stored data from backend failure.

## Testing

- Use `InMemorySecureStorage` and `InMemoryPreferencesStorage` for unit
  tests. They implement the same interfaces the production code depends on.
- **Never mock `flutter_secure_storage` or `shared_preferences` directly.**
  They require platform channels; mocking them is brittle. The in-memory
  implementations cover the behaviour under test.
- `ScopedStorage` tests should prove: (a) values round-trip, (b) scope A
  cannot read scope B, (c) `clear` only wipes the calling scope.

## Security Notes

- Never store tokens, refresh tokens, OTP secrets, or PII in
  `PreferencesStorage`. They belong in `SecureStorage`.
- Never log the contents of either storage layer — even at trace level.
- Treat a decode-failure on a secure-storage key as a potential tampering
  signal: wipe and force re-auth. The in-memory impl does not simulate
  tamper detection; that is platform-level.

## Dependencies

- `core` (Result, AppError)
- `mini_app_sdk` (StorageScope)
- `flutter_secure_storage`, `shared_preferences`, `meta`

## Out of Scope

- Secrets rotation, device-binding, biometric gating — these are service-
  level concerns that call into this package, not part of it.
- Caching or TTL — add in a purpose-built package if needed.

# shared_services Package

All I/O, all side effects, all external communication. This is where "the outside world" enters the monorepo.

## Purpose

Every network call, every database read/write, every platform-channel call lives here. Apps consume these services via Riverpod providers.

## Contents

```
lib/
├── shared_services.dart          // barrel
├── src/
│   ├── api/
│   │   ├── api_client.dart       // dio + interceptors
│   │   ├── interceptors/
│   │   │   ├── auth_interceptor.dart
│   │   │   ├── logging_interceptor.dart
│   │   │   └── retry_interceptor.dart
│   │   └── api_exception.dart
│   ├── auth/
│   │   ├── auth_service.dart
│   │   └── token_storage.dart
│   ├── trips/
│   │   └── trip_service.dart     // REST + WebSocket
│   ├── location/
│   │   ├── location_service.dart
│   │   └── location_permission_service.dart
│   ├── storage/
│   │   ├── secure_storage.dart
│   │   └── preferences_storage.dart
│   └── push/
│       └── push_service.dart     // FCM
```

## Rules

- **Every service is a class with a narrow, testable interface**:
  ```dart
  abstract class AuthService {
    Future<Result<User, AppError>> signInWithOtp({
      required String phone,
      required String code,
    });
    Future<void> signOut();
    Stream<User?> watchCurrentUser();
  }
  ```
- **Every service returns `Result<T, AppError>` for fallible operations** — never throws to callers
- **Every service exposes a Riverpod provider** in the same file:
  ```dart
  @riverpod
  AuthService authService(AuthServiceRef ref) => AuthServiceImpl(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
  ```
- **Never import from apps**. Services are app-agnostic.
- **Never import `shared_ui`**. Services have zero UI dependencies.
- **Every network call goes through `ApiClient`**, not raw `dio`. This ensures consistent auth, logging, retry.

## ApiClient

Single `Dio` instance with these interceptors in order:

1. `AuthInterceptor` — attaches bearer token, refreshes on 401
2. `LoggingInterceptor` — structured request/response logs (stripped in release)
3. `RetryInterceptor` — exponential backoff for 5xx, idempotent methods only

Base URL, timeouts, and environment come from `core`'s `AppConfig`.

## Testing

- Every service has a unit test with a mocked `ApiClient`
- Use `mocktail` — no codegen
- Test error paths explicitly: network failure, 401, 500, timeout, malformed JSON

## Dependencies

- `dio`
- `flutter_secure_storage`
- `shared_preferences`
- `geolocator`
- `web_socket_channel`
- `firebase_messaging`
- `flutter_riverpod` + `riverpod_annotation`
- `core`
- `shared_models`

## Secrets

- **Never commit API keys, tokens, or URLs.** All secrets come from `--dart-define` at build time, read via `core`'s `AppConfig`.
- `.env` files are `.gitignore`d.

## When to Split

If this package exceeds ~15 service files or ~3000 lines of code, split it:

- `packages/auth`
- `packages/networking`
- `packages/location`
- `packages/push`

This is explicitly called out as future work in `ARCHITECTURE.md §11`.

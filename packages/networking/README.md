# networking

Dio-based `ApiClient` + `NetworkGateway` implementation for the super-app shell.
Ships with auth, logging, and retry interceptors.

## Install

Listed in the root workspace; consume with `networking: any` inside the
monorepo.

## Usage

```dart
import 'package:core/core.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:networking/networking.dart';

class SecureStorageTokenProvider implements TokenProvider {
  // backed by flutter_secure_storage in the auth package
  @override
  Future<String?> currentToken() async => /* ... */;
  @override
  Future<void> invalidate() async => /* ... */;
}

final apiClient = ApiClient(
  baseUrl: 'https://api.super-app.example',
  tokenProvider: SecureStorageTokenProvider(),
);

final NetworkGateway gateway = NetworkGatewayImpl(apiClient);

final Result<User, AppError> user = await gateway.get(
  '/me',
  decode: (json) => User.fromJson(json! as Map<String, Object?>),
);

user.fold(
  onOk: (u) => print('Signed in as ${u.name}'),
  onErr: (e) => print('Failed: ${e.message}'),
);
```

## Rules

- Do NOT import this package from a mini-app. Mini-apps depend only on
  `mini_app_sdk` and consume `NetworkGateway` through `MiniAppContext`.
- Do NOT add auth-specific logic here. Keep the package token-aware but
  auth-agnostic via `TokenProvider`.

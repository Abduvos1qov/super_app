import 'package:networking/networking.dart';

import 'package:auth/src/secure_token_storage.dart';
import 'package:auth/src/session_controller_impl.dart';

/// Bridges [DefaultSessionController] + [SecureTokenStorage] into the
/// networking package's [TokenProvider] port.
///
/// Kept in the auth package so networking stays free of auth imports — this
/// direction of the dependency is fine because the shell is the only
/// consumer that wires both together.
class AuthTokenProviderAdapter implements TokenProvider {
  /// Wires the adapter. [sessionController] is used to clear state on 401;
  /// [tokenStorage] is the source of truth for the current access token.
  AuthTokenProviderAdapter({
    required this.sessionController,
    required this.tokenStorage,
  });

  /// The controller invoked when a 401 forces invalidation.
  final DefaultSessionController sessionController;

  /// The secure-storage-backed token source.
  final SecureTokenStorage tokenStorage;

  @override
  Future<String?> currentToken() async {
    final result = await tokenStorage.read();
    return result.fold(
      onOk: (token) => token?.accessToken,
      onErr: (_) => null,
    );
  }

  @override
  Future<void> invalidate() => sessionController.signOut();
}

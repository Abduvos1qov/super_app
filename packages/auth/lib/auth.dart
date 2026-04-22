/// Single sign-on platform for the super-app shell.
///
/// Owns the [SessionController] implementation, OTP-based authentication
/// service, secure token persistence, and a [TokenProvider] adapter that
/// bridges the auth package into the networking package without creating a
/// dependency cycle.
library;

export 'src/auth_service.dart';
export 'src/auth_token.dart';
export 'src/otp_auth_service.dart';
export 'src/secure_token_storage.dart';
export 'src/session_controller_impl.dart';
export 'src/token_provider_adapter.dart';

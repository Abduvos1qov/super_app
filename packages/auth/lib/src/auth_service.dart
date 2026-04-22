import 'package:core/core.dart';
import 'package:shared_models/shared_models.dart';

import 'package:auth/src/auth_token.dart';

/// Contract implemented by anything that can drive the super-app's OTP
/// authentication flow.
///
/// Concrete implementations (see [OtpAuthService]) translate transport errors
/// into typed [AppError] variants so higher layers never need to catch
/// exceptions. The service is deliberately stateless — the caller (typically
/// [DefaultSessionController]) persists the returned [AuthToken].
abstract class AuthService {
  /// Requests an OTP be delivered to [phone] via SMS or Telegram.
  ///
  /// Returns `Ok(null)` on success. Validation failures from the backend
  /// surface as [ValidationError]; transport failures as [NetworkError].
  Future<Result<void, AppError>> requestOtp(String phone);

  /// Exchanges a successfully-delivered OTP for an [AuthToken].
  ///
  /// A `401` from the backend is mapped to [AuthError] with
  /// [AuthErrorKind.invalidCredentials].
  Future<Result<AuthToken, AppError>> signInWithOtp({
    required String phone,
    required String otp,
  });

  /// Exchanges a refresh token for a new [AuthToken] pair.
  ///
  /// A `401` here means the refresh token itself is no longer valid and the
  /// caller must fall back to a fresh sign-in.
  Future<Result<AuthToken, AppError>> refresh(AuthToken current);

  /// Fetches the authenticated [User] profile. The caller supplies the
  /// current [token]; this method does not read persisted state.
  Future<Result<User, AppError>> currentUser(AuthToken token);
}

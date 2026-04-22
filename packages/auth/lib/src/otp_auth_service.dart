import 'package:core/core.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_models/shared_models.dart';

import 'package:auth/src/auth_service.dart';
import 'package:auth/src/auth_token.dart';

/// Concrete [AuthService] backed by [NetworkGateway].
///
/// All HTTP concerns (timeouts, retries, status → [AppError] mapping) are
/// handled inside the gateway, so this class is a thin adapter that shapes
/// request bodies, decodes responses, and maps a few missing fields to
/// [ValidationError].
class OtpAuthService implements AuthService {
  /// Creates an [OtpAuthService]. Endpoint paths are injectable so deployments
  /// that re-version the auth API can override them without forking.
  OtpAuthService({
    required NetworkGateway gateway,
    this.requestOtpPath = '/auth/otp/request',
    this.verifyOtpPath = '/auth/otp/verify',
    this.refreshPath = '/auth/token/refresh',
    this.meEndpoint = '/me',
  }) : _gateway = gateway;

  final NetworkGateway _gateway;

  /// Backend path that triggers OTP delivery.
  final String requestOtpPath;

  /// Backend path that exchanges an OTP for an [AuthToken].
  final String verifyOtpPath;

  /// Backend path that exchanges a refresh token for a new [AuthToken].
  final String refreshPath;

  /// Backend path that returns the current authenticated [User].
  final String meEndpoint;

  @override
  Future<Result<void, AppError>> requestOtp(String phone) {
    return _gateway.post<void>(
      requestOtpPath,
      body: <String, Object?>{'phone': phone},
      decode: (_) {},
    );
  }

  @override
  Future<Result<AuthToken, AppError>> signInWithOtp({
    required String phone,
    required String otp,
  }) async {
    final result = await _gateway.post<AuthToken>(
      verifyOtpPath,
      body: <String, Object?>{'phone': phone, 'otp': otp},
      decode: _decodeToken,
    );
    return switch (result) {
      Ok<AuthToken, AppError>() => result,
      Err<AuthToken, AppError>(:final error) =>
        Err<AuthToken, AppError>(_mapSignInError(error)),
    };
  }

  @override
  Future<Result<AuthToken, AppError>> refresh(AuthToken current) {
    return _gateway.post<AuthToken>(
      refreshPath,
      body: <String, Object?>{'refreshToken': current.refreshToken},
      decode: _decodeToken,
    );
  }

  @override
  Future<Result<User, AppError>> currentUser(AuthToken token) {
    return _gateway.get<User>(
      meEndpoint,
      headers: <String, String>{'Authorization': 'Bearer ${token.accessToken}'},
      decode: _decodeUser,
    );
  }

  AuthToken _decodeToken(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('Token response must be a JSON object');
    }
    return AuthToken.fromJson(json);
  }

  User _decodeUser(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('/me response must be a JSON object');
    }
    return User.fromJson(json);
  }

  /// Remaps a generic `expiredToken` [AuthError] coming back from the
  /// sign-in endpoint to [AuthErrorKind.invalidCredentials], which is the
  /// semantically correct variant before any session has been established.
  AppError _mapSignInError(AppError error) {
    if (error is AuthError && error.kind == AuthErrorKind.expiredToken) {
      return AuthError(
        message: 'Invalid OTP',
        kind: AuthErrorKind.invalidCredentials,
        cause: error.cause,
      );
    }
    return error;
  }
}

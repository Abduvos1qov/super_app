import 'dart:async';

import 'package:core/core.dart';
import 'package:meta/meta.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_models/shared_models.dart';

import 'package:auth/src/auth_service.dart';
import 'package:auth/src/auth_token.dart';
import 'package:auth/src/secure_token_storage.dart';

/// Injectable clock so [DefaultSessionController] tests can force expiry
/// decisions without waiting for wall-clock time.
@immutable
class Clock {
  const Clock();

  DateTime now() => DateTime.now();
}

/// Default [SessionController] backed by an [AuthService] for I/O and a
/// [SecureTokenStorage] for persistence.
///
/// The controller is a small state machine over [SessionState]:
///
///   Anonymous ──bootstrap(valid)──▶ Authenticated
///   Anonymous ──signInWithOtp────▶ Authenticated
///   Authenticated ──signOut──────▶ Anonymous
///   Any ──refresh fails──────────▶ Anonymous
class DefaultSessionController implements SessionController {
  /// Wires the controller. The shell constructs exactly one instance during
  /// bootstrap and hands it to every [MiniAppContext].
  DefaultSessionController({
    required AuthService authService,
    required SecureTokenStorage tokenStorage,
    Clock clock = const Clock(),
  })  : _auth = authService,
        _tokenStorage = tokenStorage,
        _clock = clock;

  final AuthService _auth;
  final SecureTokenStorage _tokenStorage;
  final Clock _clock;

  final StreamController<SessionState> _stateController =
      StreamController<SessionState>.broadcast();
  SessionState _current = const SessionAnonymous();
  AuthToken? _cachedToken;

  @override
  SessionState get current => _current;

  @override
  Stream<SessionState> watch() async* {
    yield _current;
    yield* _stateController.stream;
  }

  /// Attempts to restore an authenticated session from secure storage. Call
  /// once from the shell bootstrap, before any mini-app starts reading the
  /// session stream.
  Future<SessionState> bootstrap() async {
    _transition(const SessionLoading());
    final tokenResult = await _tokenStorage.read();
    if (tokenResult is Err<AuthToken?, AppError>) {
      await _tokenStorage.clear();
      _cachedToken = null;
      return _transition(const SessionAnonymous());
    }
    final token = (tokenResult as Ok<AuthToken?, AppError>).value;
    if (token == null) {
      _cachedToken = null;
      return _transition(const SessionAnonymous());
    }
    final usable = token.isExpired(now: _clock.now())
        ? await _tryRefresh(token)
        : token;
    if (usable == null) {
      return _transition(const SessionAnonymous());
    }
    return _resolveUser(usable);
  }

  /// Completes the OTP exchange flow and persists the resulting token.
  Future<Result<User, AppError>> signInWithOtp({
    required String phone,
    required String otp,
  }) async {
    _transition(const SessionLoading());
    final tokenResult = await _auth.signInWithOtp(phone: phone, otp: otp);
    return switch (tokenResult) {
      Err<AuthToken, AppError>(:final error) => _failSignIn(error),
      Ok<AuthToken, AppError>(:final value) => await _persistAndResolve(value),
    };
  }

  @override
  Future<Result<User, AppError>> requireAuthenticated({
    KycLevel min = KycLevel.basic,
  }) async {
    final snapshot = _current;
    if (snapshot is! SessionAuthenticated) {
      return const Err<User, AppError>(
        AuthError(
          message: 'Authentication required',
          kind: AuthErrorKind.expiredToken,
        ),
      );
    }
    if (_kycRank(snapshot.user.kycLevel) < _kycRank(min)) {
      return Err<User, AppError>(
        AuthError(
          message: 'KYC level ${snapshot.user.kycLevel.name} is below '
              'required ${min.name}',
          kind: AuthErrorKind.forbidden,
        ),
      );
    }
    return Ok<User, AppError>(snapshot.user);
  }

  @override
  Future<void> signOut() async {
    await _tokenStorage.clear();
    _cachedToken = null;
    _transition(const SessionAnonymous());
  }

  /// Releases the underlying state stream. Call from shell teardown.
  Future<void> dispose() => _stateController.close();

  Future<AuthToken?> _tryRefresh(AuthToken expired) async {
    final refreshed = await _auth.refresh(expired);
    return switch (refreshed) {
      Ok<AuthToken, AppError>(:final value) => value,
      Err<AuthToken, AppError>() => null,
    };
  }

  Future<SessionState> _resolveUser(AuthToken token) async {
    final userResult = await _auth.currentUser(token);
    return switch (userResult) {
      Err<User, AppError>() => _transition(const SessionAnonymous()),
      Ok<User, AppError>(:final value) => _adoptAuthenticated(token, value),
    };
  }

  Future<Result<User, AppError>> _persistAndResolve(AuthToken token) async {
    final writeResult = await _tokenStorage.write(token);
    if (writeResult is Err<void, AppError>) {
      _transition(const SessionAnonymous());
      return Err<User, AppError>(writeResult.error);
    }
    final userResult = await _auth.currentUser(token);
    return switch (userResult) {
      Err<User, AppError>(:final error) => _failSignIn(error),
      Ok<User, AppError>(:final value) => _okAuthenticated(token, value),
    };
  }

  Result<User, AppError> _okAuthenticated(AuthToken token, User user) {
    _adoptAuthenticated(token, user);
    return Ok<User, AppError>(user);
  }

  SessionState _adoptAuthenticated(AuthToken token, User user) {
    _cachedToken = token;
    return _transition(SessionAuthenticated(user));
  }

  Result<User, AppError> _failSignIn(AppError error) {
    _transition(const SessionAnonymous());
    return Err<User, AppError>(error);
  }

  SessionState _transition(SessionState next) {
    _current = next;
    _stateController.add(next);
    return next;
  }

  /// Exposed for the networking [TokenProvider] adapter.
  AuthToken? get cachedToken => _cachedToken;

  static int _kycRank(KycLevel level) => switch (level) {
        KycLevel.none => 0,
        KycLevel.basic => 1,
        KycLevel.verified => 2,
        KycLevel.enhanced => 3,
        KycLevel.unknown => 0,
      };
}

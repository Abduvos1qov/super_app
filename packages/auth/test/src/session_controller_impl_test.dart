import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_models/shared_models.dart';
import 'package:storage/storage.dart';

import 'package:auth/auth.dart';

// ignore: must_be_immutable
class _FakeClock extends Clock {
  _FakeClock(this._now);
  DateTime _now;

  @override
  DateTime now() => _now;

  // ignore: unused_element
  void setTo(DateTime value) => _now = value;
}

class _RecordingAuthService implements AuthService {
  AuthToken? signInResponse;
  AppError? signInError;
  AuthToken? refreshResponse;
  AppError? refreshError;
  User? currentUserResponse;
  AppError? currentUserError;

  int refreshCalls = 0;
  int currentUserCalls = 0;

  @override
  Future<Result<void, AppError>> requestOtp(String phone) async {
    return const Ok<void, AppError>(null);
  }

  @override
  Future<Result<AuthToken, AppError>> signInWithOtp({
    required String phone,
    required String otp,
  }) async {
    if (signInError != null) {
      return Err<AuthToken, AppError>(signInError!);
    }
    return Ok<AuthToken, AppError>(signInResponse!);
  }

  @override
  Future<Result<AuthToken, AppError>> refresh(AuthToken current) async {
    refreshCalls++;
    if (refreshError != null) {
      return Err<AuthToken, AppError>(refreshError!);
    }
    return Ok<AuthToken, AppError>(refreshResponse!);
  }

  @override
  Future<Result<User, AppError>> currentUser(AuthToken token) async {
    currentUserCalls++;
    if (currentUserError != null) {
      return Err<User, AppError>(currentUserError!);
    }
    return Ok<User, AppError>(currentUserResponse!);
  }
}

AuthToken _token({DateTime? expiresAt, String access = 'a', String refresh = 'r'}) =>
    AuthToken(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: expiresAt ?? DateTime.utc(2030, 1, 1),
    );

User _user({KycLevel kyc = KycLevel.basic}) => User(
      id: 'u1',
      phone: '+1555',
      displayName: 'Test User',
      kycLevel: kyc,
    );

void main() {
  group('DefaultSessionController', () {
    late InMemorySecureStorage secure;
    late SecureTokenStorage tokenStorage;
    late _RecordingAuthService auth;
    late _FakeClock clock;
    late DefaultSessionController sut;

    setUp(() {
      secure = InMemorySecureStorage();
      tokenStorage = SecureTokenStorage(secure);
      auth = _RecordingAuthService();
      clock = _FakeClock(DateTime.utc(2026, 1, 1));
      sut = DefaultSessionController(
        authService: auth,
        tokenStorage: tokenStorage,
        clock: clock,
      );
    });

    tearDown(() async {
      await sut.dispose();
    });

    test('starts in Anonymous state', () {
      expect(sut.current, const SessionAnonymous());
    });

    test('bootstrap with empty storage transitions to Anonymous', () async {
      final state = await sut.bootstrap();

      expect(state, const SessionAnonymous());
      expect(auth.currentUserCalls, 0);
      expect(auth.refreshCalls, 0);
    });

    test('bootstrap with valid token transitions to Authenticated', () async {
      final validToken = _token(expiresAt: DateTime.utc(2026, 6, 1));
      await tokenStorage.write(validToken);
      auth.currentUserResponse = _user();

      final state = await sut.bootstrap();

      expect(state, isA<SessionAuthenticated>());
      expect((state as SessionAuthenticated).user.id, 'u1');
      expect(auth.refreshCalls, 0);
    });

    test('bootstrap with expired token refreshes successfully', () async {
      final expired = _token(expiresAt: DateTime.utc(2025, 1, 1));
      await tokenStorage.write(expired);
      auth.refreshResponse = _token(expiresAt: DateTime.utc(2027, 1, 1));
      auth.currentUserResponse = _user();

      final state = await sut.bootstrap();

      expect(auth.refreshCalls, 1);
      expect(state, isA<SessionAuthenticated>());
    });

    test('bootstrap falls back to Anonymous when refresh fails', () async {
      final expired = _token(expiresAt: DateTime.utc(2025, 1, 1));
      await tokenStorage.write(expired);
      auth.refreshError = const AuthError(
        message: 'refresh token no longer valid',
        kind: AuthErrorKind.expiredToken,
      );

      final state = await sut.bootstrap();

      expect(state, const SessionAnonymous());
    });

    test('signInWithOtp success persists token and resolves user', () async {
      auth.signInResponse = _token();
      auth.currentUserResponse = _user();

      final result = await sut.signInWithOtp(phone: '+1555', otp: '1234');

      expect(result, isA<Ok<User, AppError>>());
      expect(sut.current, isA<SessionAuthenticated>());
      final stored = await tokenStorage.read();
      expect(stored.valueOrThrow, isNotNull);
    });

    test('signInWithOtp auth failure surfaces the error and stays Anonymous',
        () async {
      auth.signInError = const AuthError(
        message: 'bad OTP',
        kind: AuthErrorKind.invalidCredentials,
      );

      final result = await sut.signInWithOtp(phone: '+1555', otp: 'bad');

      expect(result, isA<Err<User, AppError>>());
      expect(sut.current, const SessionAnonymous());
    });

    test('signOut clears storage and transitions to Anonymous', () async {
      await tokenStorage.write(_token());
      auth.currentUserResponse = _user();
      await sut.bootstrap();
      expect(sut.current, isA<SessionAuthenticated>());

      await sut.signOut();

      expect(sut.current, const SessionAnonymous());
      final stored = await tokenStorage.read();
      expect(stored.valueOrThrow, isNull);
    });

    test('requireAuthenticated returns AuthError when anonymous', () async {
      final result = await sut.requireAuthenticated();

      expect(result, isA<Err<User, AppError>>());
      final error = (result as Err<User, AppError>).error;
      expect(error, isA<AuthError>());
    });

    test('requireAuthenticated returns user when KYC is sufficient', () async {
      await tokenStorage.write(_token());
      auth.currentUserResponse = _user(kyc: KycLevel.verified);
      await sut.bootstrap();

      final result = await sut.requireAuthenticated(min: KycLevel.basic);

      expect(result, isA<Ok<User, AppError>>());
    });

    test('requireAuthenticated returns forbidden when KYC is too low', () async {
      await tokenStorage.write(_token());
      auth.currentUserResponse = _user(kyc: KycLevel.basic);
      await sut.bootstrap();

      final result = await sut.requireAuthenticated(min: KycLevel.enhanced);

      expect(result, isA<Err<User, AppError>>());
      final error = (result as Err<User, AppError>).error;
      expect(error, isA<AuthError>());
      expect((error as AuthError).kind, AuthErrorKind.forbidden);
    });

    test('watch emits transitions in order', () async {
      final emitted = <SessionState>[];
      final sub = sut.watch().listen(emitted.add);
      await Future<void>.delayed(Duration.zero);

      auth.signInResponse = _token();
      auth.currentUserResponse = _user();
      await sut.signInWithOtp(phone: '+1555', otp: '1234');
      await sut.signOut();
      await Future<void>.delayed(Duration.zero);

      expect(emitted.first, const SessionAnonymous());
      expect(emitted.any((s) => s is SessionLoading), isTrue);
      expect(emitted.any((s) => s is SessionAuthenticated), isTrue);
      expect(emitted.last, const SessionAnonymous());

      await sub.cancel();
    });
  });
}

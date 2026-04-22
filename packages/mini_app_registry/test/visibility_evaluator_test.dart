import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app_registry/mini_app_registry.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_models/shared_models.dart';

/// In-memory [FeatureFlagService] backed by a plain [Map]. Only `boolFlag`
/// is exercised by the evaluator; the other members are unused stubs.
class _FakeFeatureFlagService implements FeatureFlagService {
  _FakeFeatureFlagService([Map<String, bool>? flags])
      : _flags = <String, bool>{...?flags};

  final Map<String, bool> _flags;

  @override
  bool boolFlag(String key, {bool fallback = false}) =>
      _flags[key] ?? fallback;

  @override
  String stringFlag(String key, {String fallback = ''}) =>
      throw UnimplementedError();

  @override
  T jsonFlag<T>(
    String key, {
    required T Function(Object? json) decode,
    required T fallback,
  }) =>
      throw UnimplementedError();

  @override
  Stream<void> changes() => const Stream<void>.empty();
}

User _user({
  Set<AccountRole> roles = const <AccountRole>{AccountRole.consumer},
  KycLevel kyc = KycLevel.none,
}) {
  return User(
    id: 'u1',
    phone: '+998901234567',
    displayName: 'Test User',
    roles: roles,
    kycLevel: kyc,
  );
}

void main() {
  group('VisibilityEvaluator', () {
    late _FakeFeatureFlagService flags;

    setUp(() {
      flags = _FakeFeatureFlagService();
    });

    group('MiniAppVisibility.always', () {
      test('is visible for anonymous sessions', () {
        expect(
          VisibilityEvaluator.isVisible(
            const MiniAppVisibility.always(),
            session: const SessionAnonymous(),
            featureFlags: flags,
          ),
          isTrue,
        );
      });

      test('is visible for authenticated sessions', () {
        expect(
          VisibilityEvaluator.isVisible(
            const MiniAppVisibility.always(),
            session: SessionAuthenticated(_user()),
            featureFlags: flags,
          ),
          isTrue,
        );
      });
    });

    group('MiniAppVisibility.featureFlag', () {
      test('delegates to FeatureFlagService.boolFlag', () {
        flags = _FakeFeatureFlagService({'taxi_v2': true});
        expect(
          VisibilityEvaluator.isVisible(
            const MiniAppVisibility.featureFlag('taxi_v2'),
            session: const SessionAnonymous(),
            featureFlags: flags,
          ),
          isTrue,
        );
      });

      test('is hidden when the flag is off', () {
        flags = _FakeFeatureFlagService({'taxi_v2': false});
        expect(
          VisibilityEvaluator.isVisible(
            const MiniAppVisibility.featureFlag('taxi_v2'),
            session: const SessionAnonymous(),
            featureFlags: flags,
          ),
          isFalse,
        );
      });

      test('is hidden when the flag key is missing (fallback=false)', () {
        expect(
          VisibilityEvaluator.isVisible(
            const MiniAppVisibility.featureFlag('missing_key'),
            session: const SessionAnonymous(),
            featureFlags: flags,
          ),
          isFalse,
        );
      });
    });

    group('MiniAppVisibility.roleBased', () {
      test('is visible when the user holds a required role', () {
        expect(
          VisibilityEvaluator.isVisible(
            const MiniAppVisibility.roleBased(<String>{'consumer'}),
            session: SessionAuthenticated(_user()),
            featureFlags: flags,
          ),
          isTrue,
        );
      });

      test('is hidden when the user has none of the required roles', () {
        expect(
          VisibilityEvaluator.isVisible(
            const MiniAppVisibility.roleBased(<String>{'admin'}),
            session: SessionAuthenticated(_user()),
            featureFlags: flags,
          ),
          isFalse,
        );
      });

      test('is hidden for an anonymous session', () {
        expect(
          VisibilityEvaluator.isVisible(
            const MiniAppVisibility.roleBased(<String>{'consumer'}),
            session: const SessionAnonymous(),
            featureFlags: flags,
          ),
          isFalse,
        );
      });

      test('is hidden for a loading session', () {
        expect(
          VisibilityEvaluator.isVisible(
            const MiniAppVisibility.roleBased(<String>{'consumer'}),
            session: const SessionLoading(),
            featureFlags: flags,
          ),
          isFalse,
        );
      });
    });

    group('MiniAppVisibility.kycRequired', () {
      test('is visible when the user meets the required level', () {
        expect(
          VisibilityEvaluator.isVisible(
            const MiniAppVisibility.kycRequired(KycLevel.verified),
            session: SessionAuthenticated(_user(kyc: KycLevel.verified)),
            featureFlags: flags,
          ),
          isTrue,
        );
      });

      test('is visible when the user exceeds the required level', () {
        expect(
          VisibilityEvaluator.isVisible(
            const MiniAppVisibility.kycRequired(KycLevel.verified),
            session: SessionAuthenticated(_user(kyc: KycLevel.enhanced)),
            featureFlags: flags,
          ),
          isTrue,
        );
      });

      test('is hidden when the user falls below the required level', () {
        expect(
          VisibilityEvaluator.isVisible(
            const MiniAppVisibility.kycRequired(KycLevel.enhanced),
            session: SessionAuthenticated(_user(kyc: KycLevel.basic)),
            featureFlags: flags,
          ),
          isFalse,
        );
      });

      test('requiring KycLevel.none is always visible for any authenticated '
          'user', () {
        expect(
          VisibilityEvaluator.isVisible(
            const MiniAppVisibility.kycRequired(KycLevel.none),
            session: SessionAuthenticated(_user()),
            featureFlags: flags,
          ),
          isTrue,
        );
      });

      test('is hidden for an anonymous session', () {
        expect(
          VisibilityEvaluator.isVisible(
            const MiniAppVisibility.kycRequired(KycLevel.basic),
            session: const SessionAnonymous(),
            featureFlags: flags,
          ),
          isFalse,
        );
      });

      test('treats KycLevel.unknown as rank zero: any non-none requirement '
          'fails closed', () {
        expect(
          VisibilityEvaluator.isVisible(
            const MiniAppVisibility.kycRequired(KycLevel.basic),
            session: SessionAuthenticated(_user(kyc: KycLevel.unknown)),
            featureFlags: flags,
          ),
          isFalse,
        );
      });
    });
  });
}

import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_models/shared_models.dart';

/// Pure evaluator that answers "should this mini-app be visible right now?"
/// against a [MiniAppVisibility] rule, the current [SessionState] and the
/// shell's [FeatureFlagService].
///
/// Kept in its own file so it can be unit-tested exhaustively without
/// building the whole registry.
final class VisibilityEvaluator {
  const VisibilityEvaluator._();

  /// Evaluates [rule] and returns `true` when the mini-app should be shown.
  ///
  /// Pure function — same inputs always yield the same output. Callers are
  /// expected to re-invoke it when the session or feature-flag snapshot
  /// changes.
  static bool isVisible(
    MiniAppVisibility rule, {
    required SessionState session,
    required FeatureFlagService featureFlags,
  }) {
    return switch (rule) {
      MiniAppVisibilityAlways() => true,
      MiniAppVisibilityFeatureFlag(:final key) => featureFlags.boolFlag(key),
      MiniAppVisibilityRoleBased(:final roles) => _hasAnyRole(session, roles),
      MiniAppVisibilityKycRequired(:final level) =>
        _meetsKycLevel(session, level),
    };
  }

  static bool _hasAnyRole(SessionState session, Set<String> required) {
    if (_userOrNull(session) case final User user) {
      final userRoleCodes = user.roles.map((r) => r.name).toSet();
      return required.any(userRoleCodes.contains);
    }
    return false;
  }

  static bool _meetsKycLevel(SessionState session, KycLevel required) {
    if (_userOrNull(session) case final User user) {
      return _kycRank(user.kycLevel) >= _kycRank(required);
    }
    return false;
  }

  static User? _userOrNull(SessionState session) {
    return switch (session) {
      SessionAuthenticated(:final user) => user,
      SessionAnonymous() || SessionLoading() => null,
    };
  }

  /// Ordering of [KycLevel] from least to most verified. `unknown` is treated
  /// as rank 0: any non-zero requirement fails closed, matching the backend
  /// forward-compatibility contract documented on [KycLevel].
  static int _kycRank(KycLevel level) => switch (level) {
        KycLevel.none => 0,
        KycLevel.basic => 1,
        KycLevel.verified => 2,
        KycLevel.enhanced => 3,
        KycLevel.unknown => 0,
      };
}

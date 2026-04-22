import 'package:meta/meta.dart';
import 'package:shared_models/shared_models.dart';

/// Declarative rule describing when a mini-app should appear in the launcher
/// and be routable. The shell evaluates the rule against the current session,
/// remote config and user roles.
@immutable
sealed class MiniAppVisibility {
  const MiniAppVisibility();

  /// Always visible to every session.
  const factory MiniAppVisibility.always() = MiniAppVisibilityAlways;

  /// Visible only when the named remote-config boolean flag is enabled.
  const factory MiniAppVisibility.featureFlag(String key) =
      MiniAppVisibilityFeatureFlag;

  /// Visible only when the authenticated user holds at least one of [roles].
  const factory MiniAppVisibility.roleBased(Set<String> roles) =
      MiniAppVisibilityRoleBased;

  /// Visible only when the user has reached at least [level] KYC.
  const factory MiniAppVisibility.kycRequired(KycLevel level) =
      MiniAppVisibilityKycRequired;
}

/// Always-visible variant of [MiniAppVisibility].
final class MiniAppVisibilityAlways extends MiniAppVisibility {
  /// Creates an always-visible rule.
  const MiniAppVisibilityAlways();

  @override
  bool operator ==(Object other) => other is MiniAppVisibilityAlways;

  @override
  int get hashCode => (MiniAppVisibilityAlways).hashCode;

  @override
  String toString() => 'MiniAppVisibility.always()';
}

/// Feature-flag-gated variant of [MiniAppVisibility].
final class MiniAppVisibilityFeatureFlag extends MiniAppVisibility {
  /// Creates a feature-flag gated rule for [key].
  const MiniAppVisibilityFeatureFlag(this.key);

  /// Feature-flag key evaluated at runtime.
  final String key;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MiniAppVisibilityFeatureFlag && other.key == key;

  @override
  int get hashCode => Object.hash(MiniAppVisibilityFeatureFlag, key);

  @override
  String toString() => 'MiniAppVisibility.featureFlag($key)';
}

/// Role-based variant of [MiniAppVisibility].
final class MiniAppVisibilityRoleBased extends MiniAppVisibility {
  /// Creates a role-based rule unlocked by any of [roles].
  const MiniAppVisibilityRoleBased(this.roles);

  /// Roles that unlock the mini-app. Match is ANY, not ALL.
  final Set<String> roles;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MiniAppVisibilityRoleBased) return false;
    if (other.roles.length != roles.length) return false;
    return other.roles.containsAll(roles);
  }

  @override
  int get hashCode => Object.hashAllUnordered(roles);

  @override
  String toString() => 'MiniAppVisibility.roleBased($roles)';
}

/// KYC-gated variant of [MiniAppVisibility].
final class MiniAppVisibilityKycRequired extends MiniAppVisibility {
  /// Creates a KYC-gated rule requiring at least [level].
  const MiniAppVisibilityKycRequired(this.level);

  /// Minimum required KYC level for the mini-app to be visible.
  final KycLevel level;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MiniAppVisibilityKycRequired && other.level == level;

  @override
  int get hashCode => Object.hash(MiniAppVisibilityKycRequired, level);

  @override
  String toString() => 'MiniAppVisibility.kycRequired($level)';
}

import 'package:meta/meta.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

/// Cross-mini-app event published whenever a permission outcome changes.
///
/// The shell fans this out through the [AppEventBus] so features that depend
/// on capabilities (e.g. live tracking) can refresh without coupling to the
/// broker directly.
@immutable
class PermissionOutcomeEvent extends AppEvent {
  /// Creates a permission outcome event.
  const PermissionOutcomeEvent({
    required this.permission,
    required this.status,
    required this.action,
  });

  /// The permission whose state changed.
  final MiniAppPermission permission;

  /// The resulting status as seen by the shell SDK.
  final PermissionStatus status;

  /// Whether the outcome came from a passive [PermissionAction.check] or an
  /// interactive [PermissionAction.request].
  final PermissionAction action;

  @override
  String get topic => 'permissions.outcome';

  @override
  bool operator ==(Object other) =>
      other is PermissionOutcomeEvent &&
      other.permission == permission &&
      other.status == status &&
      other.action == action;

  @override
  int get hashCode => Object.hash(permission, status, action);

  @override
  String toString() =>
      'PermissionOutcomeEvent(permission: $permission, status: $status, '
      'action: $action)';
}

/// Distinguishes the two shapes of interaction with [PermissionBroker].
enum PermissionAction {
  /// Produced by [PermissionBroker.check] — non-interactive status read.
  check,

  /// Produced by [PermissionBroker.request] — user-facing OS prompt flow.
  request,
}

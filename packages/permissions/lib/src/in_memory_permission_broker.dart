import 'package:meta/meta.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

/// A single `request` invocation captured by [InMemoryPermissionBroker].
@immutable
class PermissionRequestLogEntry {
  /// Records one [permission] request with its associated [rationale].
  const PermissionRequestLogEntry(this.permission, this.rationale);

  /// The permission that was requested.
  final MiniAppPermission permission;

  /// The rationale string supplied by the caller.
  final String rationale;

  @override
  bool operator ==(Object other) =>
      other is PermissionRequestLogEntry &&
      other.permission == permission &&
      other.rationale == rationale;

  @override
  int get hashCode => Object.hash(permission, rationale);

  @override
  String toString() => 'PermissionRequestLogEntry('
      'permission: $permission, rationale: $rationale)';
}

/// In-memory [PermissionBroker] used by unit tests and the shell bootstrap
/// fallback when the real plugin is not available (e.g. golden tests).
///
/// Production code MUST NOT depend on this class. Use
/// `DefaultPermissionBroker` from `permission_broker_impl.dart` instead.
@visibleForTesting
class InMemoryPermissionBroker implements PermissionBroker {
  final Map<MiniAppPermission, PermissionStatus> _statuses =
      <MiniAppPermission, PermissionStatus>{};
  final Map<MiniAppPermission, PermissionStatus> _requestResponses =
      <MiniAppPermission, PermissionStatus>{};
  final List<PermissionRequestLogEntry> _requestLog =
      <PermissionRequestLogEntry>[];

  /// Read-only snapshot of every `request` invocation, in call order.
  List<PermissionRequestLogEntry> get requestLog =>
      List<PermissionRequestLogEntry>.unmodifiable(_requestLog);

  /// Pre-populates the status reported by [check] for [permission].
  void setStatus(MiniAppPermission permission, PermissionStatus status) {
    _statuses[permission] = status;
  }

  /// Sets the status that [request] will resolve to for [permission]. The
  /// configured response also becomes the new value returned by [check].
  void setRequestResponse(
    MiniAppPermission permission,
    PermissionStatus status,
  ) {
    _requestResponses[permission] = status;
  }

  /// Clears every configured status, response and log entry.
  void reset() {
    _statuses.clear();
    _requestResponses.clear();
    _requestLog.clear();
  }

  @override
  Future<PermissionStatus> check(MiniAppPermission permission) async =>
      _statuses[permission] ?? PermissionStatus.notDetermined;

  @override
  Future<PermissionStatus> request(
    MiniAppPermission permission, {
    required String rationale,
  }) async {
    _requestLog.add(PermissionRequestLogEntry(permission, rationale));
    final response = _requestResponses[permission] ?? PermissionStatus.granted;
    _statuses[permission] = response;
    return response;
  }
}

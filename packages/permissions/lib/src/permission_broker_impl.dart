import 'package:meta/meta.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import 'package:permissions/src/permission_mapper.dart';
import 'package:permissions/src/permission_rationale_presenter.dart';

/// Signature for obtaining a plugin permission's current status. Exposed for
/// testing so the broker can be exercised without binding to real platform
/// channels.
@visibleForTesting
typedef PluginStatusReader = Future<ph.PermissionStatus> Function(
  ph.Permission permission,
);

/// Signature for triggering a plugin permission request. Exposed for testing.
@visibleForTesting
typedef PluginStatusRequester = Future<ph.PermissionStatus> Function(
  ph.Permission permission,
);

/// Default [PermissionBroker] backed by the `permission_handler` plugin.
///
/// Lifecycle of a [request] call:
///
/// 1. Short-circuit app-level permissions (payments, biometrics) as
///    [PermissionStatus.notDetermined] so callers route them through the
///    appropriate service rather than the OS.
/// 2. Read the current status. If already granted or restricted, return
///    early.
/// 3. If permanently denied, defer to the [PermissionRationalePresenter] so
///    the shell can open the system settings. The broker never asks the OS
///    again in that state — the prompt no longer appears.
/// 4. If merely denied and a presenter is wired, show the in-app rationale.
///    If the user declines, surface `denied` without disturbing the OS.
/// 5. Otherwise issue the OS request and map the result.
class DefaultPermissionBroker implements PermissionBroker {
  /// Creates a broker that uses [rationalePresenter] for in-app dialogs.
  ///
  /// [statusReader] and [statusRequester] exist so unit tests can substitute
  /// the plugin without touching platform channels; production callers
  /// should omit them.
  DefaultPermissionBroker({
    PermissionRationalePresenter? rationalePresenter,
    PluginStatusReader? statusReader,
    PluginStatusRequester? statusRequester,
  })  : _rationalePresenter = rationalePresenter,
        _statusReader = statusReader ?? _defaultStatusReader,
        _statusRequester = statusRequester ?? _defaultStatusRequester;

  final PermissionRationalePresenter? _rationalePresenter;
  final PluginStatusReader _statusReader;
  final PluginStatusRequester _statusRequester;

  static Future<ph.PermissionStatus> _defaultStatusReader(
    ph.Permission permission,
  ) =>
      permission.status;

  static Future<ph.PermissionStatus> _defaultStatusRequester(
    ph.Permission permission,
  ) =>
      permission.request();

  @override
  Future<PermissionStatus> check(MiniAppPermission permission) async {
    if (!PermissionMapper.isOsLevel(permission)) {
      return PermissionStatus.notDetermined;
    }
    final pluginPermission = PermissionMapper.toPlugin(permission);
    final status = await _statusReader(pluginPermission);
    return PermissionMapper.fromPlugin(status);
  }

  @override
  Future<PermissionStatus> request(
    MiniAppPermission permission, {
    required String rationale,
  }) async {
    if (!PermissionMapper.isOsLevel(permission)) {
      return PermissionStatus.notDetermined;
    }

    final current = await check(permission);

    if (current == PermissionStatus.granted ||
        current == PermissionStatus.restricted) {
      return current;
    }

    if (current == PermissionStatus.permanentlyDenied) {
      if (_rationalePresenter case final presenter?) {
        await presenter.showPermanentlyDeniedRationale(permission, rationale);
      }
      return current;
    }

    if (current == PermissionStatus.denied) {
      if (_rationalePresenter case final presenter?) {
        final proceed =
            await presenter.showRationaleForRequest(permission, rationale);
        if (!proceed) return current;
      }
    }

    final pluginPermission = PermissionMapper.toPlugin(permission);
    final result = await _statusRequester(pluginPermission);
    return PermissionMapper.fromPlugin(result);
  }
}

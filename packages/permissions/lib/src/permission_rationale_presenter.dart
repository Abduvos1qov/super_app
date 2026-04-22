import 'package:mini_app_sdk/mini_app_sdk.dart';

/// Shell-provided UI hook shown around OS permission prompts.
///
/// The broker calls this presenter on the UX-critical moments:
///
/// * **Before** an OS prompt, to explain why the mini-app needs the
///   capability — platforms require this for sensitive permissions and it
///   materially improves grant rates.
/// * **After** a permanent denial, to surface a "Open settings" affordance
///   because the OS will no longer show its native prompt.
///
/// The concrete implementation lives in the shell (Riverpod / go_router) so
/// this package stays free of any particular navigation stack.
abstract class PermissionRationalePresenter {
  /// Shows a pre-request rationale for [permission] with the supplied
  /// [rationale] copy. Returns `true` if the user chose to proceed with the
  /// OS prompt, `false` if they dismissed the rationale.
  Future<bool> showRationaleForRequest(
    MiniAppPermission permission,
    String rationale,
  );

  /// Shows a "permission permanently denied" explanation with an affordance
  /// to open the OS settings app. Returns once the sheet / dialog has been
  /// dismissed.
  Future<void> showPermanentlyDeniedRationale(
    MiniAppPermission permission,
    String rationale,
  );
}

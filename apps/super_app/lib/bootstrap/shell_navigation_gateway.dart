import 'package:go_router/go_router.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

/// [NavigationGateway] implementation that delegates to the shell's
/// [GoRouter].
///
/// Built per mini-app so [pushWithin] and [pop] operate against the correct
/// mount namespace. [openMiniApp] ignores the owning mini-app and targets
/// `/m/<id>` so any context can cross-navigate. The gateway intentionally
/// stays framework-thin: auth/KYC gates and deep-link parity live in the
/// router's redirect logic, not here.
class ShellNavigationGateway implements NavigationGateway {
  /// Wires the gateway to a [GoRouter] owned by the shell.
  ShellNavigationGateway({
    required GoRouter router,
    required this.miniAppId,
  }) : _router = router;

  final GoRouter _router;

  /// Mini-app this gateway was built for; [pushWithin] prefixes paths with
  /// `/m/<miniAppId>` so relative navigation stays inside the caller's
  /// namespace.
  final String miniAppId;

  @override
  void openMiniApp(
    String id, {
    String? subPath,
    Map<String, String>? params,
  }) {
    final path = _joinPath('/m/$id', subPath);
    _router.push(_withQuery(path, params));
  }

  @override
  void pop() {
    if (_router.canPop()) {
      _router.pop();
    }
  }

  @override
  void pushWithin(String path) {
    final base = '/m/$miniAppId';
    final full = _joinPath(base, path);
    _router.push(full);
  }

  String _joinPath(String base, String? sub) {
    if (sub == null || sub.isEmpty || sub == '/') return base;
    final normalised = sub.startsWith('/') ? sub : '/$sub';
    return '$base$normalised';
  }

  String _withQuery(String path, Map<String, String>? params) {
    if (params == null || params.isEmpty) return path;
    final uri = Uri.parse(path).replace(queryParameters: params);
    return uri.toString();
  }
}

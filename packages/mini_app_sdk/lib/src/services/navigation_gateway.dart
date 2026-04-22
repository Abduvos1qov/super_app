/// Shell-side navigation facade exposed to mini-apps.
///
/// Mini-apps never call `Navigator.of(context).push(...)` or touch the
/// shell's `GoRouter` directly. They request navigation through this gateway
/// so the shell can enforce auth gates, deep-link parity, and back-stack
/// invariants.
abstract class NavigationGateway {
  /// Routes to another mini-app by its manifest [id].
  ///
  /// [subPath] is appended to the target mini-app's mount point.
  /// [params] are forwarded as query parameters.
  void openMiniApp(
    String id, {
    String? subPath,
    Map<String, String>? params,
  });

  /// Pops the top-most route owned by the calling mini-app.
  void pop();

  /// Pushes [path] onto the current mini-app's own navigation stack.
  void pushWithin(String path);
}

import 'package:flutter/widgets.dart';

/// Lightweight, routing-library-agnostic description of a single screen a
/// mini-app contributes to the shell's router.
///
/// The shell converts a list of [MiniAppRoute] into its own router
/// primitives (e.g. `go_router` `GoRoute`). Mini-apps never depend on a
/// specific routing package — they only declare shape here.
@immutable
class MiniAppRoute {
  /// Creates a route descriptor.
  const MiniAppRoute({
    required this.path,
    required this.builder,
    this.name,
    this.children = const <MiniAppRoute>[],
  });

  /// URL path segment relative to the mini-app's mount point. May include
  /// `:param` placeholders that the shell's router understands.
  final String path;

  /// Optional logical name used for type-safe navigation and deep links.
  final String? name;

  /// Builds the screen widget. The second argument is an opaque routing
  /// state object supplied by the host router — mini-apps cast it to the
  /// type they expect (e.g. `GoRouterState`).
  final Widget Function(BuildContext context, Object? state) builder;

  /// Nested routes mounted under [path].
  final List<MiniAppRoute> children;
}

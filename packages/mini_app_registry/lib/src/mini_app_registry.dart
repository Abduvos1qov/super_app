import 'package:meta/meta.dart';
import 'package:mini_app_registry/src/visibility_evaluator.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

/// Immutable collection of [MiniApp]s available to the super-app shell.
///
/// The shell constructs one [MiniAppRegistry] at startup with every mini-app
/// the build ships with. It then calls [allVisible] whenever the session or
/// feature-flag snapshot changes to decide which tiles to render and which
/// routes to mount.
@immutable
class MiniAppRegistry {
  /// Creates a registry backed by the given mini-apps.
  ///
  /// Registration order is preserved by [all] and [allVisible] so the shell
  /// can rely on manifest order for launcher layout.
  const MiniAppRegistry(this._miniApps);

  final List<MiniApp> _miniApps;

  /// Every mini-app the build ships with, regardless of visibility rules.
  ///
  /// The returned list is unmodifiable; mutate the registry by constructing
  /// a new instance.
  List<MiniApp> get all => List.unmodifiable(_miniApps);

  /// Returns the mini-app whose manifest id matches [id], or `null` when no
  /// mini-app with that id is registered.
  MiniApp? byId(String id) {
    for (final app in _miniApps) {
      if (app.manifest.id == id) return app;
    }
    return null;
  }

  /// Returns only the mini-apps that should currently be shown to the user,
  /// after applying each manifest's [MiniAppVisibility] rule against the
  /// provided [session] and [featureFlags].
  ///
  /// Pure function of its inputs: call it again whenever the session state
  /// or feature-flag snapshot changes.
  List<MiniApp> allVisible({
    required SessionState session,
    required FeatureFlagService featureFlags,
  }) {
    return _miniApps
        .where(
          (app) => VisibilityEvaluator.isVisible(
            app.manifest.visibility,
            session: session,
            featureFlags: featureFlags,
          ),
        )
        .toList(growable: false);
  }
}

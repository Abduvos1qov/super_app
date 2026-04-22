import 'package:demo_mini_app/src/presentation/widgets/demo_action_tile.dart';
import 'package:flutter/material.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_ui/shared_ui.dart';

/// Home screen for the reference demo mini-app.
///
/// Each action on this screen exercises a different facade on
/// [MiniAppContext] so other mini-app authors can see the shape of a well-
/// behaved call site.
class DemoHomeScreen extends StatelessWidget {
  /// Creates the demo home screen.
  const DemoHomeScreen({required this.miniAppContext, super.key});

  /// Mini-app context handed in by the shell when it mounts this route.
  ///
  /// Held on the widget rather than pulled from an `InheritedWidget` to keep
  /// this template independent from any specific DI framework.
  final MiniAppContext miniAppContext;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppColors>() ?? AppColors.light();
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Demo')),
      body: ListView(
        padding: EdgeInsets.all(spacing.md),
        children: [
          Text(
            'This is the demo mini-app. It exists to prove the MiniApp '
            'contract end-to-end.',
            style: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: spacing.lg),
          DemoActionTile(
            title: 'Track analytics event',
            subtitle: 'Calls miniAppContext.analytics.track(...)',
            onTap: _onTrackAnalytics,
          ),
          DemoActionTile(
            title: 'Ask for camera permission',
            subtitle: 'Calls miniAppContext.permissions.request(camera)',
            onTap: _onRequestCameraPermission,
          ),
          DemoActionTile(
            title: 'Publish domain event',
            subtitle: 'Calls miniAppContext.events.publish(...)',
            onTap: _onPublishEvent,
          ),
        ],
      ),
    );
  }

  void _onTrackAnalytics() {
    miniAppContext.analytics.track(
      'demo.button.tapped',
      props: const <String, Object?>{'source': 'home'},
    );
  }

  Future<void> _onRequestCameraPermission() async {
    await miniAppContext.permissions.request(
      MiniAppPermission.camera,
      rationale:
          'Demo needs camera to show how permission requests flow through '
          'the shell.',
    );
  }

  void _onPublishEvent() {
    miniAppContext.events.publish(const DemoPingEvent());
  }
}

/// Cross-mini-app event published by [DemoHomeScreen] to demonstrate
/// `MiniAppContext.events`.
///
/// Exposed as a top-level class (not private) so tests and the shell can
/// subscribe to it via `AppEventBus.on<DemoPingEvent>()`.
class DemoPingEvent extends AppEvent {
  /// Creates a [DemoPingEvent].
  const DemoPingEvent();

  @override
  String get topic => 'com.superapp.demo.ping';
}

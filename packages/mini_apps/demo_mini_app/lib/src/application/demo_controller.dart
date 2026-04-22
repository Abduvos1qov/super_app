import 'package:demo_mini_app/src/domain/demo_state.dart';
import 'package:flutter/foundation.dart';

/// Minimal controller that drives [DemoState].
///
/// This mini-app intentionally does NOT depend on Riverpod. A future
/// production mini-app will typically expose an `AsyncNotifier` in the app
/// layer, but we want the demo package to show only what the `mini_app_sdk`
/// contract requires — state management is the mini-app author's call and
/// should not be pinned by the template.
class DemoController extends ChangeNotifier {
  /// Creates a controller seeded with [DemoState.initial].
  DemoController();

  DemoState _state = DemoState.initial;

  /// Current immutable state snapshot.
  DemoState get state => _state;

  /// Increments the tap counter and notifies listeners.
  void registerTap() {
    _state = _state.copyWith(tapCount: _state.tapCount + 1);
    notifyListeners();
  }

  /// Resets the counter back to zero.
  void reset() {
    if (_state.tapCount == 0) return;
    _state = DemoState.initial;
    notifyListeners();
  }
}

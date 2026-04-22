/// Default implementation of the `AppEventBus` contract defined in
/// `mini_app_sdk`.
///
/// Exports a broadcast-stream-backed bus suitable for single-isolate use by
/// the shell. Mini-apps should depend on `mini_app_sdk` (the contract), not
/// on this package directly.
library;

export 'src/stream_event_bus.dart';

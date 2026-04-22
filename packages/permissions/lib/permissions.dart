/// Unified runtime permissions broker wrapping `permission_handler`.
///
/// This package is wired by the shell; mini-apps depend on the
/// `PermissionBroker` abstraction exported from `mini_app_sdk`, never on
/// this package directly.
library;

export 'src/in_memory_permission_broker.dart';
export 'src/permission_broker_impl.dart';
export 'src/permission_event.dart';
export 'src/permission_mapper.dart';
export 'src/permission_rationale_presenter.dart';

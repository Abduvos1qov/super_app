/// Deep-link parsing and dispatch for the super-app shell.
///
/// This package is the default implementation behind the
/// `DeepLinkDispatcher` contract declared in `mini_app_sdk`. It turns
/// platform-delivered URIs (from `app_links`, `uni_links`, custom schemes,
/// or manual injection) into parsed `DeepLink` instances scoped to a single
/// mini-app, and fans them out to the owning mini-app's subscription stream.
///
/// The shell wires the platform link source; this package owns the parsing
/// grammar and the pub/sub plumbing. Mini-apps should depend on
/// `mini_app_sdk` for the `DeepLinkDispatcher` abstraction — they must not
/// import this package directly.
library;

export 'src/deep_link_parser.dart';
export 'src/deep_link_scheme_config.dart';
export 'src/default_deep_link_dispatcher.dart';

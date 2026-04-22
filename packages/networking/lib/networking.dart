/// Dio-based ApiClient, NetworkGateway implementation, and stock HTTP
/// interceptors (auth, logging, retry). This package is the single
/// transport-layer implementation for the super-app shell — mini-apps never
/// import it directly; they consume `NetworkGateway` via `MiniAppContext`.
library;

export 'src/api_client.dart';
export 'src/interceptors/auth_interceptor.dart';
export 'src/interceptors/logging_interceptor.dart';
export 'src/interceptors/retry_interceptor.dart';
export 'src/network_gateway_impl.dart';
export 'src/token_provider.dart';

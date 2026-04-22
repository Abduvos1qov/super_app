import 'package:meta/meta.dart';

/// Configuration that controls which URI schemes and HTTPS hosts the deep
/// link parser accepts.
///
/// The default configuration recognises the custom `superapp://` scheme only.
/// Production builds that use Universal Links (iOS) or App Links (Android)
/// should extend [allowedHttpsHosts] with the app's verified domains.
@immutable
class DeepLinkSchemeConfig {
  /// Creates a scheme configuration.
  ///
  /// [allowedSchemes] limits which custom URI schemes the parser accepts
  /// (e.g. `{'superapp'}`). Schemes not in this set are dropped silently.
  ///
  /// [allowedHttpsHosts] lists the HTTPS hostnames that should be treated as
  /// Universal/App Links. An empty set (the default) disables HTTPS routing.
  const DeepLinkSchemeConfig({
    this.allowedSchemes = const {'superapp'},
    this.allowedHttpsHosts = const {},
  });

  /// Custom URI schemes accepted by the parser.
  final Set<String> allowedSchemes;

  /// HTTPS hostnames treated as Universal Links / App Links.
  ///
  /// Requests whose scheme is `https` but whose host is not present here are
  /// rejected by the parser (returns `null`).
  final Set<String> allowedHttpsHosts;
}

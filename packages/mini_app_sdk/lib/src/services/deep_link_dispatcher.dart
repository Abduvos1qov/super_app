// The dispatcher is a platform service interface; even though it currently
// exposes a single method the shell will implement it as a stateful class
// with lifecycle and isolation per mini-app. A top-level function would not
// satisfy that contract.
// ignore_for_file: one_member_abstracts

import 'package:meta/meta.dart';

/// Parsed deep link scoped to a single mini-app.
@immutable
class DeepLink {
  /// Creates a parsed deep link.
  const DeepLink({
    required this.miniAppId,
    required this.uri,
    this.path,
    this.params = const <String, String>{},
  });

  /// Identifier of the target mini-app.
  final String miniAppId;

  /// Original URI (scheme + host + path + query + fragment).
  final Uri uri;

  /// Optional in-app path the shell parsed from [uri] (e.g. `/trip/123`).
  final String? path;

  /// Query parameters flattened into a string map.
  final Map<String, String> params;
}

/// Shell-side deep-link facade exposed to mini-apps.
///
/// The shell centralises deep-link parsing (OS callbacks, universal links,
/// marketing URLs) and fans resolved links out to the owning mini-app.
abstract class DeepLinkDispatcher {
  /// Emits [DeepLink] values targeted at the given [miniAppId].
  Stream<DeepLink> linksFor(String miniAppId);
}

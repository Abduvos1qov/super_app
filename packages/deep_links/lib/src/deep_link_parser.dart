import 'package:deep_links/src/deep_link_scheme_config.dart';
import 'package:meta/meta.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

/// Parses raw [Uri] values into [DeepLink] instances scoped to a single
/// mini-app.
///
/// Grammar:
///
/// * Custom scheme: `superapp://<miniAppId>/<subPath>?<query>`
///   * `scheme` must be present in [DeepLinkSchemeConfig.allowedSchemes].
///   * `host` becomes the target `miniAppId`.
///   * `path` (including the leading slash) becomes the in-app `path`. If the
///     URI has no path, `path` defaults to `/`.
/// * Universal / App Links: `https://<host>/<miniAppId>/<subPath>?<query>`
///   * `host` must be present in [DeepLinkSchemeConfig.allowedHttpsHosts].
///   * The first path segment becomes the target `miniAppId`.
///   * The remaining segments (prefixed with `/`) become the in-app `path`.
///
/// Any URI that does not match these shapes yields `null`. Unknown schemes
/// are silently dropped so a malicious or stray link cannot be routed to an
/// arbitrary mini-app.
@immutable
class DeepLinkParser {
  /// Creates a parser that accepts the schemes/hosts listed in [config].
  const DeepLinkParser(this.config);

  /// Scheme and host allow-list used by [parse].
  final DeepLinkSchemeConfig config;

  /// Returns a [DeepLink] if [uri] matches the configured scheme/host, or
  /// `null` for unknown schemes, missing host, or empty path segments.
  DeepLink? parse(Uri uri) {
    final scheme = uri.scheme;
    if (scheme.isEmpty) {
      return null;
    }
    if (scheme == 'https') {
      return _parseHttps(uri);
    }
    if (config.allowedSchemes.contains(scheme)) {
      return _parseCustomScheme(uri);
    }
    return null;
  }

  DeepLink? _parseCustomScheme(Uri uri) {
    final miniAppId = uri.host;
    if (miniAppId.isEmpty) {
      return null;
    }
    final rawPath = uri.path;
    final path = rawPath.isEmpty ? '/' : rawPath;
    return DeepLink(
      miniAppId: miniAppId,
      uri: uri,
      path: path,
      params: Map<String, String>.unmodifiable(uri.queryParameters),
    );
  }

  DeepLink? _parseHttps(Uri uri) {
    if (!config.allowedHttpsHosts.contains(uri.host)) {
      return null;
    }
    final segments = uri.pathSegments;
    if (segments.isEmpty || segments.first.isEmpty) {
      return null;
    }
    final miniAppId = segments.first;
    final rest = segments.skip(1).join('/');
    final path = rest.isEmpty ? '/' : '/$rest';
    return DeepLink(
      miniAppId: miniAppId,
      uri: uri,
      path: path,
      params: Map<String, String>.unmodifiable(uri.queryParameters),
    );
  }
}

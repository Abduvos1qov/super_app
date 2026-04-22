/// Abstracts bearer-token retrieval and invalidation so the networking
/// package does not depend on the auth package (which in turn depends on
/// networking for its API calls).
///
/// The shell wires a concrete implementation — typically backed by secure
/// storage — into `AuthInterceptor` when constructing the `ApiClient`.
abstract class TokenProvider {
  /// Returns the active bearer token, or `null` when the user is signed out.
  ///
  /// The interceptor treats `null` and the empty string identically: no
  /// `Authorization` header is attached.
  Future<String?> currentToken();

  /// Invalidates the stored token. Called by `AuthInterceptor` on a 401
  /// response so the next request sees a signed-out state instead of
  /// replaying the rejected token.
  Future<void> invalidate();
}

import 'package:core/core.dart';
import 'package:meta/meta.dart';
import 'package:shared_models/shared_models.dart';

/// Snapshot of the authentication state the shell exposes to mini-apps.
@immutable
sealed class SessionState {
  const SessionState();
}

/// No session has been established yet.
final class SessionAnonymous extends SessionState {
  /// Creates an anonymous session marker.
  const SessionAnonymous();

  @override
  bool operator ==(Object other) => other is SessionAnonymous;

  @override
  int get hashCode => (SessionAnonymous).hashCode;
}

/// The session is being refreshed or the user is signing in.
final class SessionLoading extends SessionState {
  /// Creates a loading session marker.
  const SessionLoading();

  @override
  bool operator ==(Object other) => other is SessionLoading;

  @override
  int get hashCode => (SessionLoading).hashCode;
}

/// An authenticated session with a resolved [User].
final class SessionAuthenticated extends SessionState {
  /// Creates an authenticated session snapshot.
  const SessionAuthenticated(this.user);

  /// The currently signed-in user.
  final User user;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionAuthenticated && other.user == user;

  @override
  int get hashCode => Object.hash(SessionAuthenticated, user);
}

/// Shell-side authentication facade exposed to mini-apps.
///
/// Mini-apps never talk to the auth service directly; they observe session
/// state and ask the shell to enforce authentication / KYC preconditions.
abstract class SessionController {
  /// Emits the current [SessionState] and every subsequent change.
  Stream<SessionState> watch();

  /// Returns the current session state synchronously, or `null` if the
  /// controller has not yet initialised.
  SessionState? get current;

  /// Ensures the user is authenticated and at or above [min] KYC level.
  ///
  /// The shell may trigger sign-in or step-up KYC flows as a side effect.
  /// Returns the resolved [User] on success.
  Future<Result<User, AppError>> requireAuthenticated({
    KycLevel min = KycLevel.basic,
  });

  /// Signs the user out and clears session-scoped caches owned by the shell.
  Future<void> signOut();
}

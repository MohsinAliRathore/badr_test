part of 'auth_bloc.dart';

enum AuthStatus { unknown, loading, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    required this.status,
    this.profile,
    this.errorMessage,
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  const AuthState.unauthenticated({String? errorMessage})
      : this(status: AuthStatus.unauthenticated, errorMessage: errorMessage);

  factory AuthState.authenticated(SessionProfile profile) => AuthState(
        status: AuthStatus.authenticated,
        profile: profile,
      );

  final AuthStatus status;
  final SessionProfile? profile;
  final String? errorMessage;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && profile != null;

  AuthState copyWith({
    AuthStatus? status,
    SessionProfile? profile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        profile?.id,
        profile?.role,
        profile?.permissions,
        errorMessage,
      ];
}

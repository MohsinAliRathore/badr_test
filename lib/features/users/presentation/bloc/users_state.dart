part of 'users_bloc.dart';

class UsersState extends Equatable {
  const UsersState({
    this.loading = false,
    this.users = const [],
    this.error,
    this.message,
    this.canCreate = false,
    this.canSetRole = false,
    this.canBan = false,
  });

  final bool loading;
  final List<ApiUser> users;
  final String? error;
  final String? message;
  final bool canCreate;
  final bool canSetRole;
  final bool canBan;

  UsersState copyWith({
    bool? loading,
    List<ApiUser>? users,
    String? error,
    String? message,
    bool? canCreate,
    bool? canSetRole,
    bool? canBan,
    bool clearError = false,
  }) {
    return UsersState(
      loading: loading ?? this.loading,
      users: users ?? this.users,
      error: clearError ? null : (error ?? this.error),
      message: message,
      canCreate: canCreate ?? this.canCreate,
      canSetRole: canSetRole ?? this.canSetRole,
      canBan: canBan ?? this.canBan,
    );
  }

  @override
  List<Object?> get props =>
      [loading, users, error, message, canCreate, canSetRole, canBan];
}

part of 'users_bloc.dart';

sealed class UsersEvent extends Equatable {
  const UsersEvent();
  @override
  List<Object?> get props => [];
}

class UsersStarted extends UsersEvent {
  const UsersStarted();
}

class UsersRefreshRequested extends UsersEvent {
  const UsersRefreshRequested();
}

class UserCreateRequested extends UsersEvent {
  const UserCreateRequested(this.input);
  final CreateUserInput input;
  @override
  List<Object?> get props => [input];
}

class UserUpdateRequested extends UsersEvent {
  const UserUpdateRequested(this.id, this.input);
  final String id;
  final UpdateUserInput input;
  @override
  List<Object?> get props => [id, input];
}

class UserBanRequested extends UsersEvent {
  const UserBanRequested(this.id, this.reason);
  final String id;
  final String reason;
  @override
  List<Object?> get props => [id, reason];
}

class UserUnbanRequested extends UsersEvent {
  const UserUnbanRequested(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

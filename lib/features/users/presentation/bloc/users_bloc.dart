import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/permissions/permission.dart';
import '../../../../generated/openapi_models.dart';
import '../../data/repositories/user_repository_impl.dart';

part 'users_event.dart';
part 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  UsersBloc({
    required UserRepository repository,
    required PermissionSet permissions,
  })  : _repo = repository,
        super(UsersState(
          canCreate: permissions.canCreateUser,
          canSetRole: permissions.canSetUserRole,
          canBan: permissions.canBanUser,
        )) {
    on<UsersStarted>(_onStarted);
    on<UsersRefreshRequested>(_onRefresh);
    on<UserCreateRequested>(_onCreate);
    on<UserUpdateRequested>(_onUpdate);
    on<UserBanRequested>(_onBan);
    on<UserUnbanRequested>(_onUnban);
  }

  final UserRepository _repo;

  Future<void> _onStarted(UsersStarted e, Emitter<UsersState> emit) =>
      _load(emit);

  Future<void> _onRefresh(UsersRefreshRequested e, Emitter<UsersState> emit) =>
      _load(emit);

  Future<void> _load(Emitter<UsersState> emit) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final page = await _repo.list();
      emit(state.copyWith(loading: false, users: page.data));
    } on AppException catch (e) {
      emit(state.copyWith(loading: false, error: e.message));
    }
  }

  Future<void> _onCreate(UserCreateRequested e, Emitter<UsersState> emit) async {
    try {
      await _repo.create(e.input);
      await _load(emit);
      emit(state.copyWith(message: 'User created'));
    } on AppException catch (err) {
      emit(state.copyWith(error: err.message));
    }
  }

  Future<void> _onUpdate(UserUpdateRequested e, Emitter<UsersState> emit) async {
    try {
      await _repo.update(e.id, e.input);
      await _load(emit);
      emit(state.copyWith(message: 'User updated'));
    } on AppException catch (err) {
      emit(state.copyWith(error: err.message));
    }
  }

  Future<void> _onBan(UserBanRequested e, Emitter<UsersState> emit) async {
    try {
      await _repo.ban(e.id, e.reason);
      await _load(emit);
      emit(state.copyWith(message: 'User banned'));
    } on AppException catch (err) {
      emit(state.copyWith(error: err.message));
    }
  }

  Future<void> _onUnban(UserUnbanRequested e, Emitter<UsersState> emit) async {
    try {
      await _repo.unban(e.id);
      await _load(emit);
      emit(state.copyWith(message: 'User unbanned'));
    } on AppException catch (err) {
      emit(state.copyWith(error: err.message));
    }
  }
}

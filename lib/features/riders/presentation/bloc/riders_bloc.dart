import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/permissions/permission.dart';
import '../../../../generated/openapi_models.dart';
import '../../data/repositories/rider_admin_repository.dart';

part 'riders_event.dart';
part 'riders_state.dart';

class RidersBloc extends Bloc<RidersEvent, RidersState> {
  RidersBloc({
    required RiderAdminRepository repository,
    required PermissionSet permissions,
  })  : _repo = repository,
        super(RidersState(
          canCreate: permissions.canCreateRider,
          canUpdate: permissions.canUpdateRider,
        )) {
    on<RidersStarted>(_load);
    on<RidersRefreshRequested>(_load);
    on<RiderCreateRequested>(_onCreate);
    on<RiderUpdateRequested>(_onUpdate);
  }

  final RiderAdminRepository _repo;

  Future<void> _load(RidersEvent event, Emitter<RidersState> emit) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final riders = await _repo.list();
      final cities = await _repo.cities();
      emit(state.copyWith(loading: false, riders: riders, cities: cities));
    } on AppException catch (e) {
      emit(state.copyWith(loading: false, error: e.message));
    }
  }

  Future<void> _onCreate(
    RiderCreateRequested event,
    Emitter<RidersState> emit,
  ) async {
    try {
      await _repo.create(event.input);
      add(const RidersRefreshRequested());
    } on AppException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }

  Future<void> _onUpdate(
    RiderUpdateRequested event,
    Emitter<RidersState> emit,
  ) async {
    try {
      await _repo.update(event.id, event.input);
      add(const RidersRefreshRequested());
    } on AppException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }
}

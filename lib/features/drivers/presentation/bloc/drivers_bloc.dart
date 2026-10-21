import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/permissions/permission.dart';
import '../../../../generated/openapi_models.dart';
import '../../data/repositories/driver_admin_repository.dart';

part 'drivers_event.dart';
part 'drivers_state.dart';

class DriversBloc extends Bloc<DriversEvent, DriversState> {
  DriversBloc({
    required DriverAdminRepository repository,
    required PermissionSet permissions,
  })  : _repo = repository,
        super(DriversState(
          canCreate: permissions.canCreateDriver,
          canUpdate: permissions.canUpdateDriver,
        )) {
    on<DriversStarted>(_load);
    on<DriversRefreshRequested>(_load);
    on<DriverCreateRequested>(_onCreate);
    on<DriverUpdateRequested>(_onUpdate);
  }

  final DriverAdminRepository _repo;

  Future<void> _load(DriversEvent event, Emitter<DriversState> emit) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final drivers = await _repo.list();
      final cities = await _repo.cities();
      emit(state.copyWith(loading: false, drivers: drivers, cities: cities));
    } on AppException catch (e) {
      emit(state.copyWith(loading: false, error: e.message));
    }
  }

  Future<void> _onCreate(
    DriverCreateRequested event,
    Emitter<DriversState> emit,
  ) async {
    try {
      await _repo.create(event.input);
      add(const DriversRefreshRequested());
    } on AppException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }

  Future<void> _onUpdate(
    DriverUpdateRequested event,
    Emitter<DriversState> emit,
  ) async {
    try {
      await _repo.update(event.id, event.input);
      add(const DriversRefreshRequested());
    } on AppException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }
}

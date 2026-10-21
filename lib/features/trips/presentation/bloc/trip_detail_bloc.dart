import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/permissions/permission.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';

part 'trip_detail_event.dart';
part 'trip_detail_state.dart';

class TripDetailBloc extends Bloc<TripDetailEvent, TripDetailState> {
  TripDetailBloc({
    required TripRepository tripRepository,
    required PermissionSet permissions,
  })  : _trips = tripRepository,
        _permissions = permissions,
        super(const TripDetailState()) {
    on<TripDetailLoadRequested>(_onLoad);
    on<TripAssignRequested>(_onAssign);
    on<TripCancelRequested>(_onCancel);
    on<TripRefundRequested>(_onRefund);
    on<TripLoadDriversRequested>(_onLoadDrivers);
  }

  final TripRepository _trips;
  final PermissionSet _permissions;

  Future<void> _onLoad(
    TripDetailLoadRequested event,
    Emitter<TripDetailState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true, notFound: false));
    try {
      final trip = await _trips.getTrip(event.tripId);
      emit(
        state.copyWith(
          loading: false,
          trip: trip,
          canAssign: _permissions.canAssignTrip,
          canCancel: _permissions.canCancelTrip,
          canRefund: _permissions.canRefundTrip,
        ),
      );
    } on AppException catch (e) {
      if (e.isNotFound) {
        emit(state.copyWith(loading: false, notFound: true));
      } else {
        emit(state.copyWith(loading: false, error: e.message));
      }
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadDrivers(
    TripLoadDriversRequested event,
    Emitter<TripDetailState> emit,
  ) async {
    try {
      final drivers = await _trips.availableDrivers();
      emit(state.copyWith(availableDrivers: drivers));
    } on AppException catch (e) {
      emit(state.copyWith(actionError: e.message));
    }
  }

  Future<void> _onAssign(
    TripAssignRequested event,
    Emitter<TripDetailState> emit,
  ) async {
    emit(state.copyWith(actionBusy: true, clearActionError: true));
    try {
      final trip = await _trips.assignDriver(
        tripId: event.tripId,
        driverId: event.driverId,
      );
      emit(state.copyWith(actionBusy: false, trip: trip, actionSuccess: 'Driver assigned'));
    } on AppException catch (e) {
      emit(state.copyWith(actionBusy: false, actionError: _friendly(e)));
    }
  }

  Future<void> _onCancel(
    TripCancelRequested event,
    Emitter<TripDetailState> emit,
  ) async {
    emit(state.copyWith(actionBusy: true, clearActionError: true));
    try {
      final trip = await _trips.cancelTrip(
        tripId: event.tripId,
        reason: event.reason,
      );
      emit(state.copyWith(actionBusy: false, trip: trip, actionSuccess: 'Trip cancelled'));
    } on AppException catch (e) {
      emit(state.copyWith(actionBusy: false, actionError: _friendly(e)));
    }
  }

  Future<void> _onRefund(
    TripRefundRequested event,
    Emitter<TripDetailState> emit,
  ) async {
    emit(state.copyWith(actionBusy: true, clearActionError: true));
    try {
      final trip = await _trips.refundTrip(
        tripId: event.tripId,
        amount: event.amount,
        reason: event.reason,
      );
      emit(state.copyWith(actionBusy: false, trip: trip, actionSuccess: 'Refund issued'));
    } on AppException catch (e) {
      emit(state.copyWith(actionBusy: false, actionError: _friendly(e)));
    }
  }

  String _friendly(AppException e) {
    if (e.isInvalidState) {
      return 'This trip changed while you were working on it. ${e.message}';
    }
    if (e.isValidation) return e.message;
    return e.message;
  }
}

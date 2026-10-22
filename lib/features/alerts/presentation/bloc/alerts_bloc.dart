import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/sse_client.dart';
import '../../../../core/permissions/permission.dart';
import '../../../realtime/data/realtime_hub.dart';
import '../../data/models/alert_mapper.dart';
import '../../domain/entities/alert.dart';
import '../../domain/repositories/alert_repository.dart';

part 'alerts_event.dart';
part 'alerts_state.dart';

class AlertsBloc extends Bloc<AlertsEvent, AlertsState> {
  AlertsBloc({
    required AlertRepository alertRepository,
    required RealtimeHub realtimeHub,
    required PermissionSet permissions,
  })  : _alerts = alertRepository,
        _hub = realtimeHub,
        _permissions = permissions,
        super(AlertsState(canAcknowledge: permissions.canAcknowledgeAlert)) {
    on<AlertsStarted>(_onStarted);
    on<AlertsSseReceived>(_onSse);
    on<AlertAcknowledgeRequested>(_onAcknowledge);
    on<AlertCriticalDismissed>(_onDismissCritical);
    on<AlertsRefreshRequested>(_onRefresh);
  }

  final AlertRepository _alerts;
  final RealtimeHub _hub;
  final PermissionSet _permissions;
  StreamSubscription<SseEvent>? _sseSub;

  Future<void> _onStarted(
    AlertsStarted event,
    Emitter<AlertsState> emit,
  ) async {
    _sseSub ??= _hub.sseEvents.listen((e) {
      if (e.type == 'alert.created' || e.type == 'alert.acknowledged') {
        add(AlertsSseReceived(type: e.type, data: e.data));
      }
    });
    await _load(emit);
  }

  Future<void> _onRefresh(
    AlertsRefreshRequested event,
    Emitter<AlertsState> emit,
  ) =>
      _load(emit);

  Future<void> _load(Emitter<AlertsState> emit) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final items = await _alerts.listAlerts();
      emit(
        state.copyWith(
          loading: false,
          alerts: items,
          canAcknowledge: _permissions.canAcknowledgeAlert,
        ),
      );
    } on AppException catch (e) {
      emit(state.copyWith(loading: false, error: e.message));
    }
  }

  void _onSse(AlertsSseReceived event, Emitter<AlertsState> emit) {
    final alert = mapAlertJson(event.data);
    if (event.type == 'alert.created') {
      final next = [alert, ...state.alerts.where((a) => a.id != alert.id)];
      emit(
        state.copyWith(
          alerts: next,
          criticalBanner: alert.isCritical ? alert : state.criticalBanner,
        ),
      );
      return;
    }

    final next = state.alerts.map((a) {
      if (a.id != alert.id) return a;
      return alert;
    }).where((a) => !a.isAcknowledged).toList();
    emit(
      state.copyWith(
        alerts: next,
        criticalBanner:
            state.criticalBanner?.id == alert.id ? null : state.criticalBanner,
      ),
    );
  }

  Future<void> _onAcknowledge(
    AlertAcknowledgeRequested event,
    Emitter<AlertsState> emit,
  ) async {
    try {
      final updated = await _alerts.acknowledge(event.id);
      final next = state.alerts.where((a) => a.id != updated.id).toList();
      emit(
        state.copyWith(
          alerts: next,
          criticalBanner: state.criticalBanner?.id == updated.id
              ? null
              : state.criticalBanner,
        ),
      );
    } on AppException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }

  void _onDismissCritical(
    AlertCriticalDismissed event,
    Emitter<AlertsState> emit,
  ) {
    emit(state.copyWith(clearCritical: true));
  }

  @override
  Future<void> close() {
    _sseSub?.cancel();
    return super.close();
  }
}

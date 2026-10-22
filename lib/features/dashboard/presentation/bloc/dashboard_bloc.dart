import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/sse_client.dart';
import '../../../realtime/data/realtime_hub.dart';
import '../../data/models/kpi_mapper.dart';
import '../../domain/entities/kpi_snapshot.dart';
import '../../domain/repositories/kpi_repository.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required KpiRepository kpiRepository,
    required RealtimeHub realtimeHub,
  })  : _kpiRepository = kpiRepository,
        _hub = realtimeHub,
        super(const DashboardState()) {
    on<DashboardStarted>(_onStarted);
    on<DashboardRangeChanged>(_onRangeChanged);
    on<DashboardSseKpiReceived>(_onSseKpi);
    on<DashboardRefreshRequested>(_onRefresh);
  }

  final KpiRepository _kpiRepository;
  final RealtimeHub _hub;
  StreamSubscription<SseEvent>? _sseSub;

  Future<void> _onStarted(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) async {
    _sseSub ??= _hub.sseEvents.listen((e) {
      if (e.type == 'kpi') add(DashboardSseKpiReceived(e.data));
    });
    await _load(emit, state.range);
  }

  Future<void> _onRangeChanged(
    DashboardRangeChanged event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(range: event.range));
    await _load(emit, event.range);
  }

  Future<void> _onRefresh(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) =>
      _load(emit, state.range);

  void _onSseKpi(
    DashboardSseKpiReceived event,
    Emitter<DashboardState> emit,
  ) {

    final incoming = mapKpiJson(event.data);
    if (state.range == KpiRange.last24h) {
      emit(state.copyWith(snapshot: incoming, live: true, clearError: true));
    }
  }

  Future<void> _load(Emitter<DashboardState> emit, KpiRange range) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final snapshot = await _kpiRepository.fetchKpis(range: range);
      emit(state.copyWith(loading: false, snapshot: snapshot, live: false));
    } on AppException catch (e) {
      emit(state.copyWith(loading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _sseSub?.cancel();
    return super.close();
  }
}

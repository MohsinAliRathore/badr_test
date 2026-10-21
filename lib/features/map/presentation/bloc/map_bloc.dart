import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/graphql_client.dart';
import '../../../../core/network/ws_client.dart';
import '../../../../generated/graphql_operations.dart';
import '../../../realtime/data/realtime_hub.dart';
import '../../domain/entities/live_driver.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc({
    required RealtimeHub realtimeHub,
    required GraphqlClient graphql,
  })  : _hub = realtimeHub,
        _graphql = graphql,
        super(const MapState()) {
    on<MapStarted>(_onStarted);
    on<MapWsFrameReceived>(_onFrame);
    on<MapWsStateChanged>(_onWsState);
    on<MapDriverSelected>(_onSelect);
    on<MapDriverDetailsRequested>(_onDetails);
  }

  final RealtimeHub _hub;
  final GraphqlClient _graphql;
  StreamSubscription<WsFrame>? _wsSub;
  StreamSubscription<WsConnectionState>? _stateSub;

  static const _channel = 'drivers.locations';

  Future<void> _onStarted(MapStarted event, Emitter<MapState> emit) async {
    _hub.ws.subscribe(_channel);
    _wsSub ??= _hub.wsMessages.listen((f) => add(MapWsFrameReceived(f)));
    _stateSub ??= _hub.wsState.listen((s) => add(MapWsStateChanged(s)));
    emit(state.copyWith(connection: _hub.ws.state));
  }

  void _onWsState(MapWsStateChanged event, Emitter<MapState> emit) {
    emit(state.copyWith(connection: event.state));
  }

  void _onFrame(MapWsFrameReceived event, Emitter<MapState> emit) {
    final frame = event.frame;
    if (frame.type != 'drivers.locations') return;
    final list = frame.payload['drivers'] as List<dynamic>? ?? const [];
    final drivers = list
        .whereType<Map<String, dynamic>>()
        .map(LiveDriver.fromJson)
        .toList();
    emit(state.copyWith(drivers: drivers, lastUpdate: DateTime.now().toUtc()));
  }

  void _onSelect(MapDriverSelected event, Emitter<MapState> emit) {
    if (event.driverId.isEmpty) {
      emit(state.copyWith(clearSelected: true, clearDetails: true));
      return;
    }
    LiveDriver? driver;
    for (final d in state.drivers) {
      if (d.id == event.driverId) {
        driver = d;
        break;
      }
    }
    emit(state.copyWith(selected: driver, clearDetails: true));
    if (driver != null) {
      add(MapDriverDetailsRequested(driver.id));
    }
  }

  Future<void> _onDetails(
    MapDriverDetailsRequested event,
    Emitter<MapState> emit,
  ) async {
    try {
      final data = await _graphql.query(
        document: GqlOps.driverDetail,
        variables: {'id': event.driverId},
      );
      emit(state.copyWith(selectedDetails: data['driver'] as Map<String, dynamic>?));
    } catch (_) {
      // details are best-effort
    }
  }

  @override
  Future<void> close() {
    _hub.ws.unsubscribe(_channel);
    _wsSub?.cancel();
    _stateSub?.cancel();
    return super.close();
  }
}

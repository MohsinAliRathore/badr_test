import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/rest_client.dart';
import '../../../../core/network/sse_client.dart';
import '../../../../core/network/ws_client.dart';
import '../../../realtime/data/realtime_hub.dart';

part 'connectivity_event.dart';
part 'connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  ConnectivityBloc({
    required RestClient rest,
    required RealtimeHub realtimeHub,
    Connectivity? connectivity,
  })  : _rest = rest,
        _hub = realtimeHub,
        _connectivity = connectivity ?? Connectivity(),
        super(const ConnectivityState()) {
    on<ConnectivityStarted>(_onStarted);
    on<ConnectivityHealthTick>(_onHealthTick);
    on<ConnectivitySseHint>(_onSseHint);
    on<ConnectivityWsHint>(_onWsHint);
    on<ConnectivityMaintenanceDetected>(_onMaintenance);
    on<ConnectivityOfflineChanged>(_onOffline);
  }

  final RestClient _rest;
  final RealtimeHub _hub;
  final Connectivity _connectivity;
  Timer? _pollTimer;
  int _backoffAttempt = 0;
  StreamSubscription<SseEvent>? _sseSub;
  StreamSubscription<WsConnectionState>? _wsSub;
  StreamSubscription<List<ConnectivityResult>>? _netSub;

  Future<void> _onStarted(
    ConnectivityStarted event,
    Emitter<ConnectivityState> emit,
  ) async {
    _sseSub ??= _hub.sseEvents.listen((e) {
      if (e.type == '_connection') {
        add(ConnectivitySseHint(e.data['state']?.toString() ?? 'error'));
      }
    });
    _wsSub ??= _hub.wsState.listen((s) => add(ConnectivityWsHint(s)));
    _netSub ??= _connectivity.onConnectivityChanged.listen((results) {
      final offline = results.isEmpty ||
          results.every((r) => r == ConnectivityResult.none);
      add(ConnectivityOfflineChanged(offline));
    });
    final current = await _connectivity.checkConnectivity();
    final offline = current.isEmpty ||
        current.every((r) => r == ConnectivityResult.none);
    emit(state.copyWith(offline: offline));
    add(const ConnectivityHealthTick());
  }

  void _onOffline(
    ConnectivityOfflineChanged event,
    Emitter<ConnectivityState> emit,
  ) {
    emit(state.copyWith(offline: event.offline));
    if (!event.offline && !state.maintenance) {
      _hub.restartTransports();
      add(const ConnectivityHealthTick());
    }
  }

  Future<void> _onHealthTick(
    ConnectivityHealthTick event,
    Emitter<ConnectivityState> emit,
  ) async {
    try {
      final response = await _rest.get<Map<String, dynamic>>('/api/health');
      final data = response.data ?? {};
      final ok = data['ok'] == true;
      if (ok) {
        final wasMaintenance = state.maintenance;
        _backoffAttempt = 0;
        emit(state.copyWith(clearMaintenance: true, apiUp: true));
        if (wasMaintenance) {
          _hub.restartTransports();
        }
        _schedulePoll(const Duration(seconds: 20));
      } else {
        add(
          ConnectivityMaintenanceDetected(
            reason: data['reason']?.toString() ?? 'unavailable',
            message: data['message']?.toString() ?? 'API under maintenance',
            since: DateTime.tryParse(data['since']?.toString() ?? ''),
          ),
        );
      }
    } on AppException catch (e) {
      if (e.isMaintenance) {
        final details = e.details;
        String reason = 'unavailable';
        String message = e.message;
        DateTime? since;
        int? retryAfter;
        if (details is Map) {
          reason = details['reason']?.toString() ?? reason;
          message = details['message']?.toString() ?? message;
          since = DateTime.tryParse(details['since']?.toString() ?? '');
          retryAfter = (details['retryAfterSeconds'] as num?)?.toInt();
        }
        add(
          ConnectivityMaintenanceDetected(
            reason: reason,
            message: message,
            since: since,
            retryAfterSeconds: retryAfter,
          ),
        );
      } else {
        emit(state.copyWith(apiUp: false));
        _schedulePoll(_nextBackoff());
      }
    } catch (_) {
      emit(state.copyWith(apiUp: false));
      _schedulePoll(_nextBackoff());
    }
  }

  void _onMaintenance(
    ConnectivityMaintenanceDetected event,
    Emitter<ConnectivityState> emit,
  ) {
    emit(
      state.copyWith(
        maintenance: true,
        apiUp: false,
        maintenanceReason: event.reason,
        maintenanceMessage: event.message,
        maintenanceSince: event.since ?? state.maintenanceSince ?? DateTime.now().toUtc(),
        retryAfterSeconds: event.retryAfterSeconds,
      ),
    );
    _hub.sse.stop();
    _hub.ws.stop();
    final wait = event.retryAfterSeconds != null
        ? Duration(seconds: event.retryAfterSeconds!)
        : _nextBackoff();
    _schedulePoll(wait);
  }

  void _onSseHint(ConnectivitySseHint event, Emitter<ConnectivityState> emit) {
    if (state.maintenance) return;
    emit(state.copyWith(sseHint: event.state != 'open'));
  }

  void _onWsHint(ConnectivityWsHint event, Emitter<ConnectivityState> emit) {
    if (state.maintenance) return;
    final reconnecting = event.state == WsConnectionState.reconnecting ||
        event.state == WsConnectionState.connecting;
    emit(state.copyWith(wsHint: reconnecting));
  }

  Duration _nextBackoff() {
    _backoffAttempt += 1;
    final seconds = min(60, pow(2, min(_backoffAttempt, 5)).toInt());
    return Duration(seconds: seconds);
  }

  void _schedulePoll(Duration delay) {
    _pollTimer?.cancel();
    _pollTimer = Timer(delay, () {
      if (!isClosed) add(const ConnectivityHealthTick());
    });
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    _sseSub?.cancel();
    _wsSub?.cancel();
    _netSub?.cancel();
    return super.close();
  }
}

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/sse_client.dart';
import '../../../realtime/data/realtime_hub.dart';
import '../../data/models/trip_mapper.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';

part 'trips_list_event.dart';
part 'trips_list_state.dart';

class TripsListBloc extends Bloc<TripsListEvent, TripsListState> {
  TripsListBloc({
    required TripRepository tripRepository,
    required RealtimeHub realtimeHub,
  })  : _trips = tripRepository,
        _hub = realtimeHub,
        super(const TripsListState()) {
    on<TripsListStarted>(_onStarted);
    on<TripsFilterChanged>(_onFilterChanged);
    on<TripsLoadMore>(_onLoadMore);
    on<TripsRefreshRequested>(_onRefresh);
    on<TripsSseEventReceived>(_onSse);
  }

  final TripRepository _trips;
  final RealtimeHub _hub;
  StreamSubscription<SseEvent>? _sseSub;

  Future<void> _onStarted(
    TripsListStarted event,
    Emitter<TripsListState> emit,
  ) async {
    _sseSub ??= _hub.sseEvents.listen((e) {
      if (e.type == 'trip.created' || e.type == 'trip.updated') {
        add(TripsSseEventReceived(type: e.type, data: e.data));
      }
    });
    await _reload(emit);
  }

  Future<void> _onFilterChanged(
    TripsFilterChanged event,
    Emitter<TripsListState> emit,
  ) async {
    emit(state.copyWith(filter: event.filter));
    await _reload(emit);
  }

  Future<void> _onRefresh(
    TripsRefreshRequested event,
    Emitter<TripsListState> emit,
  ) =>
      _reload(emit);

  Future<void> _onLoadMore(
    TripsLoadMore event,
    Emitter<TripsListState> emit,
  ) async {
    if (!state.hasNextPage || state.loadingMore || state.loading) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _trips.listTrips(
        filter: state.filter,
        after: state.endCursor,
      );
      emit(
        state.copyWith(
          loadingMore: false,
          trips: [...state.trips, ...page.nodes],
          hasNextPage: page.hasNextPage,
          endCursor: page.endCursor,
          totalCount: page.totalCount,
        ),
      );
    } on AppException catch (e) {
      emit(state.copyWith(loadingMore: false, error: e.message));
    }
  }

  Future<void> _onSse(
    TripsSseEventReceived event,
    Emitter<TripsListState> emit,
  ) async {
    final mapped = mapTripEventPayload(event.data);
    final id = mapped?.id ??
        event.data['id']?.toString() ??
        event.data['tripId']?.toString();
    if (id == null) return;

    if (event.type == 'trip.created') {
      Trip? trip = mapped;
      trip ??= await _safeFetch(id);
      if (trip == null) return;
      if (!_matchesFilter(trip, state.filter)) return;
      final existing = [...state.trips]..removeWhere((t) => t.id == id);
      emit(
        state.copyWith(
          trips: [trip, ...existing],
          highlightNew: {...state.highlightNew, id},
          totalCount: state.totalCount + 1,
        ),
      );
      return;
    }

    // trip.updated
    final index = state.trips.indexWhere((t) => t.id == id);
    Trip? trip = mapped;
    trip ??= await _safeFetch(id);
    if (trip == null) return;

    if (!_matchesFilter(trip, state.filter)) {
      if (index >= 0) {
        final next = [...state.trips]..removeAt(index);
        emit(state.copyWith(trips: next));
      }
      return;
    }

    final next = [...state.trips];
    if (index >= 0) {
      next[index] = trip;
    } else {
      next.insert(0, trip);
    }
    emit(
      state.copyWith(
        trips: next,
        highlightChanged: {...state.highlightChanged, id},
      ),
    );
  }

  Future<Trip?> _safeFetch(String id) async {
    try {
      return await _trips.getTrip(id);
    } catch (_) {
      return null;
    }
  }

  bool _matchesFilter(Trip trip, TripFilter filter) {
    if (filter.statuses != null &&
        filter.statuses!.isNotEmpty &&
        !filter.statuses!.contains(trip.status)) {
      return false;
    }
    final q = filter.search?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      final hay = [
        trip.id,
        trip.rider.name,
        trip.pickup.address,
        trip.dropoff.address,
      ].join(' ').toLowerCase();
      if (!hay.contains(q)) return false;
    }
    return true;
  }

  Future<void> _reload(Emitter<TripsListState> emit) async {
    emit(
      state.copyWith(
        loading: true,
        clearError: true,
        trips: const [],
        highlightNew: const {},
        highlightChanged: const {},
      ),
    );
    try {
      final page = await _trips.listTrips(filter: state.filter);
      emit(
        state.copyWith(
          loading: false,
          trips: page.nodes,
          hasNextPage: page.hasNextPage,
          endCursor: page.endCursor,
          totalCount: page.totalCount,
        ),
      );
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

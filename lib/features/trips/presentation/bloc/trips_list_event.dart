part of 'trips_list_bloc.dart';

sealed class TripsListEvent extends Equatable {
  const TripsListEvent();
  @override
  List<Object?> get props => [];
}

class TripsListStarted extends TripsListEvent {
  const TripsListStarted();
}

class TripsFilterChanged extends TripsListEvent {
  const TripsFilterChanged(this.filter);
  final TripFilter filter;
  @override
  List<Object?> get props => [filter];
}

class TripsLoadMore extends TripsListEvent {
  const TripsLoadMore();
}

class TripsRefreshRequested extends TripsListEvent {
  const TripsRefreshRequested();
}

class TripsSseEventReceived extends TripsListEvent {
  const TripsSseEventReceived({required this.type, required this.data});
  final String type;
  final Map<String, dynamic> data;
  @override
  List<Object?> get props => [type, data];
}

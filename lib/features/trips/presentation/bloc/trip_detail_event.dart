part of 'trip_detail_bloc.dart';

sealed class TripDetailEvent extends Equatable {
  const TripDetailEvent();
  @override
  List<Object?> get props => [];
}

class TripDetailLoadRequested extends TripDetailEvent {
  const TripDetailLoadRequested(this.tripId);
  final String tripId;
  @override
  List<Object?> get props => [tripId];
}

class TripLoadDriversRequested extends TripDetailEvent {
  const TripLoadDriversRequested();
}

class TripAssignRequested extends TripDetailEvent {
  const TripAssignRequested({required this.tripId, required this.driverId});
  final String tripId;
  final String driverId;
  @override
  List<Object?> get props => [tripId, driverId];
}

class TripCancelRequested extends TripDetailEvent {
  const TripCancelRequested({required this.tripId, required this.reason});
  final String tripId;
  final String reason;
  @override
  List<Object?> get props => [tripId, reason];
}

class TripRefundRequested extends TripDetailEvent {
  const TripRefundRequested({
    required this.tripId,
    required this.amount,
    required this.reason,
  });
  final String tripId;
  final double amount;
  final String reason;
  @override
  List<Object?> get props => [tripId, amount, reason];
}

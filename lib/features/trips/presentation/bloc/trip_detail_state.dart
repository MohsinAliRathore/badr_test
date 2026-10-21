part of 'trip_detail_bloc.dart';

class TripDetailState extends Equatable {
  const TripDetailState({
    this.loading = false,
    this.trip,
    this.error,
    this.notFound = false,
    this.canAssign = false,
    this.canCancel = false,
    this.canRefund = false,
    this.availableDrivers = const [],
    this.actionBusy = false,
    this.actionError,
    this.actionSuccess,
  });

  final bool loading;
  final Trip? trip;
  final String? error;
  final bool notFound;
  final bool canAssign;
  final bool canCancel;
  final bool canRefund;
  final List<PersonRef> availableDrivers;
  final bool actionBusy;
  final String? actionError;
  final String? actionSuccess;

  TripDetailState copyWith({
    bool? loading,
    Trip? trip,
    String? error,
    bool? notFound,
    bool? canAssign,
    bool? canCancel,
    bool? canRefund,
    List<PersonRef>? availableDrivers,
    bool? actionBusy,
    String? actionError,
    String? actionSuccess,
    bool clearError = false,
    bool clearActionError = false,
  }) {
    return TripDetailState(
      loading: loading ?? this.loading,
      trip: trip ?? this.trip,
      error: clearError ? null : (error ?? this.error),
      notFound: notFound ?? this.notFound,
      canAssign: canAssign ?? this.canAssign,
      canCancel: canCancel ?? this.canCancel,
      canRefund: canRefund ?? this.canRefund,
      availableDrivers: availableDrivers ?? this.availableDrivers,
      actionBusy: actionBusy ?? this.actionBusy,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      actionSuccess: actionSuccess,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        trip,
        error,
        notFound,
        canAssign,
        canCancel,
        canRefund,
        availableDrivers,
        actionBusy,
        actionError,
        actionSuccess,
      ];
}

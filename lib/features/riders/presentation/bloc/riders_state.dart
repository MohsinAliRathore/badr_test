part of 'riders_bloc.dart';

class RidersState extends Equatable {
  const RidersState({
    this.loading = false,
    this.riders = const [],
    this.cities = const [],
    this.error,
    this.canCreate = false,
    this.canUpdate = false,
  });

  final bool loading;
  final List<ApiRider> riders;
  final List<({String id, String name})> cities;
  final String? error;
  final bool canCreate;
  final bool canUpdate;

  RidersState copyWith({
    bool? loading,
    List<ApiRider>? riders,
    List<({String id, String name})>? cities,
    String? error,
    bool? canCreate,
    bool? canUpdate,
    bool clearError = false,
  }) {
    return RidersState(
      loading: loading ?? this.loading,
      riders: riders ?? this.riders,
      cities: cities ?? this.cities,
      error: clearError ? null : (error ?? this.error),
      canCreate: canCreate ?? this.canCreate,
      canUpdate: canUpdate ?? this.canUpdate,
    );
  }

  @override
  List<Object?> get props =>
      [loading, riders, cities, error, canCreate, canUpdate];
}

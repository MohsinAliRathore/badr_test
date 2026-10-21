part of 'drivers_bloc.dart';

class DriversState extends Equatable {
  const DriversState({
    this.loading = false,
    this.drivers = const [],
    this.cities = const [],
    this.error,
    this.canCreate = false,
    this.canUpdate = false,
  });

  final bool loading;
  final List<ApiDriver> drivers;
  final List<({String id, String name})> cities;
  final String? error;
  final bool canCreate;
  final bool canUpdate;

  DriversState copyWith({
    bool? loading,
    List<ApiDriver>? drivers,
    List<({String id, String name})>? cities,
    String? error,
    bool? canCreate,
    bool? canUpdate,
    bool clearError = false,
  }) {
    return DriversState(
      loading: loading ?? this.loading,
      drivers: drivers ?? this.drivers,
      cities: cities ?? this.cities,
      error: clearError ? null : (error ?? this.error),
      canCreate: canCreate ?? this.canCreate,
      canUpdate: canUpdate ?? this.canUpdate,
    );
  }

  @override
  List<Object?> get props =>
      [loading, drivers, cities, error, canCreate, canUpdate];
}

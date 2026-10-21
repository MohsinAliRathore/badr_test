part of 'trips_list_bloc.dart';

class TripsListState extends Equatable {
  const TripsListState({
    this.loading = false,
    this.loadingMore = false,
    this.trips = const [],
    this.filter = const TripFilter(),
    this.hasNextPage = false,
    this.endCursor,
    this.totalCount = 0,
    this.error,
    this.highlightNew = const {},
    this.highlightChanged = const {},
  });

  final bool loading;
  final bool loadingMore;
  final List<Trip> trips;
  final TripFilter filter;
  final bool hasNextPage;
  final String? endCursor;
  final int totalCount;
  final String? error;
  final Set<String> highlightNew;
  final Set<String> highlightChanged;

  TripsListState copyWith({
    bool? loading,
    bool? loadingMore,
    List<Trip>? trips,
    TripFilter? filter,
    bool? hasNextPage,
    String? endCursor,
    int? totalCount,
    String? error,
    Set<String>? highlightNew,
    Set<String>? highlightChanged,
    bool clearError = false,
  }) {
    return TripsListState(
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      trips: trips ?? this.trips,
      filter: filter ?? this.filter,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      endCursor: endCursor ?? this.endCursor,
      totalCount: totalCount ?? this.totalCount,
      error: clearError ? null : (error ?? this.error),
      highlightNew: highlightNew ?? this.highlightNew,
      highlightChanged: highlightChanged ?? this.highlightChanged,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        loadingMore,
        trips,
        filter,
        hasNextPage,
        endCursor,
        totalCount,
        error,
        highlightNew,
        highlightChanged,
      ];
}

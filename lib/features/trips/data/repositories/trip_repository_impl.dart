import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/graphql_client.dart';
import '../../../../core/network/rest_client.dart';
import '../../../../generated/graphql_operations.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../models/trip_mapper.dart';

class TripRepositoryImpl implements TripRepository {
  TripRepositoryImpl({
    required GraphqlClient graphql,
    required RestClient rest,
  })  : _graphql = graphql,
        _rest = rest;

  final GraphqlClient _graphql;
  final RestClient _rest;

  static const _listQuery = GqlOps.trips;

  static const _detailQuery = GqlOps.trip;

  static const _driversQuery = GqlOps.availableDrivers;

  @override
  Future<TripPage> listTrips({
    required TripFilter filter,
    int first = 20,
    String? after,
  }) async {
    final filterMap = <String, dynamic>{};
    if (filter.statuses != null && filter.statuses!.isNotEmpty) {
      filterMap['status'] =
          filter.statuses!.map(toGraphqlTripStatus).toList();
    }
    if (filter.from != null) {
      filterMap['from'] = filter.from!.toUtc().toIso8601String();
    }
    if (filter.to != null) {
      filterMap['to'] = filter.to!.toUtc().toIso8601String();
    }
    if (filter.search != null && filter.search!.trim().isNotEmpty) {
      filterMap['search'] = filter.search!.trim();
    }

    final data = await _graphql.query(
      document: _listQuery,
      variables: {
        'filter': filterMap.isEmpty ? null : filterMap,
        'first': first,
        'after': after,
      },
    );
    final connection = data['trips'] as Map<String, dynamic>;
    final pageInfo = connection['pageInfo'] as Map<String, dynamic>? ?? {};
    final nodes = (connection['nodes'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(mapTripJson)
        .toList();
    return TripPage(
      nodes: nodes,
      hasNextPage: pageInfo['hasNextPage'] == true,
      endCursor: pageInfo['endCursor']?.toString(),
      totalCount: (connection['totalCount'] as num?)?.toInt() ?? nodes.length,
    );
  }

  @override
  Future<Trip> getTrip(String id) async {
    final data = await _graphql.query(
      document: _detailQuery,
      variables: {'id': id},
    );
    final trip = data['trip'];
    if (trip is! Map<String, dynamic>) {
      throw const AppException(
        code: 'NOT_FOUND',
        message: 'Trip not found or outside your city',
        statusCode: 404,
      );
    }
    return mapTripJson(trip);
  }

  @override
  Future<Trip> assignDriver({
    required String tripId,
    required String driverId,
  }) async {
    await _rest.post<Map<String, dynamic>>(
      '/api/trips/$tripId/assign',
      data: {'driverId': driverId},
    );
    // REST trip shape is flat; reload nested GraphQL detail for the UI.
    return getTrip(tripId);
  }

  @override
  Future<Trip> cancelTrip({
    required String tripId,
    required String reason,
  }) async {
    await _rest.post<Map<String, dynamic>>(
      '/api/trips/$tripId/cancel',
      data: {'reason': reason},
    );
    return getTrip(tripId);
  }

  @override
  Future<Trip> refundTrip({
    required String tripId,
    required double amount,
    required String reason,
  }) async {
    await _rest.post<Map<String, dynamic>>(
      '/api/trips/$tripId/refund',
      data: {'amount': amount, 'reason': reason},
    );
    return getTrip(tripId);
  }

  @override
  Future<List<PersonRef>> availableDrivers() async {
    final data = await _graphql.query(document: _driversQuery);
    final connection = data['drivers'] as Map<String, dynamic>? ?? {};
    return (connection['nodes'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(mapPersonJson)
        .toList();
  }
}

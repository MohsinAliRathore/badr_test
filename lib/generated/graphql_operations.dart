/// Typed GraphQL operation documents (B7).
/// Aligned with https://sandbox.badrgo.com/graphql/schema.graphql
class GqlOps {
  GqlOps._();

  static const String kpis = r'''
    query Kpis($range: KpiRange!, $cityId: ID) {
      kpis(range: $range, cityId: $cityId) {
        range generatedAt openAlerts
        trips { active completed cancelled cancellationRate requested assigned inProgress }
        drivers { available onTrip offline total }
        revenue { amount currency }
        series { bucket total completed cancelled }
      }
    }
  ''';

  static const String trips = r'''
    query Trips($filter: TripFilter, $first: Int, $after: String) {
      trips(filter: $filter, first: $first, after: $after) {
        totalCount
        pageInfo { endCursor hasNextPage }
        nodes {
          id status distanceKm
          requestedAt assignedAt startedAt completedAt cancelledAt
          cancelReason refundReason
          fare { amount currency }
          refunded { amount currency }
          city { id name }
          rider { id name phone }
          driver { id name phone status }
          pickup { address location { lat lng } }
          dropoff { address location { lat lng } }
        }
      }
    }
  ''';

  static const String trip = r'''
    query Trip($id: ID!) {
      trip(id: $id) {
        id status distanceKm
        requestedAt assignedAt startedAt completedAt cancelledAt
        cancelReason cancelledBy refundReason
        fare { amount currency }
        refunded { amount currency }
        city { id name currency }
        rider { id name phone email rating }
        driver { id name phone status rating vehicle { make model plate color } }
        pickup { address location { lat lng } }
        dropoff { address location { lat lng } }
        timeline { status at }
      }
    }
  ''';

  static const String availableDrivers = r'''
    query AvailableDrivers {
      drivers(filter: { status: [AVAILABLE] }, first: 50) {
        nodes { id name phone status rating vehicle { make model plate color } }
      }
    }
  ''';

  static const String drivers = r'''
    query Drivers($first: Int, $after: String, $search: String) {
      drivers(first: $first, after: $after, filter: { search: $search }) {
        totalCount
        pageInfo { endCursor hasNextPage }
        nodes {
          id name phone status rating
          city { id name }
          vehicle { make model plate color }
        }
      }
    }
  ''';

  static const String riders = r'''
    query Riders($first: Int, $after: String, $search: String) {
      riders(first: $first, after: $after, search: $search) {
        totalCount
        pageInfo { endCursor hasNextPage }
        nodes {
          id name phone email rating tripCount
          city { id name }
        }
      }
    }
  ''';

  static const String alerts = r'''
    query Alerts($first: Int) {
      alerts(first: $first, filter: { acknowledged: false }) {
        nodes {
          id type severity message createdAt acknowledgedAt acknowledgedBy
          city { id name }
          trip { id }
          driver { id }
        }
      }
    }
  ''';

  static const String driverDetail = r'''
    query Driver($id: ID!) {
      driver(id: $id) {
        id name phone status rating
        vehicle { make model plate color }
        currentTrip { id status pickup { address } dropoff { address } }
      }
    }
  ''';

  static const String cities = r'''
    query Cities { cities { id name currency center { lat lng } } }
  ''';
}

import '../entities/trip.dart';

abstract class TripRepository {
  Future<TripPage> listTrips({
    required TripFilter filter,
    int first = 20,
    String? after,
  });

  Future<Trip> getTrip(String id);

  Future<Trip> assignDriver({required String tripId, required String driverId});

  Future<Trip> cancelTrip({required String tripId, required String reason});

  Future<Trip> refundTrip({
    required String tripId,
    required double amount,
    required String reason,
  });

  Future<List<PersonRef>> availableDrivers();
}

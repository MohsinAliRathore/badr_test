import '../../../../core/permissions/permission.dart';

class GeoPoint {
  const GeoPoint({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

class CityRef {
  const CityRef({
    required this.id,
    required this.name,
    this.countryCode,
    this.currency,
    this.timezone,
    this.center,
  });

  final String id;
  final String name;
  final String? countryCode;
  final String? currency;
  final String? timezone;
  final GeoPoint? center;
}

class SessionProfile {
  const SessionProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.roleDescription,
    required this.permissions,
    this.city,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String roleDescription;
  final PermissionSet permissions;
  final CityRef? city;

  String get cityLabel => city?.name ?? 'All cities';
}

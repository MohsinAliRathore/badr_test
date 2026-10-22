
class PermissionSet {
  const PermissionSet(this._map);

  factory PermissionSet.fromJson(Map<String, dynamic> json) {
    final map = <String, Set<String>>{};
    json.forEach((resource, actions) {
      if (actions is List) {
        map[resource] = actions.map((e) => e.toString()).toSet();
      }
    });
    return PermissionSet(map);
  }

  factory PermissionSet.fromGraphqlList(List<dynamic> list) {
    final map = <String, Set<String>>{};
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final resource = item['resource']?.toString();
        final actions = item['actions'];
        if (resource != null && actions is List) {
          map[resource] = actions.map((e) => e.toString()).toSet();
        }
      }
    }
    return PermissionSet(map);
  }

  final Map<String, Set<String>> _map;

  bool can(String resource, String action) =>
      _map[resource]?.contains(action) ?? false;

  bool get canReadKpi => can('kpi', 'read');
  bool get canReadTrip => can('trip', 'read');
  bool get canAssignTrip => can('trip', 'assign');
  bool get canCancelTrip => can('trip', 'cancel');
  bool get canRefundTrip => can('trip', 'refund');
  bool get canTrackDrivers => can('driver', 'track');
  bool get canReadDriver => can('driver', 'read');
  bool get canCreateDriver => can('driver', 'create');
  bool get canUpdateDriver => can('driver', 'update');
  bool get canMessageDriver => can('driver', 'message');
  bool get canReadRider => can('rider', 'read');
  bool get canCreateRider => can('rider', 'create');
  bool get canUpdateRider => can('rider', 'update');
  bool get canReadAlert => can('alert', 'read');
  bool get canAcknowledgeAlert => can('alert', 'acknowledge');
  bool get canReadPii => can('pii', 'read');
  bool get canListUsers => can('user', 'list');
  bool get canCreateUser => can('user', 'create');
  bool get canSetUserRole => can('user', 'set-role');
  bool get canBanUser => can('user', 'ban');
  bool get canManageUsers => canListUsers || canCreateUser;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PermissionSet && _mapsEqual(_map, other._map);

  @override
  int get hashCode => Object.hashAll(
        _map.entries.map((e) => Object.hash(e.key, Object.hashAll(e.value))),
      );

  static bool _mapsEqual(
    Map<String, Set<String>> a,
    Map<String, Set<String>> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null ||
          other.length != entry.value.length ||
          !other.containsAll(entry.value)) {
        return false;
      }
    }
    return true;
  }
}

enum AppDestination {
  dashboard,
  trips,
  map,
  alerts,
  drivers,
  riders,
  users,
}

extension AppDestinationX on AppDestination {
  String get path => switch (this) {
        AppDestination.dashboard => '/dashboard',
        AppDestination.trips => '/trips',
        AppDestination.map => '/map',
        AppDestination.alerts => '/alerts',
        AppDestination.drivers => '/drivers',
        AppDestination.riders => '/riders',
        AppDestination.users => '/users',
      };

  String get labelKey => switch (this) {
        AppDestination.dashboard => 'navDashboard',
        AppDestination.trips => 'navTrips',
        AppDestination.map => 'navMap',
        AppDestination.alerts => 'navAlerts',
        AppDestination.drivers => 'navDrivers',
        AppDestination.riders => 'navRiders',
        AppDestination.users => 'navUsers',
      };

  String get label => switch (this) {
        AppDestination.dashboard => 'Dashboard',
        AppDestination.trips => 'Trips',
        AppDestination.map => 'Live map',
        AppDestination.alerts => 'Alerts',
        AppDestination.drivers => 'Drivers',
        AppDestination.riders => 'Riders',
        AppDestination.users => 'Users',
      };

  bool isAllowed(PermissionSet permissions) => switch (this) {
        AppDestination.dashboard => permissions.canReadKpi,
        AppDestination.trips => permissions.canReadTrip,
        AppDestination.map => permissions.canTrackDrivers,
        AppDestination.alerts => permissions.canReadAlert,
        AppDestination.drivers => permissions.canReadDriver,
        AppDestination.riders => permissions.canReadRider,
        AppDestination.users => permissions.canListUsers,
      };
}

import 'package:badr_test/core/permissions/permission.dart';
import 'package:badr_test/core/theme/app_theme.dart';
import 'package:badr_test/features/auth/domain/entities/session_user.dart';
import 'package:badr_test/features/dashboard/domain/entities/kpi_snapshot.dart';
import 'package:badr_test/features/trips/domain/entities/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lightweight stand-in that mirrors permission-gated action buttons on trip detail.
class _TripActionsBar extends StatelessWidget {
  const _TripActionsBar({
    required this.permissions,
    required this.status,
  });

  final PermissionSet permissions;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (permissions.canAssignTrip &&
            (status == 'requested' || status == 'assigned'))
          const FilledButton(
            onPressed: null,
            child: Text('Assign driver'),
          ),
        if (permissions.canCancelTrip &&
            status != 'completed' &&
            status != 'cancelled')
          const OutlinedButton(
            onPressed: null,
            child: Text('Cancel'),
          ),
        if (permissions.canRefundTrip && status == 'completed')
          const FilledButton(
            onPressed: null,
            child: Text('Refund'),
          ),
      ],
    );
  }
}

Trip _sample({required String status}) {
  return Trip(
    id: 'trp_test',
    status: status,
    city: const CityRef(id: 'city_doh', name: 'Doha'),
    rider: const PersonRef(id: 'r1', name: 'Rider', phone: '***'),
    pickup: const PlaceRef(
      address: 'A',
      location: GeoPoint(lat: 0, lng: 0),
    ),
    dropoff: const PlaceRef(
      address: 'B',
      location: GeoPoint(lat: 1, lng: 1),
    ),
    distanceKm: 3,
    fare: const MoneyAmount(amount: 20, currency: 'QAR'),
    refunded: const MoneyAmount(amount: 0, currency: 'QAR'),
    requestedAt: DateTime.utc(2026, 1, 1),
    timeline: const [],
  );
}

void main() {
  testWidgets('viewer sees no trip action buttons; dispatcher sees assign',
      (tester) async {
    final viewer = PermissionSet.fromJson({
      'trip': ['read'],
      'kpi': ['read'],
    });
    final dispatcher = PermissionSet.fromJson({
      'trip': ['read', 'assign', 'cancel'],
    });

    // Viewer
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: _TripActionsBar(
            permissions: viewer,
            status: _sample(status: 'requested').status,
          ),
        ),
      ),
    );
    expect(find.text('Assign driver'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Refund'), findsNothing);

    // Dispatcher
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: _TripActionsBar(
            permissions: dispatcher,
            status: 'requested',
          ),
        ),
      ),
    );
    expect(find.text('Assign driver'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Refund'), findsNothing);
  });
}

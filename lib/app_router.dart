import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/permissions/permission.dart';
import 'core/widgets/async_body.dart';
import 'di/injection.dart';
import 'features/alerts/presentation/bloc/alerts_bloc.dart';
import 'features/alerts/presentation/pages/alerts_page.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/sign_in_page.dart';
import 'features/chat/presentation/widgets/driver_chat_panel.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/drivers/presentation/bloc/drivers_bloc.dart';
import 'features/drivers/presentation/pages/drivers_page.dart';
import 'features/map/presentation/bloc/map_bloc.dart';
import 'features/map/presentation/pages/map_page.dart';
import 'features/riders/presentation/bloc/riders_bloc.dart';
import 'features/riders/presentation/pages/riders_page.dart';
import 'features/shell/presentation/pages/shell_page.dart';
import 'features/trips/presentation/bloc/trips_list_bloc.dart';
import 'features/trips/presentation/pages/trip_detail_page.dart';
import 'features/trips/presentation/pages/trips_page.dart';
import 'features/users/presentation/bloc/users_bloc.dart';
import 'features/users/presentation/pages/users_page.dart';

GoRouter createRouter({
  required AuthBloc authBloc,
  required AppDependencies deps,
}) {
  return GoRouter(
    initialLocation: '/sign-in',
    refreshListenable: _AuthRefresh(authBloc),
    redirect: (context, state) {
      final auth = authBloc.state;
      final loggingIn = state.matchedLocation == '/sign-in';
      if (auth.status == AuthStatus.unknown ||
          (auth.status == AuthStatus.loading && !auth.isAuthenticated)) {
        return loggingIn ? null : '/sign-in';
      }
      if (!auth.isAuthenticated) {
        return loggingIn ? null : '/sign-in';
      }
      if (loggingIn) {
        return _homeFor(auth.profile!.permissions);
      }

      final perms = auth.profile!.permissions;
      final loc = state.matchedLocation;
      if (loc.startsWith('/dashboard') && !perms.canReadKpi) {
        return _firstAllowed(perms) ?? '/no-access';
      }
      if (loc.startsWith('/map') && !perms.canTrackDrivers) {
        return '/no-access';
      }
      if (loc.startsWith('/alerts') && !perms.canReadAlert) {
        return '/no-access';
      }
      if (loc.startsWith('/trips') && !perms.canReadTrip) {
        return '/no-access';
      }
      if (loc.startsWith('/drivers') && !perms.canReadDriver) {
        return '/no-access';
      }
      if (loc.startsWith('/riders') && !perms.canReadRider) {
        return '/no-access';
      }
      if (loc.startsWith('/users') && !perms.canListUsers) {
        return '/no-access';
      }
      if (loc == '/') return _homeFor(perms);
      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: '/no-access',
        builder: (context, state) => const Scaffold(body: NoAccessView()),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => AlertsBloc(
                  alertRepository: deps.alertRepository,
                  realtimeHub: deps.realtimeHub,
                  permissions: authBloc.state.profile!.permissions,
                )..add(const AlertsStarted()),
              ),
            ],
            child: ShellPage(child: child),
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) {
              final allowed =
                  context.read<AuthBloc>().state.profile!.permissions.canReadKpi;
              return PermissionGate(
                allowed: allowed,
                child: BlocProvider(
                  create: (_) => DashboardBloc(
                    kpiRepository: deps.kpiRepository,
                    realtimeHub: deps.realtimeHub,
                  )..add(const DashboardStarted()),
                  child: const DashboardPage(),
                ),
              );
            },
          ),
          GoRoute(
            path: '/trips',
            builder: (context, state) {
              final allowed =
                  context.read<AuthBloc>().state.profile!.permissions.canReadTrip;
              return PermissionGate(
                allowed: allowed,
                child: BlocProvider(
                  create: (_) => TripsListBloc(
                    tripRepository: deps.tripRepository,
                    realtimeHub: deps.realtimeHub,
                  )..add(const TripsListStarted()),
                  child: const TripsPage(),
                ),
              );
            },
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return TripDetailPage(tripId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) {
              final perms =
                  context.read<AuthBloc>().state.profile!.permissions;
              return PermissionGate(
                allowed: perms.canTrackDrivers,
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) => MapBloc(
                        realtimeHub: deps.realtimeHub,
                        graphql: deps.graphqlClient,
                      )..add(const MapStarted()),
                    ),
                  ],
                  child: Stack(
                    children: [
                      const MapPage(),
                      if (perms.canMessageDriver)
                        const Positioned(
                          right: 12,
                          bottom: 12,
                          child: DriverChatPanel(),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          GoRoute(
            path: '/alerts',
            builder: (context, state) {
              final allowed =
                  context.read<AuthBloc>().state.profile!.permissions.canReadAlert;
              return PermissionGate(
                allowed: allowed,
                child: const AlertsPage(),
              );
            },
          ),
          GoRoute(
            path: '/drivers',
            builder: (context, state) {
              final perms =
                  context.read<AuthBloc>().state.profile!.permissions;
              return PermissionGate(
                allowed: perms.canReadDriver,
                child: BlocProvider(
                  create: (_) => DriversBloc(
                    repository: deps.driverAdminRepository,
                    permissions: perms,
                  )..add(const DriversStarted()),
                  child: const DriversPage(),
                ),
              );
            },
          ),
          GoRoute(
            path: '/riders',
            builder: (context, state) {
              final perms =
                  context.read<AuthBloc>().state.profile!.permissions;
              return PermissionGate(
                allowed: perms.canReadRider,
                child: BlocProvider(
                  create: (_) => RidersBloc(
                    repository: deps.riderAdminRepository,
                    permissions: perms,
                  )..add(const RidersStarted()),
                  child: const RidersPage(),
                ),
              );
            },
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) {
              final perms =
                  context.read<AuthBloc>().state.profile!.permissions;
              return PermissionGate(
                allowed: perms.canListUsers,
                child: BlocProvider(
                  create: (_) => UsersBloc(
                    repository: deps.userRepository,
                    permissions: perms,
                  )..add(const UsersStarted()),
                  child: const UsersPage(),
                ),
              );
            },
          ),
        ],
      ),
    ],
  );
}

String _homeFor(PermissionSet permissions) {
  return _firstAllowed(permissions) ?? '/no-access';
}

String? _firstAllowed(PermissionSet permissions) {
  for (final d in AppDestination.values) {
    if (d.isAllowed(permissions)) return d.path;
  }
  return null;
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._authBloc) {
    _authBloc.stream.listen((_) => notifyListeners());
  }

  final AuthBloc _authBloc;
}

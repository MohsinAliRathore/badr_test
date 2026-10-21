import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/permissions/permission.dart';
import '../../../../core/widgets/async_body.dart';
import '../../../alerts/presentation/bloc/alerts_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../connectivity/presentation/bloc/connectivity_bloc.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';

class ShellPage extends StatelessWidget {
  const ShellPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, auth) {
        final profile = auth.profile;
        if (profile == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final destinations = AppDestination.values
            .where((d) => d.isAllowed(profile.permissions))
            .toList();
        final location = GoRouterState.of(context).uri.path;
        var selected = 0;
        for (var i = 0; i < destinations.length; i++) {
          if (location.startsWith(destinations[i].path)) {
            selected = i;
            break;
          }
        }

        final width = MediaQuery.sizeOf(context).width;
        final useRail = width >= 900;

        return Scaffold(
          body: Column(
            children: [
              BlocBuilder<AlertsBloc, AlertsState>(
                buildWhen: (p, c) => p.criticalBanner != c.criticalBanner,
                builder: (context, alerts) {
                  final banner = alerts.criticalBanner;
                  if (banner == null) return const SizedBox.shrink();
                  return Material(
                    color: Colors.red.shade700,
                    child: SafeArea(
                      bottom: false,
                      child: ListTile(
                        leading: const Icon(Icons.sos, color: Colors.white),
                        title: Text(
                          banner.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          s.navAlerts,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (alerts.canAcknowledge)
                              TextButton(
                                onPressed: () => context
                                    .read<AlertsBloc>()
                                    .add(AlertAcknowledgeRequested(banner.id)),
                                child: Text(
                                  s.acknowledge,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            IconButton(
                              onPressed: () => context
                                  .read<AlertsBloc>()
                                  .add(const AlertCriticalDismissed()),
                              icon: const Icon(Icons.close, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              BlocBuilder<ConnectivityBloc, ConnectivityState>(
                builder: (context, conn) {
                  if (conn.offline) {
                    return Material(
                      color: Colors.blueGrey.shade800,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              s.offline,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (conn.maintenance) {
                    final since = conn.maintenanceSince;
                    final durationText = since == null
                        ? ''
                        : _formatDuration(
                            DateTime.now().toUtc().difference(since),
                          );
                    return Material(
                      color: const Color(0xFF1E293B),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.construction,
                                color: Colors.white, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              s.maintenance,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              conn.maintenanceMessage ??
                                  'The API is temporarily unavailable.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            if (durationText.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Down for $durationText · reason: ${conn.maintenanceReason ?? '—'}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }
                  if (conn.showLightReconnect) {
                    return Material(
                      color: Colors.orange.shade700,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              s.reconnecting,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              Expanded(
                child: useRail
                    ? Row(
                        children: [
                          _Rail(
                            destinations: destinations,
                            selected: selected,
                            profileName: profile.name,
                            role: profile.role,
                            city: profile.cityLabel,
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(
                            child: destinations.isEmpty
                                ? NoAccessView(message: s.noAccessBody)
                                : child,
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _CompactHeader(
                            profileName: profile.name,
                            role: profile.role,
                            city: profile.cityLabel,
                          ),
                          Expanded(
                            child: destinations.isEmpty
                                ? NoAccessView(message: s.noAccessBody)
                                : child,
                          ),
                          if (destinations.isNotEmpty)
                            NavigationBar(
                              selectedIndex: selected.clamp(0, destinations.length - 1),
                              onDestinationSelected: (i) {
                                if (i < destinations.length) {
                                  context.go(destinations[i].path);
                                }
                              },
                              destinations: [
                                for (final d in destinations)
                                  NavigationDestination(
                                    icon: Icon(_icon(d)),
                                    label: s.labelFor(d.labelKey),
                                  ),
                              ],
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _icon(AppDestination d) => switch (d) {
        AppDestination.dashboard => Icons.dashboard_outlined,
        AppDestination.trips => Icons.route_outlined,
        AppDestination.map => Icons.map_outlined,
        AppDestination.alerts => Icons.notifications_outlined,
        AppDestination.drivers => Icons.drive_eta_outlined,
        AppDestination.riders => Icons.person_outline,
        AppDestination.users => Icons.admin_panel_settings_outlined,
      };

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    return '${d.inSeconds}s';
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.destinations,
    required this.selected,
    required this.profileName,
    required this.role,
    required this.city,
  });

  final List<AppDestination> destinations;
  final int selected;
  final String profileName;
  final String role;
  final String city;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return NavigationRail(
      selectedIndex: destinations.isEmpty ? 0 : selected,
      onDestinationSelected: (i) {
        if (i < destinations.length) context.go(destinations[i].path);
      },
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              'badrgo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            Text('Ops', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  child: Text(
                    profileName.isNotEmpty
                        ? profileName.characters.first.toUpperCase()
                        : '?',
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 88,
                  child: Text(
                    profileName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                Text(
                  role,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                Text(city, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 4),
                IconButton(
                  tooltip: s.language,
                  onPressed: () => context.read<SettingsCubit>().toggleLocale(),
                  icon: const Icon(Icons.translate),
                ),
                IconButton(
                  tooltip: s.theme,
                  onPressed: () => context.read<SettingsCubit>().cycleTheme(),
                  icon: const Icon(Icons.brightness_6_outlined),
                ),
                IconButton(
                  tooltip: s.signOut,
                  onPressed: () =>
                      context.read<AuthBloc>().add(const AuthSignOutRequested()),
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
          ),
        ),
      ),
      destinations: [
        for (final d in destinations)
          NavigationRailDestination(
            icon: Icon(_icon(d)),
            label: Text(s.labelFor(d.labelKey)),
          ),
      ],
    );
  }

  IconData _icon(AppDestination d) => switch (d) {
        AppDestination.dashboard => Icons.dashboard_outlined,
        AppDestination.trips => Icons.route_outlined,
        AppDestination.map => Icons.map_outlined,
        AppDestination.alerts => Icons.notifications_outlined,
        AppDestination.drivers => Icons.drive_eta_outlined,
        AppDestination.riders => Icons.person_outline,
        AppDestination.users => Icons.admin_panel_settings_outlined,
      };
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({
    required this.profileName,
    required this.role,
    required this.city,
  });

  final String profileName;
  final String role;
  final String city;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Material(
      elevation: 1,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text(
                'badrgo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$profileName · $role · $city',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => context.read<SettingsCubit>().toggleLocale(),
                icon: const Icon(Icons.translate),
              ),
              IconButton(
                onPressed: () => context.read<SettingsCubit>().cycleTheme(),
                icon: const Icon(Icons.brightness_6_outlined),
              ),
              IconButton(
                tooltip: s.signOut,
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthSignOutRequested()),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PermissionGate extends StatelessWidget {
  const PermissionGate({
    super.key,
    required this.allowed,
    required this.child,
  });

  final bool allowed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!allowed) {
      return NoAccessView(message: AppStrings.of(context).noAccessBody);
    }
    return child;
  }
}

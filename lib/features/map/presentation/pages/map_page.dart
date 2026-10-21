import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart';
import '../bloc/map_bloc.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.read<AuthBloc>().state.profile;
    final city = profile?.city;
    final canChat = profile?.permissions.canMessageDriver ?? false;
    final center = LatLng(
      city?.center?.lat ?? 25.2854,
      city?.center?.lng ?? 51.531,
    );
    final s = AppStrings.of(context);

    return BlocBuilder<MapBloc, MapState>(
      builder: (context, state) {
        return Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 11.5,
                onTap: (_, _) {},
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.badrgo.ops_console',
                ),
                MarkerLayer(
                  markers: state.drivers.map((d) {
                    final selected = state.selected?.id == d.id;
                    return Marker(
                      point: LatLng(d.lat, d.lng),
                      width: selected ? 44 : 36,
                      height: selected ? 44 : 36,
                      child: GestureDetector(
                        onTap: () => context
                            .read<MapBloc>()
                            .add(MapDriverSelected(d.id)),
                        child: Tooltip(
                          message: '${d.name} (${d.status})',
                          child: Icon(
                            Icons.navigation,
                            color: AppTheme.statusColor(d.status),
                            size: selected ? 36 : 28,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            if (state.isReconnecting)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Material(
                  color: Colors.orange.shade700,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      'Reconnecting to live map…',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            if (state.selected != null)
              Positioned(
                right: 12,
                top: 56,
                child: Card(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  state.selected!.name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              IconButton(
                                onPressed: () => context
                                    .read<MapBloc>()
                                    .add(const MapDriverSelected('')),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          Text('Status: ${state.selected!.status}'),
                          if (state.selectedDetails != null) ...[
                            const SizedBox(height: 8),
                            Text('Phone: ${state.selectedDetails!['phone']}'),
                            if (state.selectedDetails!['vehicle'] is Map) ...[
                              Text(
                                'Vehicle: ${state.selectedDetails!['vehicle']['make']} '
                                '${state.selectedDetails!['vehicle']['model']} · '
                                '${state.selectedDetails!['vehicle']['plate']}',
                              ),
                            ],
                            if (state.selectedDetails!['currentTrip'] is Map) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Current trip: ${state.selectedDetails!['currentTrip']['id']}',
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                              Text(
                                'Trip status: ${state.selectedDetails!['currentTrip']['status']}',
                              ),
                            ] else
                              const Text('No active trip'),
                          ],
                          if (canChat) ...[
                            const SizedBox(height: 12),
                            FilledButton.tonalIcon(
                              onPressed: () => context.read<ChatBloc>().add(
                                    ChatOpened(
                                      driverId: state.selected!.id,
                                      driverName: state.selected!.name,
                                    ),
                                  ),
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: Text(s.chat),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text('${state.drivers.length} drivers'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/async_body.dart';
import '../../domain/entities/trip.dart';
import '../bloc/trips_list_bloc.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  final _search = TextEditingController();
  String? _status;
  DateTime? _from;
  DateTime? _to;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<TripsListBloc>().add(
          TripsFilterChanged(
            TripFilter(
              statuses: _status == null ? null : [_status!],
              search: _search.text,
              from: _from,
              to: _to,
            ),
          ),
        );
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from ?? DateTime.now().subtract(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _from = DateTime.utc(picked.year, picked.month, picked.day));
      _applyFilters();
    }
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(
        () => _to = DateTime.utc(picked.year, picked.month, picked.day, 23, 59, 59),
      );
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(s.navTrips, style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: s.search,
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _applyFilters(),
                ),
              ),
              DropdownButton<String?>(
                value: _status,
                hint: const Text('Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All statuses')),
                  DropdownMenuItem(value: 'requested', child: Text('Requested')),
                  DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
                  DropdownMenuItem(value: 'in_progress', child: Text('In progress')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (v) {
                  setState(() => _status = v);
                  _applyFilters();
                },
              ),
              OutlinedButton.icon(
                onPressed: _pickFrom,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _from == null
                      ? s.fromDate
                      : DateFormat.yMMMd().format(_from!.toLocal()),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _pickTo,
                icon: const Icon(Icons.event, size: 16),
                label: Text(
                  _to == null
                      ? s.toDate
                      : DateFormat.yMMMd().format(_to!.toLocal()),
                ),
              ),
              if (_from != null || _to != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _from = null;
                      _to = null;
                    });
                    _applyFilters();
                  },
                  child: const Text('Clear dates'),
                ),
              IconButton(
                tooltip: 'Apply',
                onPressed: _applyFilters,
                icon: const Icon(Icons.filter_alt),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<TripsListBloc, TripsListState>(
            builder: (context, state) {
              return AsyncBody(
                loading: state.loading,
                error: state.error,
                isEmpty: state.trips.isEmpty,
                emptyMessage: 'No trips match these filters',
                onRetry: () => context
                    .read<TripsListBloc>()
                    .add(const TripsRefreshRequested()),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.trips.length + (state.hasNextPage ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.trips.length) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: state.loadingMore
                              ? const CircularProgressIndicator()
                              : TextButton(
                                  onPressed: () => context
                                      .read<TripsListBloc>()
                                      .add(const TripsLoadMore()),
                                  child: Text(s.loadMore),
                                ),
                        ),
                      );
                    }
                    final trip = state.trips[index];
                    final isNew = state.highlightNew.contains(trip.id);
                    final isChanged = state.highlightChanged.contains(trip.id);
                    return Card(
                      color: isNew
                          ? Colors.green.withValues(alpha: 0.08)
                          : isChanged
                              ? Colors.amber.withValues(alpha: 0.12)
                              : null,
                      child: ListTile(
                        onTap: () => context.go('/trips/${trip.id}'),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                trip.id,
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                            if (isNew)
                              const Chip(
                                label: Text('NEW'),
                                visualDensity: VisualDensity.compact,
                              ),
                            if (isChanged && !isNew)
                              const Chip(
                                label: Text('UPDATED'),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                        subtitle: Text(
                          '${trip.rider.name} · ${trip.pickup.address} → ${trip.dropoff.address}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.statusColor(trip.status)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                trip.status,
                                style: TextStyle(
                                  color: AppTheme.statusColor(trip.status),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              DateFormat.MMMd().add_Hm().format(
                                    trip.requestedAt.toLocal(),
                                  ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

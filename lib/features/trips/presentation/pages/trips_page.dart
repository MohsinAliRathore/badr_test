import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/async_body.dart';
import '../../../../core/widgets/page_chrome.dart';
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
        () => _to =
            DateTime.utc(picked.year, picked.month, picked.day, 23, 59, 59),
      );
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: s.navTrips,
          subtitle: 'Filter and monitor live trip activity',
          actions: [
            IconButton.filledTonal(
              tooltip: 'Apply filters',
              onPressed: _applyFilters,
              icon: const Icon(Icons.filter_alt),
            ),
          ],
        ),
        FilterBar(
          children: [
            SizedBox(
              width: 240,
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: s.search,
                  prefixIcon: const Icon(Icons.search),
                ),
                onSubmitted: (_) => _applyFilters(),
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String?>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All statuses')),
                  DropdownMenuItem(value: 'requested', child: Text('Requested')),
                  DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
                  DropdownMenuItem(
                    value: 'in_progress',
                    child: Text('In progress'),
                  ),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (v) {
                  setState(() => _status = v);
                  _applyFilters();
                },
              ),
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
          ],
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
                child: ListView.separated(
                  padding: PageChrome.listInsets,
                  itemCount: state.trips.length + (state.hasNextPage ? 1 : 0),
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: PageChrome.itemGap),
                  itemBuilder: (context, index) {
                    if (index >= state.trips.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: state.loadingMore
                              ? const CircularProgressIndicator()
                              : FilledButton.tonal(
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
                            if (isNew) ...[
                              const SizedBox(width: 8),
                              const Chip(
                                label: Text('NEW'),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                            if (isChanged && !isNew) ...[
                              const SizedBox(width: 8),
                              const Chip(
                                label: Text('UPDATED'),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${trip.rider.name} · ${trip.pickup.address} → ${trip.dropoff.address}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.statusColor(trip.status)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
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
                              const SizedBox(height: 6),
                              Text(
                                DateFormat.MMMd().add_Hm().format(
                                      trip.requestedAt.toLocal(),
                                    ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
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

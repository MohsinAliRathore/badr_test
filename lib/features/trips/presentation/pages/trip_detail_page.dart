import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/async_body.dart';
import '../../../../core/widgets/page_chrome.dart';
import '../../../../di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/trip.dart';
import '../bloc/trip_detail_bloc.dart';

class TripDetailPage extends StatelessWidget {
  const TripDetailPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final deps = context.read<AppDependencies>();
    final permissions = context.read<AuthBloc>().state.profile!.permissions;
    return BlocProvider(
      create: (_) => TripDetailBloc(
        tripRepository: deps.tripRepository,
        permissions: permissions,
      )..add(TripDetailLoadRequested(tripId)),
      child: const _TripDetailView(),
    );
  }
}

class _TripDetailView extends StatelessWidget {
  const _TripDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripDetailBloc, TripDetailState>(
      listenWhen: (p, c) =>
          p.actionError != c.actionError || p.actionSuccess != c.actionSuccess,
      listener: (context, state) {
        final msg = state.actionError ?? state.actionSuccess;
        if (msg != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      },
      builder: (context, state) {
        if (state.notFound) {
          return Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.go('/trips'),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to trips'),
                ),
              ),
              const Expanded(child: NotFoundView()),
            ],
          );
        }
        return AsyncBody(
          loading: state.loading,
          error: state.error,
          isEmpty: state.trip == null,
          onRetry: () {
            final id = GoRouterState.of(context).pathParameters['id'];
            if (id != null) {
              context.read<TripDetailBloc>().add(TripDetailLoadRequested(id));
            }
          },
          child: state.trip == null
              ? const SizedBox.shrink()
              : _TripBody(trip: state.trip!, state: state),
        );
      },
    );
  }
}

class _TripBody extends StatelessWidget {
  const _TripBody({required this.trip, required this.state});

  final Trip trip;
  final TripDetailState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: PageChrome.pageInsets,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => context.go('/trips'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Trips'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                trip.id,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.statusColor(trip.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trip.status,
                style: TextStyle(
                  color: AppTheme.statusColor(trip.status),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (state.canAssign &&
                (trip.status == 'requested' || trip.status == 'assigned'))
              FilledButton.icon(
                onPressed: state.actionBusy
                    ? null
                    : () => _assign(context),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Assign driver'),
              ),
            if (state.canCancel &&
                !['completed', 'cancelled'].contains(trip.status))
              OutlinedButton.icon(
                onPressed: state.actionBusy ? null : () => _cancel(context),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel'),
              ),
            if (state.canRefund && trip.status == 'completed')
              FilledButton.tonalIcon(
                onPressed: state.actionBusy ? null : () => _refund(context),
                icon: const Icon(Icons.currency_exchange),
                label: const Text('Refund'),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _section(
          context,
          'People',
          [
            _kv('Rider', '${trip.rider.name} · ${trip.rider.phone}'),
            _kv(
              'Driver',
              trip.driver == null
                  ? 'Unassigned'
                  : '${trip.driver!.name} · ${trip.driver!.phone}',
            ),
            _kv('City', trip.city.name),
          ],
        ),
        _section(
          context,
          'Route',
          [
            _kv('Pickup', trip.pickup.address),
            _kv('Dropoff', trip.dropoff.address),
            _kv('Distance', '${trip.distanceKm.toStringAsFixed(1)} km'),
          ],
        ),
        _section(
          context,
          'Fare',
          [
            _kv('Fare', trip.fare.formatted),
            _kv('Refunded', trip.refunded.formatted),
            _kv(
              'Remaining',
              '${trip.remainingRefundable.toStringAsFixed(2)} ${trip.fare.currency}',
            ),
            if (trip.refundReason != null) _kv('Refund reason', trip.refundReason!),
            if (trip.cancelReason != null) _kv('Cancel reason', trip.cancelReason!),
          ],
        ),
        _section(
          context,
          'Timeline',
          trip.timeline
              .map(
                (e) => _kv(
                  e.status,
                  DateFormat.MMMd().add_Hm().format(e.at.toLocal()),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  Future<void> _assign(BuildContext context) async {
    final bloc = context.read<TripDetailBloc>()
      ..add(const TripLoadDriversRequested());
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!context.mounted) return;
    final drivers = bloc.state.availableDrivers;
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Assign driver'),
          content: SizedBox(
            width: 400,
            height: 360,
            child: drivers.isEmpty
                ? const Center(child: Text('No available drivers'))
                : ListView.builder(
                    itemCount: drivers.length,
                    itemBuilder: (_, i) {
                      final d = drivers[i];
                      return ListTile(
                        title: Text(d.name),
                        subtitle: Text(
                          '${d.phone}${d.vehicle != null ? ' · ${d.vehicle!.plate}' : ''}',
                        ),
                        onTap: () => Navigator.pop(ctx, d.id),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        );
      },
    );
    if (selected != null && context.mounted) {
      context.read<TripDetailBloc>().add(
            TripAssignRequested(tripId: trip.id, driverId: selected),
          );
    }
  }

  Future<void> _cancel(BuildContext context) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel trip'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason (min 3 characters)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Cancel trip'),
          ),
        ],
      ),
    );
    if (reason != null && reason.length >= 3 && context.mounted) {
      context.read<TripDetailBloc>().add(
            TripCancelRequested(tripId: trip.id, reason: reason),
          );
    }
  }

  Future<void> _refund(BuildContext context) async {
    final amountCtrl = TextEditingController(
      text: trip.remainingRefundable.toStringAsFixed(2),
    );
    final reasonCtrl = TextEditingController();
    final result = await showDialog<(double, String)>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Issue refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Remaining: ${trip.remainingRefundable.toStringAsFixed(2)} ${trip.fare.currency}',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text.trim());
              final reason = reasonCtrl.text.trim();
              if (amount == null || amount <= 0 || reason.length < 3) return;
              Navigator.pop(ctx, (amount, reason));
            },
            child: const Text('Refund'),
          ),
        ],
      ),
    );
    if (result != null && context.mounted) {
      context.read<TripDetailBloc>().add(
            TripRefundRequested(
              tripId: trip.id,
              amount: result.$1,
              reason: result.$2,
            ),
          );
    }
  }
}

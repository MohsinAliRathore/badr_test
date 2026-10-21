import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/async_body.dart';
import '../bloc/alerts_bloc.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Text('Alerts', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              IconButton(
                onPressed: () => context
                    .read<AlertsBloc>()
                    .add(const AlertsRefreshRequested()),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<AlertsBloc, AlertsState>(
            builder: (context, state) {
              return AsyncBody(
                loading: state.loading,
                error: state.error,
                isEmpty: state.alerts.isEmpty,
                emptyMessage: 'No open alerts',
                onRetry: () => context
                    .read<AlertsBloc>()
                    .add(const AlertsRefreshRequested()),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.alerts.length,
                  itemBuilder: (context, index) {
                    final alert = state.alerts[index];
                    final critical = alert.isCritical;
                    return Card(
                      color: critical ? Colors.red.withValues(alpha: 0.08) : null,
                      child: ListTile(
                        leading: Icon(
                          critical ? Icons.sos : Icons.notifications_outlined,
                          color: critical ? Colors.red : null,
                        ),
                        title: Text(alert.message),
                        subtitle: Text(
                          '${alert.type} · ${alert.severity} · '
                          '${DateFormat.MMMd().add_Hm().format(alert.createdAt.toLocal())}',
                        ),
                        trailing: state.canAcknowledge
                            ? TextButton(
                                onPressed: () => context
                                    .read<AlertsBloc>()
                                    .add(AlertAcknowledgeRequested(alert.id)),
                                child: const Text('Ack'),
                              )
                            : null,
                        onTap: alert.tripId == null
                            ? null
                            : () => context.go('/trips/${alert.tripId}'),
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

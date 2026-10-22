import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/async_body.dart';
import '../../../../core/widgets/page_chrome.dart';
import '../bloc/alerts_bloc.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: s.navAlerts,
          subtitle: 'Open alerts for your city',
          actions: [
            IconButton.filledTonal(
              onPressed: () => context
                  .read<AlertsBloc>()
                  .add(const AlertsRefreshRequested()),
              icon: const Icon(Icons.refresh),
            ),
          ],
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
                child: SpacedList(
                  itemCount: state.alerts.length,
                  itemBuilder: (context, index) {
                    final alert = state.alerts[index];
                    final critical = alert.isCritical;
                    return Card(
                      color: critical ? Colors.red.withValues(alpha: 0.08) : null,
                      child: ListTile(
                        leading: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Icon(
                            critical ? Icons.sos : Icons.notifications_outlined,
                            color: critical ? Colors.red : null,
                          ),
                        ),
                        title: Text(alert.message),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${alert.type} · ${alert.severity} · '
                            '${DateFormat.MMMd().add_Hm().format(alert.createdAt.toLocal())}',
                          ),
                        ),
                        trailing: state.canAcknowledge
                            ? Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: FilledButton.tonal(
                                  onPressed: () => context
                                      .read<AlertsBloc>()
                                      .add(AlertAcknowledgeRequested(alert.id)),
                                  child: Text(s.acknowledge),
                                ),
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

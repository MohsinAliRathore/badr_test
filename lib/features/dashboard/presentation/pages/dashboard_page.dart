import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/async_body.dart';
import '../../../../core/widgets/page_chrome.dart';
import '../../domain/entities/kpi_snapshot.dart';
import '../bloc/dashboard_bloc.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final snap = state.snapshot;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Dashboard',
              subtitle: 'Live operations overview',
              actions: [
                if (state.live)
                  Chip(
                    avatar: Icon(
                      Icons.bolt,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: const Text('Live'),
                  ),
                SegmentedButton<KpiRange>(
                  segments: [
                    ButtonSegment(
                      value: KpiRange.last24h,
                      label: Text(KpiRange.last24h.label),
                    ),
                    ButtonSegment(
                      value: KpiRange.last7d,
                      label: Text(KpiRange.last7d.label),
                    ),
                  ],
                  selected: {state.range},
                  onSelectionChanged: (s) {
                    context
                        .read<DashboardBloc>()
                        .add(DashboardRangeChanged(s.first));
                  },
                ),
              ],
            ),
            Expanded(
              child: AsyncBody(
                loading: state.loading && snap == null,
                error: state.error,
                isEmpty: snap == null,
                onRetry: () => context
                    .read<DashboardBloc>()
                    .add(const DashboardRefreshRequested()),
                child: snap == null
                    ? const SizedBox.shrink()
                    : _DashboardBody(snapshot: snap),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.snapshot});

  final KpiSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final revenue = snapshot.revenue.isEmpty
        ? '—'
        : snapshot.revenue.map((m) => m.formatted).join(' · ');
    final tiles = [
      _KpiTile('Active trips', '${snapshot.trips.active}', Icons.local_taxi),
      _KpiTile(
        'Completed',
        '${snapshot.trips.completed}',
        Icons.check_circle_outline,
      ),
      _KpiTile(
        'Cancel rate',
        NumberFormat.percentPattern().format(snapshot.trips.cancellationRate),
        Icons.cancel_outlined,
      ),
      _KpiTile('Revenue', revenue, Icons.payments_outlined),
      _KpiTile(
        'Drivers available',
        '${snapshot.drivers.available}',
        Icons.person_outline,
      ),
      _KpiTile('Drivers on trip', '${snapshot.drivers.onTrip}', Icons.route),
      _KpiTile(
        'Open alerts',
        '${snapshot.openAlerts}',
        Icons.notification_important_outlined,
      ),
    ];

    return ListView(
      padding: PageChrome.listInsets,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final cross = width > 1200
                ? 4
                : width > 800
                    ? 3
                    : 2;
            return GridView.count(
              crossAxisCount: cross,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: width > 800 ? 2.4 : 2.1,
              children: tiles,
            );
          },
        ),
        const SizedBox(height: 28),
        Text(
          'Trips over time',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 280,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: _SeriesChart(series: snapshot.series),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeriesChart extends StatelessWidget {
  const _SeriesChart({required this.series});

  final List<SeriesPoint> series;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const Center(child: Text('No series data'));
    }
    final spots = <FlSpot>[];
    for (var i = 0; i < series.length; i++) {
      spots.add(FlSpot(i.toDouble(), series[i].completed.toDouble()));
    }
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (series.length / 4).clamp(1, 6).toDouble(),
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= series.length) return const SizedBox.shrink();
                final d = series[i].bucket.toLocal();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat.Hm().format(d),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

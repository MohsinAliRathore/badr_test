import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/async_body.dart';
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  if (state.live)
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Chip(
                        avatar: Icon(Icons.bolt, size: 16),
                        label: Text('Live'),
                        visualDensity: VisualDensity.compact,
                      ),
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
      _KpiTile('Completed', '${snapshot.trips.completed}', Icons.check_circle_outline),
      _KpiTile(
        'Cancel rate',
        NumberFormat.percentPattern().format(snapshot.trips.cancellationRate),
        Icons.cancel_outlined,
      ),
      _KpiTile('Revenue', revenue, Icons.payments_outlined),
      _KpiTile('Drivers available', '${snapshot.drivers.available}', Icons.person_outline),
      _KpiTile('Drivers on trip', '${snapshot.drivers.onTrip}', Icons.route),
      _KpiTile('Open alerts', '${snapshot.openAlerts}', Icons.notification_important_outlined),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final cross = width > 1100
                ? 4
                : width > 700
                    ? 3
                    : 2;
            return GridView.count(
              crossAxisCount: cross,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: tiles,
            );
          },
        ),
        const SizedBox(height: 24),
        Text('Trips over time', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
              child: _SeriesChart(series: snapshot.series),
            ),
          ),
        ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (series.length / 4).clamp(1, 6).toDouble(),
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= series.length) return const SizedBox.shrink();
                final d = series[i].bucket.toLocal();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
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
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

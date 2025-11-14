import 'package:flutter/material.dart';
import '../utils/performance_metrics.dart';

/// Widget displaying performance metrics and statistics.
///
/// Shows key performance indicators including:
/// - Average response time
/// - Error rate
/// - Total requests
/// - Slowest requests
class PerformanceMetricsWidget extends StatelessWidget {
  final PerformanceMetrics metrics;
  final bool showDetails;

  const PerformanceMetricsWidget({
    super.key,
    required this.metrics,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildMetricsGrid(context),
            if (showDetails) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildTopEndpoints(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            'Avg Response',
            '${metrics.avgResponseTime.toStringAsFixed(0)}ms',
            Icons.speed,
            _getResponseTimeColor(metrics.avgResponseTime),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            context,
            'Error Rate',
            '${metrics.errorRate.toStringAsFixed(1)}%',
            Icons.error_outline,
            _getErrorRateColor(metrics.errorRate),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            context,
            'Total Requests',
            '${metrics.totalRequests}',
            Icons.analytics,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildTopEndpoints(BuildContext context) {
    final endpointCounts = metrics.getRequestsByEndpoint();
    final sortedEndpoints = endpointCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEndpoints = sortedEndpoints.take(5).toList();

    if (topEndpoints.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No request data available'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Endpoints',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...topEndpoints.map((entry) {
          final percentage =
              (entry.value / metrics.totalRequests * 100).toStringAsFixed(1);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: LinearProgressIndicator(
                    value: entry.value / sortedEndpoints.first.value,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: Text(
                    '${entry.value} ($percentage%)',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _getResponseTimeColor(double avgMs) {
    if (avgMs < 200) return Colors.green;
    if (avgMs < 500) return Colors.orange;
    return Colors.red;
  }

  Color _getErrorRateColor(double rate) {
    if (rate < 1) return Colors.green;
    if (rate < 5) return Colors.orange;
    return Colors.red;
  }
}

/// Widget displaying additional performance details.
class PerformanceDetailsWidget extends StatelessWidget {
  final PerformanceMetrics metrics;

  const PerformanceDetailsWidget({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Metrics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            _buildInfoRow(
              context,
              'P95 Response Time',
              '${metrics.p95ResponseTime.toStringAsFixed(0)}ms',
            ),
            _buildInfoRow(
              context,
              'P99 Response Time',
              '${metrics.p99ResponseTime.toStringAsFixed(0)}ms',
            ),
            _buildInfoRow(
              context,
              'Successful Requests',
              '${metrics.successfulRequests}',
            ),
            _buildInfoRow(
              context,
              'Failed Requests',
              '${metrics.failedRequests}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

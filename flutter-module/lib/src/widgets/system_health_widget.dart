import 'package:flutter/material.dart';
import '../utils/system_health.dart';

/// Widget displaying system health status.
///
/// Shows the overall health of the system and individual components
/// including Grist API, database, and authentication service.
class SystemHealthWidget extends StatelessWidget {
  final SystemHealth health;
  final VoidCallback? onRefresh;

  const SystemHealthWidget({
    super.key,
    required this.health,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(health.status);
    final statusIcon = _getStatusIcon(health.status);

    return Card(
      color: statusColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'System Health',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                    tooltip: 'Refresh health status',
                  ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            // Overall status
            Center(
              child: Column(
                children: [
                  Icon(
                    statusIcon,
                    size: 64,
                    color: statusColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    health.statusString.toUpperCase(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (health.lastHealthCheck != null)
                    Text(
                      'Last checked: ${_formatTime(health.lastHealthCheck!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Component health
            Text(
              'Components',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildComponentRow(
              context,
              'Grist API',
              health.gristApiReachable,
              Icons.cloud,
            ),
            _buildComponentRow(
              context,
              'Database',
              health.databaseConnected,
              Icons.storage,
            ),
            _buildComponentRow(
              context,
              'Authentication',
              health.authServiceHealthy,
              Icons.lock,
            ),
            // Health percentage
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: health.healthPercentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    color: statusColor,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${health.healthPercentage.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            // Error message if any
            if (health.lastError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        health.lastError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComponentRow(
    BuildContext context,
    String name,
    bool isHealthy,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: isHealthy ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Icon(
            isHealthy ? Icons.check_circle : Icons.error,
            color: isHealthy ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isHealthy ? 'Online' : 'Offline',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isHealthy ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return Colors.green;
      case HealthStatus.degraded:
        return Colors.orange;
      case HealthStatus.down:
        return Colors.red;
      case HealthStatus.unknown:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return Icons.check_circle;
      case HealthStatus.degraded:
        return Icons.warning;
      case HealthStatus.down:
        return Icons.error;
      case HealthStatus.unknown:
        return Icons.help_outline;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

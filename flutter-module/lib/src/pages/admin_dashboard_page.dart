import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../services/grist_service.dart';
import '../utils/performance_metrics.dart';
import '../utils/system_health.dart';
import '../widgets/active_users_widget.dart';
import '../widgets/performance_metrics_widget.dart';
import '../widgets/system_health_widget.dart';

/// Admin dashboard with system information and real-time metrics.
///
/// Features:
/// - Real-time auto-refresh (configurable interval)
/// - System information display
/// - Database overview
/// - Active users monitoring
/// - Performance metrics
/// - System health indicators
class AdminDashboardPage extends StatefulWidget {
  final PageConfig config;

  const AdminDashboardPage({
    super.key,
    required this.config,
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  List<Map<String, dynamic>> _tables = [];
  bool _isLoading = true;
  String? _error;
  DateTime? _lastRefresh;
  Timer? _refreshTimer;
  bool _autoRefreshEnabled = true;

  final PerformanceMetrics _performanceMetrics = PerformanceMetrics();
  final SystemHealth _systemHealth = SystemHealth();

  // Auto-refresh configuration
  int get _refreshIntervalSeconds {
    final config = widget.config.config?['auto_refresh'];
    if (config is Map) {
      return config['interval_seconds'] as int? ?? 30;
    }
    return 30;
  }

  bool get _showLastRefresh {
    final config = widget.config.config?['auto_refresh'];
    if (config is Map) {
      return config['show_last_refresh'] as bool? ?? true;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();

    if (!_autoRefreshEnabled) return;

    _refreshTimer = Timer.periodic(
      Duration(seconds: _refreshIntervalSeconds),
      (timer) {
        if (mounted && _autoRefreshEnabled) {
          _loadData(silent: true);
        }
      },
    );
  }

  void _toggleAutoRefresh() {
    setState(() {
      _autoRefreshEnabled = !_autoRefreshEnabled;
    });

    if (_autoRefreshEnabled) {
      _startAutoRefresh();
    } else {
      _refreshTimer?.cancel();
    }
  }

  Future<void> _checkSystemHealth() async {
    try {
      final gristService = context.read<GristService>();

      // Check Grist API
      try {
        await gristService.fetchTables();
        _systemHealth.updateGristApiHealth(true, message: 'API is responsive');
        _systemHealth.updateDatabaseHealth(true,
            message: 'Database connection successful');
      } catch (e) {
        _systemHealth.updateGristApiHealth(false,
            message: 'Failed to connect: $e');
        _systemHealth.updateDatabaseHealth(false,
            message: 'Database unreachable');
      }

      // Auth service is assumed healthy if we're logged in
      _systemHealth.updateAuthServiceHealth(true, message: 'User authenticated');

      _systemHealth.markHealthCheckComplete();
    } catch (e) {
      _systemHealth.markHealthCheckComplete(error: e.toString());
    }
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final startTime = DateTime.now();

    try {
      final gristService = context.read<GristService>();

      // Check system health
      await _checkSystemHealth();

      // Fetch tables
      final tables = await gristService.fetchTables();

      // Track fetch tables performance
      final fetchTablesTime = DateTime.now().difference(startTime);
      _performanceMetrics.logRequest(
        'fetchTables',
        fetchTablesTime,
        success: true,
      );

      // Fetch record counts for configured tables
      final widgets =
          widget.config.config?['widgets'] as List<dynamic>? ?? [];
      final dbSummaryWidget = widgets.firstWhere(
        (w) => w['type'] == 'database_summary',
        orElse: () => <String, dynamic>{},
      ) as Map<String, dynamic>?;

      if (dbSummaryWidget != null) {
        final gristTables =
            (dbSummaryWidget['grist_tables'] as List<dynamic>?)
                    ?.cast<String>() ??
                [];

        for (final tableName in gristTables) {
          final tableInfo = tables.firstWhere(
            (t) => t['id'] == tableName,
            orElse: () => {'id': tableName},
          );

          try {
            final recordsStartTime = DateTime.now();
            final records = await gristService.fetchRecords(tableName);
            tableInfo['record_count'] = records.length;

            // Track fetch records performance
            final recordsTime =
                DateTime.now().difference(recordsStartTime);
            _performanceMetrics.logRequest(
              'fetchRecords:$tableName',
              recordsTime,
              success: true,
            );
          } catch (e) {
            tableInfo['record_count'] = 'Error';
            _performanceMetrics.logRequest(
              'fetchRecords:$tableName',
              DateTime.now().difference(startTime),
              success: false,
              errorMessage: e.toString(),
            );
          }
        }

        // Filter to only show configured tables
        _tables = tables
            .where((t) => gristTables.contains(t['id']))
            .toList();
      }

      setState(() {
        _isLoading = false;
        _lastRefresh = DateTime.now();
      });
    } catch (e) {
      final errorTime = DateTime.now().difference(startTime);
      _performanceMetrics.logRequest(
        'loadData',
        errorTime,
        success: false,
        errorMessage: e.toString(),
      );

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final appConfig = context.read<AppConfig>();

    return RefreshIndicator(
      onRefresh: () => _loadData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header with auto-refresh controls
          _buildHeader(context),
          const SizedBox(height: 16),

          // System Health Widget
          SystemHealthWidget(
            health: _systemHealth,
            onRefresh: _checkSystemHealth,
          ),
          const SizedBox(height: 16),

          // Performance Metrics Widget
          PerformanceMetricsWidget(
            metrics: _performanceMetrics,
            showDetails: true,
          ),
          const SizedBox(height: 16),

          // Active Users Widget
          const ActiveUsersWidget(
            showInactive: false,
            maxDisplay: 10,
          ),
          const SizedBox(height: 16),

          // System info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  _buildInfoRow('Application', appConfig.app.name),
                  _buildInfoRow('Version', appConfig.app.version),
                  _buildInfoRow(
                      'Grist Document', appConfig.grist.documentId),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Database summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Database Overview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  if (_tables.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text('No tables configured'),
                      ),
                    )
                  else
                    ..._tables.map((table) {
                      return ListTile(
                        leading: const Icon(Icons.table_chart),
                        title: Text(table['id'] as String? ?? 'Unknown'),
                        trailing: Text(
                          '${table['record_count']} records',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_showLastRefresh && _lastRefresh != null)
                  Text(
                    'Last refresh: ${_formatRefreshTime(_lastRefresh!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            Row(
              children: [
                // Auto-refresh toggle
                Tooltip(
                  message: _autoRefreshEnabled
                      ? 'Disable auto-refresh'
                      : 'Enable auto-refresh',
                  child: IconButton(
                    icon: Icon(
                      _autoRefreshEnabled
                          ? Icons.pause_circle
                          : Icons.play_circle,
                    ),
                    onPressed: _toggleAutoRefresh,
                  ),
                ),
                // Manual refresh button
                Tooltip(
                  message: 'Refresh now',
                  child: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => _loadData(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatRefreshTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }
}

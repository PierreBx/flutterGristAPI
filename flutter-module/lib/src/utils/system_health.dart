/// System health status values.
enum HealthStatus {
  healthy,
  degraded,
  down,
  unknown,
}

/// Represents the health of a specific component.
class ComponentHealth {
  final String name;
  final bool isHealthy;
  final String? message;
  final DateTime lastChecked;

  ComponentHealth({
    required this.name,
    required this.isHealthy,
    this.message,
    DateTime? lastChecked,
  }) : lastChecked = lastChecked ?? DateTime.now();
}

/// System health checker for monitoring application health.
///
/// Tracks the health of various system components including:
/// - Grist API connectivity
/// - Database connectivity
/// - Authentication service
class SystemHealth {
  bool _gristApiReachable = false;
  bool _databaseConnected = false;
  bool _authServiceHealthy = true;
  DateTime? _lastHealthCheck;
  String? _lastError;

  final List<ComponentHealth> _components = [];

  /// Check if Grist API is reachable.
  bool get gristApiReachable => _gristApiReachable;

  /// Check if database is connected.
  bool get databaseConnected => _databaseConnected;

  /// Check if auth service is healthy.
  bool get authServiceHealthy => _authServiceHealthy;

  /// Get last health check timestamp.
  DateTime? get lastHealthCheck => _lastHealthCheck;

  /// Get last error message.
  String? get lastError => _lastError;

  /// Get all component health statuses.
  List<ComponentHealth> get components => List.unmodifiable(_components);

  /// Get overall system status.
  HealthStatus get status {
    if (_lastHealthCheck == null) return HealthStatus.unknown;

    if (_gristApiReachable && _databaseConnected && _authServiceHealthy) {
      return HealthStatus.healthy;
    } else if (_gristApiReachable || _databaseConnected) {
      return HealthStatus.degraded;
    } else {
      return HealthStatus.down;
    }
  }

  /// Get status as a user-friendly string.
  String get statusString {
    switch (status) {
      case HealthStatus.healthy:
        return 'Healthy';
      case HealthStatus.degraded:
        return 'Degraded';
      case HealthStatus.down:
        return 'Down';
      case HealthStatus.unknown:
        return 'Unknown';
    }
  }

  /// Update Grist API health status.
  void updateGristApiHealth(bool isHealthy, {String? message}) {
    _gristApiReachable = isHealthy;
    _updateComponent('Grist API', isHealthy, message);
  }

  /// Update database health status.
  void updateDatabaseHealth(bool isHealthy, {String? message}) {
    _databaseConnected = isHealthy;
    _updateComponent('Database', isHealthy, message);
  }

  /// Update auth service health status.
  void updateAuthServiceHealth(bool isHealthy, {String? message}) {
    _authServiceHealthy = isHealthy;
    _updateComponent('Authentication', isHealthy, message);
  }

  /// Update or add a component health status.
  void _updateComponent(String name, bool isHealthy, String? message) {
    _components.removeWhere((c) => c.name == name);
    _components.add(ComponentHealth(
      name: name,
      isHealthy: isHealthy,
      message: message,
    ));
  }

  /// Mark health check as complete.
  void markHealthCheckComplete({String? error}) {
    _lastHealthCheck = DateTime.now();
    _lastError = error;
  }

  /// Get time since last health check.
  Duration? getTimeSinceLastCheck() {
    if (_lastHealthCheck == null) return null;
    return DateTime.now().difference(_lastHealthCheck!);
  }

  /// Check if a health check is needed (older than threshold).
  bool needsHealthCheck({Duration threshold = const Duration(minutes: 1)}) {
    if (_lastHealthCheck == null) return true;
    final timeSince = getTimeSinceLastCheck();
    return timeSince != null && timeSince > threshold;
  }

  /// Reset all health data.
  void reset() {
    _gristApiReachable = false;
    _databaseConnected = false;
    _authServiceHealthy = true;
    _lastHealthCheck = null;
    _lastError = null;
    _components.clear();
  }

  /// Get a summary of all component statuses.
  Map<String, bool> getComponentSummary() {
    return {
      'Grist API': _gristApiReachable,
      'Database': _databaseConnected,
      'Authentication': _authServiceHealthy,
    };
  }

  /// Get percentage of healthy components.
  double get healthPercentage {
    if (_components.isEmpty) return 100.0;
    final healthyCount =
        _components.where((c) => c.isHealthy).length;
    return (healthyCount / _components.length) * 100;
  }
}

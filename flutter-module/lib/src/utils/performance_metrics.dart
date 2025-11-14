import 'dart:async';

/// Represents a single API request log entry.
class RequestLog {
  final String endpoint;
  final Duration duration;
  final DateTime timestamp;
  final bool success;
  final String? errorMessage;

  RequestLog({
    required this.endpoint,
    required this.duration,
    required this.timestamp,
    required this.success,
    this.errorMessage,
  });
}

/// Performance metrics tracker for monitoring API requests.
///
/// Tracks the last 1000 requests and provides aggregated statistics
/// including average response time, error rate, and request counts.
class PerformanceMetrics {
  static final PerformanceMetrics _instance = PerformanceMetrics._internal();
  factory PerformanceMetrics() => _instance;
  PerformanceMetrics._internal();

  final List<RequestLog> _recentRequests = [];
  final int _maxLogs = 1000;

  /// Log a new API request.
  void logRequest(
    String endpoint,
    Duration duration, {
    bool success = true,
    String? errorMessage,
  }) {
    _recentRequests.add(RequestLog(
      endpoint: endpoint,
      duration: duration,
      timestamp: DateTime.now(),
      success: success,
      errorMessage: errorMessage,
    ));

    // Keep only last N requests
    if (_recentRequests.length > _maxLogs) {
      _recentRequests.removeAt(0);
    }
  }

  /// Get all recent requests.
  List<RequestLog> get recentRequests => List.unmodifiable(_recentRequests);

  /// Get average response time in milliseconds.
  double get avgResponseTime {
    if (_recentRequests.isEmpty) return 0;
    final total = _recentRequests
        .map((r) => r.duration.inMilliseconds)
        .reduce((a, b) => a + b);
    return total / _recentRequests.length;
  }

  /// Get error rate as a percentage (0-100).
  double get errorRate {
    if (_recentRequests.isEmpty) return 0;
    final errors = _recentRequests.where((r) => !r.success).length;
    return (errors / _recentRequests.length) * 100;
  }

  /// Get total number of requests tracked.
  int get totalRequests => _recentRequests.length;

  /// Get number of successful requests.
  int get successfulRequests =>
      _recentRequests.where((r) => r.success).length;

  /// Get number of failed requests.
  int get failedRequests => _recentRequests.where((r) => !r.success).length;

  /// Get requests in the last N minutes.
  List<RequestLog> getRequestsSince(Duration duration) {
    final cutoff = DateTime.now().subtract(duration);
    return _recentRequests.where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  /// Get requests per endpoint with counts.
  Map<String, int> getRequestsByEndpoint() {
    final counts = <String, int>{};
    for (final request in _recentRequests) {
      counts[request.endpoint] = (counts[request.endpoint] ?? 0) + 1;
    }
    return counts;
  }

  /// Get slowest requests (top N).
  List<RequestLog> getSlowestRequests({int limit = 10}) {
    final sorted = List<RequestLog>.from(_recentRequests)
      ..sort((a, b) => b.duration.compareTo(a.duration));
    return sorted.take(limit).toList();
  }

  /// Get p95 response time (95th percentile) in milliseconds.
  double get p95ResponseTime {
    if (_recentRequests.isEmpty) return 0;
    final sorted = _recentRequests
        .map((r) => r.duration.inMilliseconds)
        .toList()
      ..sort();
    final index = (sorted.length * 0.95).floor();
    return sorted[index].toDouble();
  }

  /// Get p99 response time (99th percentile) in milliseconds.
  double get p99ResponseTime {
    if (_recentRequests.isEmpty) return 0;
    final sorted = _recentRequests
        .map((r) => r.duration.inMilliseconds)
        .toList()
      ..sort();
    final index = (sorted.length * 0.99).floor();
    return sorted[index].toDouble();
  }

  /// Clear all metrics.
  void clear() {
    _recentRequests.clear();
  }

  /// Get requests per minute for the last N minutes.
  Map<int, int> getRequestsPerMinute({int minutes = 60}) {
    final now = DateTime.now();
    final counts = <int, int>{};

    for (int i = 0; i < minutes; i++) {
      counts[i] = 0;
    }

    for (final request in _recentRequests) {
      final diff = now.difference(request.timestamp).inMinutes;
      if (diff < minutes) {
        counts[diff] = (counts[diff] ?? 0) + 1;
      }
    }

    return counts;
  }
}

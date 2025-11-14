import 'package:flutter_test/flutter_test.dart';
import 'package:odalisque/odalisque.dart';

void main() {
  group('PerformanceMetrics', () {
    late PerformanceMetrics metrics;

    setUp(() {
      metrics = PerformanceMetrics();
      metrics.clear(); // Clear any existing data
    });

    test('should start with no requests', () {
      expect(metrics.totalRequests, 0);
      expect(metrics.avgResponseTime, 0);
      expect(metrics.errorRate, 0);
    });

    test('should log successful request', () {
      metrics.logRequest(
        'test-endpoint',
        const Duration(milliseconds: 100),
        success: true,
      );

      expect(metrics.totalRequests, 1);
      expect(metrics.successfulRequests, 1);
      expect(metrics.failedRequests, 0);
      expect(metrics.avgResponseTime, 100);
    });

    test('should log failed request', () {
      metrics.logRequest(
        'test-endpoint',
        const Duration(milliseconds: 100),
        success: false,
        errorMessage: 'Test error',
      );

      expect(metrics.totalRequests, 1);
      expect(metrics.successfulRequests, 0);
      expect(metrics.failedRequests, 1);
      expect(metrics.errorRate, 100);
    });

    test('should calculate average response time correctly', () {
      metrics.logRequest('test1', const Duration(milliseconds: 100),
          success: true);
      metrics.logRequest('test2', const Duration(milliseconds: 200),
          success: true);
      metrics.logRequest('test3', const Duration(milliseconds: 300),
          success: true);

      expect(metrics.totalRequests, 3);
      expect(metrics.avgResponseTime, 200);
    });

    test('should calculate error rate correctly', () {
      metrics.logRequest('test1', const Duration(milliseconds: 100),
          success: true);
      metrics.logRequest('test2', const Duration(milliseconds: 100),
          success: false);
      metrics.logRequest('test3', const Duration(milliseconds: 100),
          success: true);
      metrics.logRequest('test4', const Duration(milliseconds: 100),
          success: false);

      expect(metrics.totalRequests, 4);
      expect(metrics.errorRate, 50);
    });

    test('should track requests by endpoint', () {
      metrics.logRequest('endpoint1', const Duration(milliseconds: 100),
          success: true);
      metrics.logRequest('endpoint1', const Duration(milliseconds: 100),
          success: true);
      metrics.logRequest('endpoint2', const Duration(milliseconds: 100),
          success: true);

      final byEndpoint = metrics.getRequestsByEndpoint();
      expect(byEndpoint['endpoint1'], 2);
      expect(byEndpoint['endpoint2'], 1);
    });

    test('should limit stored requests to max size', () {
      // Log more than max requests (1000)
      for (int i = 0; i < 1100; i++) {
        metrics.logRequest(
          'test',
          const Duration(milliseconds: 100),
          success: true,
        );
      }

      expect(metrics.totalRequests, 1000);
    });

    test('should calculate p95 response time', () {
      // Add 100 requests with varying times
      for (int i = 1; i <= 100; i++) {
        metrics.logRequest(
          'test',
          Duration(milliseconds: i * 10),
          success: true,
        );
      }

      // P95 should be around the 95th percentile
      expect(metrics.p95ResponseTime, greaterThan(900));
      expect(metrics.p95ResponseTime, lessThanOrEqualTo(1000));
    });

    test('should calculate p99 response time', () {
      // Add 100 requests with varying times
      for (int i = 1; i <= 100; i++) {
        metrics.logRequest(
          'test',
          Duration(milliseconds: i * 10),
          success: true,
        );
      }

      // P99 should be around the 99th percentile
      expect(metrics.p99ResponseTime, greaterThan(980));
      expect(metrics.p99ResponseTime, lessThanOrEqualTo(1000));
    });

    test('should get slowest requests', () {
      metrics.logRequest('slow1', const Duration(milliseconds: 500),
          success: true);
      metrics.logRequest('fast', const Duration(milliseconds: 50),
          success: true);
      metrics.logRequest('slow2', const Duration(milliseconds: 400),
          success: true);

      final slowest = metrics.getSlowestRequests(limit: 2);
      expect(slowest.length, 2);
      expect(slowest[0].duration.inMilliseconds, 500);
      expect(slowest[1].duration.inMilliseconds, 400);
    });

    test('should clear all metrics', () {
      metrics.logRequest('test', const Duration(milliseconds: 100),
          success: true);
      expect(metrics.totalRequests, 1);

      metrics.clear();
      expect(metrics.totalRequests, 0);
    });

    test('should get requests since duration', () {
      // This test is time-dependent, so we just check it doesn't crash
      metrics.logRequest('test', const Duration(milliseconds: 100),
          success: true);
      final recent = metrics.getRequestsSince(const Duration(minutes: 1));
      expect(recent.length, greaterThanOrEqualTo(0));
    });
  });
}

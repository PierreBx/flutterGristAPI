import 'package:flutter_test/flutter_test.dart';
import 'package:odalisque/odalisque.dart';

void main() {
  group('SystemHealth', () {
    late SystemHealth health;

    setUp(() {
      health = SystemHealth();
      health.reset(); // Reset state
    });

    test('should start with unknown status', () {
      expect(health.status, HealthStatus.unknown);
      expect(health.statusString, 'Unknown');
    });

    test('should update Grist API health', () {
      health.updateGristApiHealth(true, message: 'API is working');

      expect(health.gristApiReachable, true);
      expect(health.components.length, 1);
      expect(health.components.first.name, 'Grist API');
      expect(health.components.first.isHealthy, true);
    });

    test('should update database health', () {
      health.updateDatabaseHealth(false, message: 'Database error');

      expect(health.databaseConnected, false);
      expect(health.components.length, 1);
      expect(health.components.first.name, 'Database');
      expect(health.components.first.isHealthy, false);
    });

    test('should update auth service health', () {
      health.updateAuthServiceHealth(true, message: 'Auth OK');

      expect(health.authServiceHealthy, true);
      expect(health.components.length, 1);
      expect(health.components.first.name, 'Authentication');
    });

    test('should show healthy status when all components are healthy', () {
      health.updateGristApiHealth(true);
      health.updateDatabaseHealth(true);
      health.updateAuthServiceHealth(true);
      health.markHealthCheckComplete();

      expect(health.status, HealthStatus.healthy);
      expect(health.statusString, 'Healthy');
      expect(health.healthPercentage, 100.0);
    });

    test('should show degraded status when some components are unhealthy', () {
      health.updateGristApiHealth(true);
      health.updateDatabaseHealth(false);
      health.updateAuthServiceHealth(true);
      health.markHealthCheckComplete();

      expect(health.status, HealthStatus.degraded);
      expect(health.statusString, 'Degraded');
      expect(health.healthPercentage, closeTo(66.67, 0.01));
    });

    test('should show down status when critical components are down', () {
      health.updateGristApiHealth(false);
      health.updateDatabaseHealth(false);
      health.updateAuthServiceHealth(true);
      health.markHealthCheckComplete();

      expect(health.status, HealthStatus.down);
      expect(health.statusString, 'Down');
    });

    test('should track last health check time', () {
      expect(health.lastHealthCheck, isNull);

      health.markHealthCheckComplete();

      expect(health.lastHealthCheck, isNotNull);
    });

    test('should track error messages', () {
      health.markHealthCheckComplete(error: 'Connection failed');

      expect(health.lastError, 'Connection failed');
    });

    test('should determine if health check is needed', () {
      expect(health.needsHealthCheck(), true);

      health.markHealthCheckComplete();
      expect(health.needsHealthCheck(), false);
    });

    test('should reset all health data', () {
      health.updateGristApiHealth(true);
      health.updateDatabaseHealth(true);
      health.markHealthCheckComplete();

      health.reset();

      expect(health.gristApiReachable, false);
      expect(health.databaseConnected, false);
      expect(health.authServiceHealthy, true); // Defaults to true
      expect(health.lastHealthCheck, isNull);
      expect(health.components.isEmpty, true);
    });

    test('should get component summary', () {
      health.updateGristApiHealth(true);
      health.updateDatabaseHealth(false);
      health.updateAuthServiceHealth(true);

      final summary = health.getComponentSummary();

      expect(summary['Grist API'], true);
      expect(summary['Database'], false);
      expect(summary['Authentication'], true);
    });

    test('should calculate health percentage correctly', () {
      health.updateGristApiHealth(true);
      health.updateDatabaseHealth(false);
      health.updateAuthServiceHealth(true);

      // 2 out of 3 healthy = 66.67%
      expect(health.healthPercentage, closeTo(66.67, 0.01));
    });

    test('should replace component on update', () {
      health.updateGristApiHealth(true, message: 'First check');
      expect(health.components.length, 1);

      health.updateGristApiHealth(false, message: 'Second check');
      expect(health.components.length, 1);
      expect(health.components.first.isHealthy, false);
      expect(health.components.first.message, 'Second check');
    });
  });

  group('ComponentHealth', () {
    test('should create component with current timestamp', () {
      final component = ComponentHealth(
        name: 'Test',
        isHealthy: true,
      );

      expect(component.name, 'Test');
      expect(component.isHealthy, true);
      expect(component.lastChecked, isNotNull);
    });

    test('should use provided timestamp', () {
      final timestamp = DateTime(2024, 1, 1);
      final component = ComponentHealth(
        name: 'Test',
        isHealthy: true,
        lastChecked: timestamp,
      );

      expect(component.lastChecked, timestamp);
    });
  });
}

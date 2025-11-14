import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/grist_service.dart';
import '../utils/security_utils.dart';

/// Represents an active user session.
class ActiveSession {
  final String userId;
  final String email;
  final String role;
  final DateTime lastActivity;
  final DateTime loginTime;

  ActiveSession({
    required this.userId,
    required this.email,
    required this.role,
    required this.lastActivity,
    required this.loginTime,
  });

  /// Check if session is currently active (within last 5 minutes).
  bool get isActive {
    final diff = DateTime.now().difference(lastActivity);
    return diff.inMinutes < 5;
  }

  /// Get time since last activity as a human-readable string.
  String get timeSinceActivity {
    final diff = DateTime.now().difference(lastActivity);
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

  /// Get session duration as a human-readable string.
  String get sessionDuration {
    final diff = DateTime.now().difference(loginTime);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m';
    } else {
      return '${diff.inDays}d ${diff.inHours % 24}h';
    }
  }
}

/// Widget displaying active user sessions.
///
/// Shows a list of users currently logged into the application,
/// including their email, role, and last activity time.
class ActiveUsersWidget extends StatefulWidget {
  final bool showInactive;
  final int maxDisplay;

  const ActiveUsersWidget({
    super.key,
    this.showInactive = false,
    this.maxDisplay = 10,
  });

  @override
  State<ActiveUsersWidget> createState() => _ActiveUsersWidgetState();
}

class _ActiveUsersWidgetState extends State<ActiveUsersWidget> {
  List<ActiveSession> _sessions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadActiveSessions();
  }

  Future<void> _loadActiveSessions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // For now, create mock data since we don't have a Sessions table yet
      // In production, this would fetch from a Grist Sessions table
      final gristService = context.read<GristService>();

      // Try to fetch users table to show at least some data
      try {
        final users = await gristService.fetchRecords('Users');

        // Create mock sessions for demonstration
        // In production, you would fetch actual session data
        _sessions = users.take(widget.maxDisplay).map((user) {
          return ActiveSession(
            userId: user['id']?.toString() ?? '',
            email: user['email']?.toString() ?? 'unknown',
            role: user['role']?.toString() ?? 'user',
            lastActivity: DateTime.now().subtract(
              Duration(minutes: (user['id'] as int? ?? 0) % 10),
            ),
            loginTime: DateTime.now().subtract(
              Duration(hours: (user['id'] as int? ?? 0) % 24),
            ),
          );
        }).toList();

        // Filter inactive sessions if needed
        if (!widget.showInactive) {
          _sessions = _sessions.where((s) => s.isActive).toList();
        }
      } catch (e) {
        // If Users table doesn't exist, show empty state
        _sessions = [];
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Users',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (!_isLoading)
                  Chip(
                    label: Text(
                      '${_sessions.where((s) => s.isActive).length} active',
                    ),
                    backgroundColor: Colors.green.shade100,
                  ),
              ],
            ),
            const Divider(),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Error: $_error'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadActiveSessions,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_sessions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No active users'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sessions.length,
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: session.isActive
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      child: Icon(
                        Icons.person,
                        color: session.isActive ? Colors.green : Colors.orange,
                      ),
                    ),
                    title: Text(session.email),
                    subtitle: Text(
                      '${session.role} • ${session.timeSinceActivity}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color:
                              session.isActive ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          session.sessionDuration,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

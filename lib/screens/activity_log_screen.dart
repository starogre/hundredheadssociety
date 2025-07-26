import 'package:flutter/material.dart';
import '../services/activity_log_service.dart';
import '../models/activity_log_model.dart';
import '../theme/app_theme.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ActivityLogService _activityLogService = ActivityLogService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      backgroundColor: AppColors.cream,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              color: AppColors.lightCream,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history, color: AppColors.forestGreen, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Admin & Moderator Activity',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.forestGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track important actions performed by admins and moderators',
                      style: TextStyle(color: AppColors.forestGreen.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Activity Log List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Activity',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<List<ActivityLogModel>>(
                      stream: _activityLogService.getActivityLogs(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final activityLogs = snapshot.data!;

                        if (activityLogs.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(Icons.history, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No activity logged yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Activity will appear here as admins and moderators perform actions',
                                    style: TextStyle(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: activityLogs.length,
                          itemBuilder: (context, index) {
                            final log = activityLogs[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getActionColor(log.action),
                                  child: Icon(
                                    _getActionIcon(log.action),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  log.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  _formatTimestamp(log.timestamp),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: _getActionBadge(log.action),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'user_approved':
        return Colors.green;
      case 'user_signup':
        return Colors.blue;
      case 'user_deleted':
        return Colors.red;
      case 'user_edited':
        return Colors.orange;
      case 'role_changed':
        return Colors.purple;
      case 'moderator_granted':
        return Colors.indigo;
      case 'moderator_removed':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'user_approved':
        return Icons.check_circle;
      case 'user_signup':
        return Icons.person_add;
      case 'user_deleted':
        return Icons.delete;
      case 'user_edited':
        return Icons.edit;
      case 'role_changed':
        return Icons.swap_horiz;
      case 'moderator_granted':
        return Icons.admin_panel_settings;
      case 'moderator_removed':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.info;
    }
  }

  Widget? _getActionBadge(String action) {
    switch (action) {
      case 'user_approved':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'APPROVED',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case 'user_deleted':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'DELETED',
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case 'role_changed':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'ROLE CHANGE',
            style: TextStyle(
              color: Colors.purple.shade700,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      default:
        return null;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
} 
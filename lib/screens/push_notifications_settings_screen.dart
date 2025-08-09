import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class PushNotificationsSettingsScreen extends StatefulWidget {
  const PushNotificationsSettingsScreen({super.key});

  @override
  State<PushNotificationsSettingsScreen> createState() => _PushNotificationsSettingsScreenState();
}

class _PushNotificationsSettingsScreenState extends State<PushNotificationsSettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _error;
  Map<String, bool> _notificationPreferences = {};

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final preferences = Map<String, bool>.from(userData['notificationPreferences'] ?? {});
          
          setState(() {
            _notificationPreferences = preferences;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load notification preferences: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateNotificationPreference(String type, bool enabled) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user != null) {
        setState(() {
          _notificationPreferences[type] = enabled;
        });

        await _firestore.collection('users').doc(user.uid).update({
          'notificationPreferences.$type': enabled,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${enabled ? 'Enabled' : 'Disabled'} $type notifications'),
            backgroundColor: enabled ? AppColors.forestGreen : Colors.grey,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to update notification preference: $e';
      });
      
      // Revert the change on error
      setState(() {
        _notificationPreferences[type] = !enabled;
      });
    }
  }

  List<NotificationSetting> _getNotificationSettings(UserModel user) {
    final settings = <NotificationSetting>[];

    // Common notifications for all users
    settings.addAll([
      NotificationSetting(
        type: 'session_reminder',
        title: 'Session Reminders',
        description: 'Get reminded about upcoming weekly sessions',
        icon: Icons.event,
        enabled: _notificationPreferences['session_reminder'] ?? true,
      ),
      NotificationSetting(
        type: 'rsvp_confirmation',
        title: 'RSVP Confirmations',
        description: 'Know when your session RSVP is confirmed',
        icon: Icons.check_circle,
        enabled: _notificationPreferences['rsvp_confirmation'] ?? true,
      ),
      NotificationSetting(
        type: 'rsvp_reminder',
        title: 'RSVP Reminders',
        description: 'Get reminded to RSVP for upcoming sessions',
        icon: Icons.schedule,
        enabled: _notificationPreferences['rsvp_reminder'] ?? true,
      ),
      NotificationSetting(
        type: 'session_cancelled',
        title: 'Session Cancellations',
        description: 'Get notified when sessions are cancelled',
        icon: Icons.cancel,
        enabled: _notificationPreferences['session_cancelled'] ?? true,
      ),
      NotificationSetting(
        type: 'voting_reminder',
        title: 'Voting Reminders',
        description: 'Get reminded to vote for your favorite portraits',
        icon: Icons.how_to_vote,
        enabled: _notificationPreferences['voting_reminder'] ?? true,
      ),
      NotificationSetting(
        type: 'session_completed',
        title: 'Session Completion',
        description: 'Get notified when weekly sessions are completed',
        icon: Icons.celebration,
        enabled: _notificationPreferences['session_completed'] ?? true,
      ),
      NotificationSetting(
        type: 'award_notification',
        title: 'Award Notifications',
        description: 'Celebrate when you win awards',
        icon: Icons.emoji_events,
        enabled: _notificationPreferences['award_notification'] ?? true,
      ),
      NotificationSetting(
        type: 'milestone',
        title: 'Milestone Celebrations',
        description: 'Get notified when you reach portrait or participation milestones',
        icon: Icons.star,
        enabled: _notificationPreferences['milestone'] ?? true,
      ),
    ]);

    // Artist-specific notifications
    if (user.isArtist) {
      settings.addAll([
        NotificationSetting(
          type: 'upload_deadline',
          title: 'Upload Deadlines',
          description: 'Get reminded to upload your portraits before the deadline',
          icon: Icons.upload,
          enabled: _notificationPreferences['upload_deadline'] ?? true,
        ),
      ]);
    }

    // Admin/Moderator-specific notifications
    if (user.hasModeratorAccess) {
      settings.addAll([
        NotificationSetting(
          type: 'new_artist_signup',
          title: 'New Artist Signups',
          description: 'Get notified when new artists request approval',
          icon: Icons.person_add,
          enabled: _notificationPreferences['new_artist_signup'] ?? true,
        ),
        NotificationSetting(
          type: 'upgrade_request',
          title: 'Upgrade Requests',
          description: 'Get notified when users request role upgrades',
          icon: Icons.upgrade,
          enabled: _notificationPreferences['upgrade_request'] ?? true,
        ),
        NotificationSetting(
          type: 'admin_reminder',
          title: 'Admin Reminders',
          description: 'Get reminded to approve users and start sessions',
          icon: Icons.admin_panel_settings,
          enabled: _notificationPreferences['admin_reminder'] ?? true,
        ),
      ]);
    }

    return settings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Notifications'),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: AppColors.white,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.userData;
          
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading settings',
                    style: TextStyle(fontSize: 18, color: Colors.red[300]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadNotificationPreferences,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (user == null) {
            return const Center(
              child: Text('User not found'),
            );
          }

          final notificationSettings = _getNotificationSettings(user);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications, color: AppColors.forestGreen),
                        const SizedBox(width: 8),
                        const Text(
                          'Notification Preferences',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Control which push notifications you receive. In-app notifications will always be available in your notifications tab.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Notification settings
              ...notificationSettings.map((setting) => _NotificationSettingTile(
                setting: setting,
                onChanged: (enabled) => _updateNotificationPreference(setting.type, enabled),
              )),
              
              const SizedBox(height: 24),
              
              // Info section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                                            const Text(
                      'About Push Notifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• These settings only control push notifications (alerts on your device)\n'
                      '• In-app notifications will always be available in your notifications tab\n'
                      '• You can change these settings at any time\n'
                      '• Changes take effect immediately for new notifications',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class NotificationSetting {
  final String type;
  final String title;
  final String description;
  final IconData icon;
  final bool enabled;

  NotificationSetting({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.enabled,
  });
}

class _NotificationSettingTile extends StatelessWidget {
  final NotificationSetting setting;
  final ValueChanged<bool> onChanged;

  const _NotificationSettingTile({
    required this.setting,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(setting.icon, color: AppColors.forestGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                setting.title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            setting.description,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        value: setting.enabled,
        onChanged: onChanged,
        activeColor: AppColors.forestGreen,
      ),
    );
  }
} 
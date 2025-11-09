import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/auth_provider.dart';
import '../services/push_notification_service.dart';
import 'user_management_screen.dart';
import 'app_updates_screen.dart';
import 'about_screen.dart';
import 'activity_log_screen.dart';
import 'model_management_screen.dart';
import 'test_notifications_screen.dart';
import 'push_notifications_settings_screen.dart';
import 'user_data_repair_screen.dart';
import 'rsvp_debug_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final userData = authProvider.userData;
          final isAdmin = userData?.isAdmin ?? false;
          final isModerator = userData?.isModerator ?? false;
          
          return ListView(
            children: [
              // Show User Management for admins and moderators
              if (isAdmin || isModerator)
                ListTile(
                  leading: PhosphorIcon(PhosphorIconsDuotone.usersThree),
                  title: const Text('User Management'),
                  subtitle: const Text('Create and manage test users'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                    );
                  },
                ),
              // Show Activity Log for admins only
              if (isAdmin)
                ListTile(
                  leading: PhosphorIcon(PhosphorIconsDuotone.clockCounterClockwise),
                  title: const Text('Activity Log'),
                  subtitle: const Text('View admin and moderator actions'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ActivityLogScreen()),
                    );
                  },
                ),
              // Show User Data Repair for admins only
              if (isAdmin)
                ListTile(
                  leading: PhosphorIcon(PhosphorIconsDuotone.wrench),
                  title: const Text('User Data Repair'),
                  subtitle: const Text('Repair user data inconsistencies'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const UserDataRepairScreen()),
                    );
                  },
                ),
              // Show RSVP Debug Tools for admins only
              if (isAdmin)
                ListTile(
                  leading: PhosphorIcon(PhosphorIconsDuotone.bug),
                  title: const Text('RSVP Debug Tools'),
                  subtitle: const Text('Test and debug RSVP functionality'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const RSVPDebugScreen()),
                    );
                  },
                ),
              // Show Model Management for admins and moderators
              if (isAdmin || isModerator)
                ListTile(
                  leading: PhosphorIcon(PhosphorIconsDuotone.userPlus),
                  title: const Text('Manage Models'),
                  subtitle: const Text('Add, edit, and manage model data'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ModelManagementScreen()),
                    );
                  },
                ),
              // Save FCM Token for admins only
              if (isAdmin)
                ListTile(
                  leading: PhosphorIcon(PhosphorIconsDuotone.floppyDisk),
                  title: const Text('Save FCM Token'),
                  subtitle: const Text('Manually save FCM token to Firestore'),
                  onTap: () async {
                    try {
                      await PushNotificationService().saveFCMTokenForCurrentUser();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('FCM token saved successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error saving FCM token: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              // Test Notifications for admins only
              if (isAdmin)
                ListTile(
                  leading: PhosphorIcon(PhosphorIconsDuotone.flask),
                  title: const Text('Test Notifications'),
                  subtitle: const Text('Test various push notification types'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const TestNotificationsScreen()),
                    );
                  },
                ),
              // Push Notifications Settings
              ListTile(
                leading: PhosphorIcon(PhosphorIconsDuotone.bell),
                title: const Text('Push Notifications'),
                subtitle: const Text('Control which push notifications you receive'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const PushNotificationsSettingsScreen()),
                  );
                },
              ),
              // Show Model Data Injection for admins only (hidden for now)
              // if (isAdmin)
              //   ListTile(
              //     leading: PhosphorIcon(PhosphorIconsDuotone.database),
              //     title: const Text('Inject Model Data'),
              //     subtitle: const Text('Add all historical models to database'),
              //     onTap: () {
              //       Navigator.of(context).push(
              //         MaterialPageRoute(builder: (context) => const ModelDataInjectionScreen()),
              //       );
              //     },
              //   ),
              ListTile(
                leading: PhosphorIcon(PhosphorIconsDuotone.arrowsClockwise),
                title: const Text('App Updates'),
                subtitle: const Text('See what\'s new and what\'s coming soon'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AppUpdatesScreen()),
                  );
                },
              ),
              ListTile(
                leading: PhosphorIcon(PhosphorIconsDuotone.info),
                title: const Text('About 100 Heads Society'),
                subtitle: const Text('Privacy policy, terms of service, and website'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AboutScreen()),
                  );
                },
              ),
              ListTile(
                leading: PhosphorIcon(PhosphorIconsDuotone.signOut),
                title: const Text('Sign Out'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Provider.of<AuthProvider>(context, listen: false).signOut();
                            Navigator.of(context).pop(); // Pop settings screen
                          },
                          child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../services/push_notification_service.dart';
import 'user_management_screen.dart';
import 'app_updates_screen.dart';
import 'about_screen.dart';
import 'activity_log_screen.dart';
import 'model_management_screen.dart';
import 'model_data_injection_screen.dart';

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
                  leading: const Icon(Icons.manage_accounts),
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
                  leading: const Icon(Icons.history),
                  title: const Text('Activity Log'),
                  subtitle: const Text('View admin and moderator actions'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ActivityLogScreen()),
                    );
                  },
                ),
              // Show Model Management for admins and moderators
              if (isAdmin || isModerator)
                ListTile(
                  leading: const Icon(Icons.person_add),
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
                  leading: const Icon(Icons.save),
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
              // Test Push Notifications for admins only
              if (isAdmin)
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Test Push Notification'),
                  subtitle: const Text('Send a test notification to yourself'),
                  onTap: () async {
                    try {
                      final userData = authProvider.userData;
                      if (userData != null) {
                        // Create a test notification in Firestore - this will trigger the Cloud Function
                        final firestore = FirebaseFirestore.instance;
                        await firestore.collection('users').doc(userData.id).collection('notifications').add({
                          'userId': userData.id,
                          'type': 'test',
                          'title': 'Test Push Notification',
                          'message': 'This is a test notification from the app!',
                          'createdAt': FieldValue.serverTimestamp(),
                          'read': false,
                          'data': {
                            'testData': 'This is test data',
                            'timestamp': DateTime.now().toIso8601String(),
                          }
                        });
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Test notification sent! Check your phone for push notification.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error sending test notification: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              // Show Model Data Injection for admins only (hidden for now)
              // if (isAdmin)
              //   ListTile(
              //     leading: const Icon(Icons.data_usage),
              //     title: const Text('Inject Model Data'),
              //     subtitle: const Text('Add all historical models to database'),
              //     onTap: () {
              //       Navigator.of(context).push(
              //         MaterialPageRoute(builder: (context) => const ModelDataInjectionScreen()),
              //       );
              //     },
              //   ),
              ListTile(
                leading: const Icon(Icons.system_update),
                title: const Text('App Updates'),
                subtitle: const Text('See what\'s new and what\'s coming soon'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AppUpdatesScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About 100 Heads Society'),
                subtitle: const Text('Privacy policy, terms of service, and website'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AboutScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../services/push_notification_service.dart';

class TestNotificationsScreen extends StatelessWidget {
  const TestNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final userData = authProvider.userData;
          final isAdmin = userData?.isAdmin ?? false;
          
          if (!isAdmin) {
            return const Center(
              child: Text('Access denied. Admin privileges required.'),
            );
          }
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Push Notifications',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Send test notifications to yourself to verify the push notification system is working correctly.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.notifications, color: Colors.blue),
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
              ListTile(
                leading: const Icon(Icons.event, color: Colors.green),
                title: const Text('Test Session Reminder'),
                subtitle: const Text('Test session reminder notification'),
                onTap: () async {
                  try {
                    final userData = authProvider.userData;
                    if (userData != null) {
                      await PushNotificationService().sendSessionReminder(
                        userData.id,
                        'Weekly Session',
                        DateTime.now().add(const Duration(days: 1)),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Session reminder sent!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error sending session reminder: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.emoji_events, color: Colors.amber),
                title: const Text('Test Award Notification'),
                subtitle: const Text('Test award notification'),
                onTap: () async {
                  try {
                    final userData = authProvider.userData;
                    if (userData != null) {
                      await PushNotificationService().sendAwardNotification(
                        userData.id,
                        'Sharpened Eye',
                        'Best Likeness Award',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Award notification sent!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error sending award notification: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.celebration, color: Colors.purple),
                title: const Text('Test Milestone Notification'),
                subtitle: const Text('Test milestone notification'),
                onTap: () async {
                  try {
                    final userData = authProvider.userData;
                    if (userData != null) {
                      await PushNotificationService().sendMilestoneNotification(
                        userData.id,
                        'portraits',
                        50,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Milestone notification sent!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error sending milestone notification: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload, color: Colors.orange),
                title: const Text('Test Upload Deadline'),
                subtitle: const Text('Test upload deadline reminder'),
                onTap: () async {
                  try {
                    final userData = authProvider.userData;
                    if (userData != null) {
                      await PushNotificationService().sendUploadDeadlineReminder(
                        userData.id,
                        'Weekly Session',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Upload deadline reminder sent!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error sending upload deadline reminder: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.how_to_vote, color: Colors.indigo),
                title: const Text('Test Voting Reminder'),
                subtitle: const Text('Test voting reminder'),
                onTap: () async {
                  try {
                    final userData = authProvider.userData;
                    if (userData != null) {
                      await PushNotificationService().sendVotingReminder(
                        userData.id,
                        'Weekly Session',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Voting reminder sent!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error sending voting reminder: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_available, color: Colors.teal),
                title: const Text('Test RSVP Reminder'),
                subtitle: const Text('Test RSVP reminder with navigation'),
                onTap: () async {
                  try {
                    final userData = authProvider.userData;
                    if (userData != null) {
                      await PushNotificationService().sendRSVPReminder(
                        userData.id,
                        'Weekly Session',
                        DateTime.now().add(const Duration(days: 3)),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('RSVP reminder sent!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error sending RSVP reminder: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Test Session Cancellation'),
                subtitle: const Text('Test session cancellation notification'),
                onTap: () async {
                  try {
                    final userData = authProvider.userData;
                    if (userData != null) {
                      await PushNotificationService().sendSessionCancellationNotification(
                        userData.id,
                        'Weekly Session',
                        DateTime.now().add(const Duration(days: 2)),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Session cancellation notification sent!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error sending session cancellation notification: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
} 
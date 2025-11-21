import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/auth_provider.dart';
import '../services/push_notification_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import 'user_management_screen.dart';
import 'app_updates_screen.dart';
import 'about_screen.dart';
import 'activity_log_screen.dart';
import 'model_management_screen.dart';
import 'test_notifications_screen.dart';
import 'push_notifications_settings_screen.dart';
import 'user_data_repair_screen.dart';
import 'rsvp_debug_screen.dart';
import 'admin_reports_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final ReportService _reportService = ReportService();
  bool _isDeleting = false;

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
              // Show Content Reports for admins and moderators
              if (isAdmin || isModerator)
                ListTile(
                  leading: PhosphorIcon(PhosphorIconsDuotone.flag),
                  title: const Text('Content Reports'),
                  subtitle: const Text('Review user-reported content'),
                  trailing: StreamBuilder<int>(
                    stream: _reportService.getPendingReportCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      if (count == 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const AdminReportsScreen()),
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
              
              // Danger Zone Section
              const Divider(height: 32, thickness: 1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Danger Zone',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ListTile(
                leading: PhosphorIcon(
                  PhosphorIconsDuotone.warning,
                  color: Colors.red,
                  size: 28,
                ),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Permanently delete your account and all data',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: _isDeleting ? null : () => _showDeleteAccountDialog(context, authProvider),
              ),
              const Divider(height: 16, thickness: 1),
              
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

  // Show initial warning dialog for account deletion
  void _showDeleteAccountDialog(BuildContext context, AuthProvider authProvider) {
    final userData = authProvider.userData;
    
    // Check if user is admin
    if (userData?.isAdmin == true) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.block, color: Colors.red),
              SizedBox(width: 8),
              Text('Cannot Delete Admin Account'),
            ],
          ),
          content: const Text(
            'Admin accounts cannot be deleted through the app for security reasons. '
            'Please contact support if you need to delete your admin account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final portraitCount = userData?.portraitsCompleted ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Delete Account?'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will permanently delete:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text('• Your profile and all data'),
              Text('• All $portraitCount portraits you\'ve uploaded'),
              const Text('• All your submissions and votes'),
              const Text('• Any awards you\'ve earned'),
              const SizedBox(height: 16),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPasswordConfirmation(context, authProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  // Show password re-authentication dialog
  void _showPasswordConfirmation(BuildContext context, AuthProvider authProvider) {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please enter your password to confirm account deletion:'),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final password = passwordController.text.trim();
                if (password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your password'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                await _deleteAccount(context, authProvider, password);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Deletion'),
            ),
          ],
        ),
      ),
    );
  }

  // Execute account deletion
  Future<void> _deleteAccount(
    BuildContext context,
    AuthProvider authProvider,
    String password,
  ) async {
    final userId = authProvider.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No user signed in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Deleting your account...'),
            SizedBox(height: 8),
            Text(
              'This may take a few moments',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    try {
      // Step 1: Re-authenticate user
      await _authService.reauthenticateWithPassword(password);

      // Step 2: Delete all user data from Firestore
      await _userService.deleteUserAccount(userId);

      // Step 3: Delete Firebase Auth account
      await _authService.deleteFirebaseAuthAccount();

      // Step 4: Sign out (redundant but safe)
      await authProvider.signOut();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success message and navigate to login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: AppColors.forestGreen,
          ),
        );

        // Pop settings screen and any other screens to get back to login
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        String errorMessage = 'Failed to delete account';
        
        if (e.toString().contains('wrong-password')) {
          errorMessage = 'Incorrect password. Please try again.';
        } else if (e.toString().contains('requires-recent-login')) {
          errorMessage = 'Please sign out and sign in again before deleting your account.';
        } else {
          errorMessage = 'Failed to delete account: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }
}
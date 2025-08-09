import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';
import '../theme/app_theme.dart';

class NotificationPermissionDialog extends StatelessWidget {
  final VoidCallback? onAllow;
  final VoidCallback? onDeny;

  const NotificationPermissionDialog({
    super.key,
    this.onAllow,
    this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.notifications, color: AppColors.forestGreen),
          const SizedBox(width: 8),
          const Text('Stay Connected!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'We\'d like to send you notifications to keep you updated on:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Open Settings" to enable notifications in your device settings.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          _NotificationBenefit(
            icon: Icons.check_circle,
            title: 'RSVP Confirmations',
            description: 'Know when your session RSVP is confirmed',
          ),
          _NotificationBenefit(
            icon: Icons.event,
            title: 'Session Reminders',
            description: 'Get reminded about upcoming weekly sessions',
          ),
          _NotificationBenefit(
            icon: Icons.upload,
            title: 'Portrait Updates',
            description: 'Stay updated on new portrait uploads',
          ),
          _NotificationBenefit(
            icon: Icons.emoji_events,
            title: 'Award Notifications',
            description: 'Celebrate when you win awards',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onDeny?.call();
          },
          child: const Text('Not Now'),
        ),
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
                onAllow?.call();
                // Open app settings to enable notifications
                await AppSettings.openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              child: const Text('Open Settings'),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationBenefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _NotificationBenefit({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.forestGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 
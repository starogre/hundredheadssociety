import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Last updated: November 21, 2025',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '100 Heads Society ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Information We Collect',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Personal information (name, email address)\n'
              '• Profile information (bio, profile picture)\n'
              '• Portrait submissions and artwork\n'
              '• Usage data and app interactions\n'
              '• Session participation and voting data',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'How We Use Your Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• To provide and maintain our services\n'
              '• To process your account registration\n'
              '• To facilitate weekly sessions and voting\n'
              '• To communicate with you about updates\n'
              '• To improve our app and user experience',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Data Security',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We implement appropriate security measures to protect your personal information. However, no method of transmission over the internet is 100% secure.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Account Deletion',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can delete your account and all associated data at any time.\n\n'
              'In-App Deletion:\n'
              '1. Open Settings in the app\n'
              '2. Scroll to the bottom and tap "Delete Account"\n'
              '3. Confirm your decision\n'
              '4. Enter your password to verify\n\n'
              'What Gets Deleted:\n'
              '• Your profile (name, email, Instagram, profile picture)\n'
              '• All portraits you\'ve uploaded (images and data)\n'
              '• All your submissions and votes\n'
              '• Any awards you\'ve earned\n'
              '• Your authentication credentials\n\n'
              'Email Request:\n'
              'If you cannot access the app, you can email us at:\n'
              'support@100headsociety.com\n\n'
              'Subject: "Account Deletion Request"\n\n'
              'We will process your request within 30 days.\n\n'
              'Important: Account deletion is permanent and cannot be undone.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'If you have any questions about this Privacy Policy or wish to request account deletion, please contact us at:\n\n'
              'Email: support@100headsociety.com\n'
              'Website: https://100headsociety.com\n\n'
              'We respond to all inquiries within 48 hours.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
} 
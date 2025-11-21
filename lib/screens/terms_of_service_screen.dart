import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
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
              'Terms of Service',
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
              'By using the 100 Heads Society mobile application, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our app.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Acceptance of Terms',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'By downloading, installing, or using our app, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'User Accounts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• You must provide accurate and complete information when creating an account\n'
              '• You are responsible for maintaining the security of your account\n'
              '• You must be at least 18 years old to use this app\n'
              '• You may not share your account credentials with others',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Content Guidelines',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• All portrait submissions must be original artwork created by you\n'
              '• Portraits must be of consenting models from our sessions\n'
              '• No explicit, offensive, or inappropriate content\n'
              '• No harassment, bullying, or hate speech\n'
              '• No spam, advertising, or commercial content\n'
              '• No copyright violations or stolen artwork\n'
              '• You retain ownership of your artwork but grant us license to display it\n'
              '• We reserve the right to remove content that violates these terms',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Prohibited Activities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Harassment or bullying of other users\n'
              '• Spamming or excessive messaging\n'
              '• Attempting to gain unauthorized access to accounts\n'
              '• Violating any applicable laws or regulations',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Content Reporting & Moderation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Users can report inappropriate content or behavior\n'
              '• All reports are reviewed by moderators\n'
              '• False or malicious reports may result in penalties\n'
              '• We investigate all reports promptly and fairly\n'
              '• Actions may include warnings, content removal, or account suspension',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Termination & Suspension',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Account Suspension:\n'
              'We may temporarily suspend accounts for violations. Suspended users cannot access the app but may request account deletion.\n\n'
              'Account Deletion:\n'
              'You may delete your account at any time through Settings. We may also permanently delete accounts for serious or repeated violations.\n\n'
              'Appeals:\n'
              'Contact support@100headsociety.com to appeal suspensions or deletions.',
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
              'If you have any questions about these Terms of Service, please contact us at:\n\n'
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
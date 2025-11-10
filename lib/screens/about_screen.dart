import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'code_of_conduct_screen.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About 100 Heads Society'),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo/Title
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/app_icon.png',
                    width: 80,
                    height: 80,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '100 Heads Society',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.rustyOrange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Version 1.0.3',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // About Section
            const Text(
              'About Us',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '100 Heads Society is a community of artists and art appreciators who come together to create, share, and celebrate portrait art. Our weekly studio sessions provide a supportive environment for artists to practice their craft and receive feedback from peers.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Website Section
            const Text(
              'Visit Our Website',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'For more information about 100 Heads Society, visit our website to:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Subscribe to our email newsletter\n'
              '• Browse and purchase merchandise\n'
              '• Sign up for art classes and workshops\n'
              '• Learn about upcoming events\n'
              '• Connect with our community',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  print('Attempting to launch website...');
                  _launchWebsite(context, 'https://100headsociety.com');
                },
                icon: const Icon(Icons.language),
                label: const Text('Visit 100HeadsSociety.com'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Legal Section
            const Text(
              'Legal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip, color: AppColors.rustyOrange),
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('How we collect and use your data'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description, color: AppColors.rustyOrange),
                    title: const Text('Terms of Service'),
                    subtitle: const Text('Rules and guidelines for using our app'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const TermsOfServiceScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.groups, color: AppColors.rustyOrange),
                    title: const Text('Code of Conduct'),
                    subtitle: const Text('Community guidelines and expectations'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CodeOfConductScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Contact Section
            const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Have questions or feedback? Visit our website to get in touch with us!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  print('Attempting to launch website...');
                  _launchWebsite(context, 'https://100headsociety.com');
                },
                icon: const Icon(Icons.contact_support),
                label: const Text('Visit Our Website'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Footer
            Center(
              child: Column(
                children: [
                  const Text(
                    '© 2025 100 Heads Society',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Made with ❤️ for the art community',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchWebsite(BuildContext context, String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('Could not launch $url');
        // Fallback: try to launch in browser
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      print('Error launching URL: $e');
      // Show a snackbar or dialog to inform the user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open website: $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 
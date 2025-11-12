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
                    'Version 1.0.5',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // What's New Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.forestGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.celebration,
                        color: AppColors.rustyOrange,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'What\'s New in v1.0.5',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forestGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '🏆 Weekly Awards Reimagined',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Renamed from "Weekly Sessions" to better reflect competition\n'
                    '• Auto-select portrait for submission - no more dropdown menus!\n'
                    '• "This Week\'s Model" section shows who you\'re painting\n'
                    '• Streamlined submission flow - just add notes and submit\n'
                    '• Beautiful new zero-state designs with duotone icons',
                    style: TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '📱 My Heads Screen Enhancements',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Personalized title with achievement emoji (🌟 → 🐉 → 🔥 → 🚀)\n'
                    '• "Your Heads" shows your name with milestone emoji\n'
                    '• Horizontal white logo in app bar for cleaner branding\n'
                    '• Milestone progress now tracks to 100, 200, 300+ correctly',
                    style: TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '🎨 Portrait Previews & Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Week number badge now shows on portrait previews\n'
                    '• Swipe left/right to browse portraits (Tinder-style!)\n'
                    '• Position indicator shows where you are (45/100)\n'
                    '• Full-screen Edit Profile page (no more cramped dialog!)\n'
                    '• Better organized profile editing with larger previews',
                    style: TextStyle(fontSize: 15, height: 1.5),
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
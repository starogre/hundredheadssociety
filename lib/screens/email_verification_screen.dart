import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  bool _isResending = false;
  bool _isChecking = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Prevent back button
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 
                       MediaQuery.of(context).padding.top - 
                       kToolbarHeight - 48, // AppBar height + padding
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              const Icon(
                Icons.mark_email_unread,
                size: 80,
                color: AppColors.rustyOrange,
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Verify Your Email Address',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Please check your email and click the verification link to continue.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Email address display
              Text(
                'Email: ${user?.email ?? ''}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Spam folder instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 24,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '📧 Check your spam/junk folder!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Look for emails from "hundredheadssociety" or "noreply@firebaseapp.com"',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (authProvider.userData?.isAdmin == true)
                const Text(
                  'Admin users must verify their email on every login for security.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.rustyOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 24),

              // Instructions
              const Card(
                color: AppColors.lightCream,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'To complete your registration:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forestGreen,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '1. Check your email inbox\n'
                        '2. Click the verification link\n'
                        '3. Return to this app and tap "I\'ve Verified My Email"',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Check Verification Button
              ElevatedButton(
                onPressed: _isChecking ? null : _checkVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rustyOrange,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isChecking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : const Text(
                        'I\'ve Verified My Email',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),

              // Resend Email Button
              TextButton(
                onPressed: _isResending ? null : _resendVerificationEmail,
                child: _isResending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.rustyOrange),
                        ),
                      )
                    : const Text(
                        'Resend Verification Email',
                        style: TextStyle(
                          color: AppColors.rustyOrange,
                          fontSize: 16,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Debug Button (temporary)
              TextButton(
                onPressed: () {
                  print('=== DEBUG INFO ===');
                  print('Current user: ${authProvider.currentUser?.uid}');
                  print('Current user email: ${authProvider.currentUser?.email}');
                  print('Email verified: ${authProvider.currentUser?.emailVerified}');
                  print('User data: ${authProvider.userData?.toMap()}');
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Debug info printed to console'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                child: const Text(
                  'Debug Info (Check Console)',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sign Out Button
              TextButton(
                onPressed: () => _showSignOutDialog(context),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkVerification() async {
    setState(() {
      _isChecking = true;
    });

    try {
      print('=== CHECKING VERIFICATION ===');
      
      // Reload user to get latest verification status
      await _authService.reloadUser();
      
      if (_authService.isUserVerified()) {
        print('Firebase reports email as verified - updating Firestore timestamp');
        
        // Update Firestore to mark email as verified and set timestamp
        final user = _authService.currentUser;
        if (user != null) {
          await _authService.updateUserEmailVerificationStatus(user.uid, true);
          print('Updated verification timestamp in Firestore');
        }
        
        // Reload user data to trigger proper routing
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.reloadUserData();
          print('Reloaded user data after verification');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully! Welcome to 100 Heads Society!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('Firebase reports email as not verified');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email not verified yet. Please check your inbox and click the verification link.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error checking verification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking verification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
    });

    try {
      print('=== RESEND VERIFICATION DEBUG ===');
      print('Attempting to resend verification email...');
      await _authService.sendEmailVerification();
      print('Resend verification email completed');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Check your inbox and spam folder for emails from "hundredheadssociety" or "noreply@firebaseapp.com".'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('=== RESEND VERIFICATION ERROR ===');
      print('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending verification email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out? You\'ll need to verify your email again when you sign back in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class WaitingApprovalScreen extends StatelessWidget {
  const WaitingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userData = authProvider.userData;
        final status = userData?.status ?? 'pending';
        
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Status Icon
                    Icon(
                      status == 'denied' ? Icons.cancel : Icons.pending_actions,
                      size: 80,
                      color: status == 'denied' ? Colors.red : AppColors.forestGreen,
                    ),
                    const SizedBox(height: 32),
                    
                    // Title
                    Text(
                      status == 'denied' 
                        ? 'Registration Denied'
                        : 'Waiting for Approval',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Message
                    Text(
                      status == 'denied'
                        ? 'Your registration has been denied. Please contact 100 Heads Society for help!'
                        : 'Thank you for registering! Your account is currently being reviewed by the 100 Heads Society team. You will be notified once your account is approved.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.forestGreen.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // User Info Card
                    Card(
                      color: AppColors.forestGreen.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppColors.rustyOrange,
                              child: Text(
                                userData?.name.isNotEmpty == true 
                                  ? userData!.name[0].toUpperCase() 
                                  : '?',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              userData?.name ?? 'Unknown User',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userData?.email ?? '',
                              style: TextStyle(
                                color: AppColors.forestGreen.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Sign Out Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          authProvider.signOut();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.rustyOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 
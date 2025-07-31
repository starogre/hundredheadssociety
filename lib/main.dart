import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/portrait_provider.dart';
import 'providers/weekly_session_provider.dart';
import 'providers/model_provider.dart';
import 'services/push_notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/waiting_approval_screen.dart';
import 'screens/email_verification_screen.dart';
import 'theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize push notification service
  await PushNotificationService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => PortraitProvider()),
        ChangeNotifierProvider(create: (_) => WeeklySessionProvider()),
        ChangeNotifierProvider(create: (_) => ModelProvider()),
      ],
      child: MaterialApp(
        title: '100 Heads Society',
        theme: AppTheme.lightTheme,
        routes: {
          '/profile': (context) {
            final userId = ModalRoute.of(context)!.settings.arguments as String;
            return ProfileScreen(userId: userId);
          },
        },
        home: FutureBuilder(
          future: Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          ),
          builder: (context, snapshot) {
            // Show splash screen while loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            // Show error screen if initialization failed
            if (snapshot.hasError) {
              return Scaffold(
                backgroundColor: AppColors.cream,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: AppColors.rustyOrange),
                      const SizedBox(height: 16),
                      const Text(
                        'Firebase Error',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Firebase.initializeApp(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Firebase initialized successfully, show the app
            return Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (!authProvider.isInitialized || authProvider.isLoading) {
                  return const SplashScreen();
                }

                if (authProvider.isAuthenticated) {
                  final userData = authProvider.userData;
                  if (userData != null) {
                    // Check if user needs email verification
                    if (authProvider.needsEmailVerification) {
                      return const EmailVerificationScreen();
                    }
                    
                    if (userData.isAdmin) {
                      print('Routing to DashboardScreen (admin)');
                      print('Admin details:');
                      print('  - ID: ${userData.id}');
                      print('  - Name: ${userData.name}');
                      print('  - Email: ${userData.email}');
                      print('  - Status: ${userData.status}');
                      return const DashboardScreen();
                    }
                    
                    // For non-admin users, check role and status
                    if (userData.userRole == 'artist') {
                      // Artists need approval
                      if (userData.status == 'pending' || userData.status == 'denied') {
                        print('Routing to WaitingApprovalScreen (artist needs approval)');
                        return const WaitingApprovalScreen();
                      }
                      if (userData.status == 'approved') {
                        print('Routing to DashboardScreen (artist approved)');
                        return const DashboardScreen();
                      }
                    } else if (userData.userRole == 'art_appreciator') {
                      // Art appreciators can access immediately
                      print('Routing to DashboardScreen (art appreciator - no approval needed)');
                      return const DashboardScreen();
                    }
                    
                    print('No matching route found - showing splash screen');
                  }
                  // If userData is null, show splash/loading screen
                  return const SplashScreen();
                } else {
                  print('User not authenticated - showing login screen');
                  return const LoginScreen();
                }
              },
            );
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

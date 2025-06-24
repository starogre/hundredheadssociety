import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/portrait_provider.dart';
import 'providers/weekly_session_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Firebase initialized');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PortraitProvider()),
        ChangeNotifierProvider(create: (_) => WeeklySessionProvider()),
      ],
      child: MaterialApp(
        title: '100 Heads Society',
        theme: AppTheme.lightTheme,
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
                // Show loading while AuthProvider is initializing
                if (!authProvider.isInitialized) {
                  return const SplashScreen();
                }
                
                if (authProvider.isLoading) {
                  return const SplashScreen();
                }
                
                if (authProvider.isAuthenticated) {
                  return const DashboardScreen();
                } else {
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

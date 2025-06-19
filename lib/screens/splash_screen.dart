import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: Image.asset(
          'assets/images/splash_logo.gif',
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
} 
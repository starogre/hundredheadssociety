import 'package:flutter/material.dart';

class AppColors {
  static const cream = Color(0xFFFBF6E9);
  static const forestGreen = Color(0xFF2F5850);
  static const rustyOrange = Color(0xFFC4502D);
  static const black = Colors.black;
  static const white = Colors.white;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: ColorScheme.light(
        primary: AppColors.forestGreen,
        secondary: AppColors.rustyOrange,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        background: AppColors.cream,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.rustyOrange,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.black,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: AppColors.black,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: AppColors.black,
          fontSize: 14,
        ),
      ),
    );
  }
} 
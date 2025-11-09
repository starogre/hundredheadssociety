import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AppColors {
  static const cream = Color(0xFFFBF6E9);
  static const lightCream = Color(0xFFFFFCF5);
  static const forestGreen = Color(0xFF2F5850);
  static const rustyOrange = Color(0xFFC4502D);
  static const lightRustyOrange = Color(0xFFFFD6C2);
  static const black = Colors.black;
  static const white = Colors.white;
}

class AppFonts {
  // Centralized font family - change this in ONE place to swap fonts app-wide
  static const String primaryFont = 'Satoshi';
  
  // To try a different font later:
  // 1. Download the new font files
  // 2. Add them to assets/fonts/
  // 3. Update pubspec.yaml with the new font family
  // 4. Change 'Satoshi' above to the new font family name
}

class AppIcons {
  // Centralized icon styling - Phosphor Icons with duotone support
  
  // Default icon style (can be: regular, thin, light, bold, fill, duotone)
  static const PhosphorIconsStyle defaultStyle = PhosphorIconsStyle.duotone;
  
  // Default icon size
  static const double defaultSize = 24.0;
  static const double largeSize = 32.0;
  static const double smallSize = 20.0;
  
  // Helper method to create duotone icons with app colors
  static PhosphorIcon duotone(
    PhosphorIconData icon, {
    Color? primaryColor,
    Color? secondaryColor,
    double? size,
  }) {
    return PhosphorIcon(
      icon,
      color: primaryColor ?? AppColors.forestGreen,
      duotoneSecondaryColor: secondaryColor ?? AppColors.rustyOrange.withOpacity(0.3),
      size: size ?? defaultSize,
    );
  }
  
  // Helper for single-color icons
  static PhosphorIcon regular(
    PhosphorIconData icon, {
    Color? color,
    double? size,
  }) {
    return PhosphorIcon(
      icon,
      color: color ?? AppColors.forestGreen,
      size: size ?? defaultSize,
    );
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppFonts.primaryFont, // Apply Satoshi globally
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: ColorScheme.light(
        primary: AppColors.forestGreen,
        secondary: AppColors.rustyOrange,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        surface: AppColors.cream,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.primaryFont,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.rustyOrange,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontFamily: AppFonts.primaryFont,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontFamily: AppFonts.primaryFont,
          color: AppColors.black,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppFonts.primaryFont,
          color: AppColors.black,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          fontFamily: AppFonts.primaryFont,
          color: AppColors.black,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppFonts.primaryFont,
          color: AppColors.black,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
} 
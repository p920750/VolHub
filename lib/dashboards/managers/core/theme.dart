import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color midnightBlue = Color(0xFF011638);
  static const Color charcoalBlue = Color(0xFF2C3544); // Darkened for better contrast
  static const Color lightGrey = Color(0xFFE5E7EB); // Lighter gray for better contrast with dark text
  static const Color darkGrey = Color(0xFF4B5563); // Specific color for secondary text
  static const Color mintIce = Color(0xFFDFF8EB);
  static const Color hunterGreen = Color(0xFF1B432C); // Slightly darker
  static const Color offWhite = Color(0xFFF9FAFB); // Cleaner off-white
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.offWhite,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.midnightBlue,
        primary: AppColors.midnightBlue,
        onPrimary: Colors.white,
        secondary: AppColors.charcoalBlue,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: AppColors.midnightBlue,
        onSurfaceVariant: AppColors.darkGrey, // Standardized secondary text
        primaryContainer: AppColors.mintIce, 
        onPrimaryContainer: AppColors.hunterGreen,
        secondaryContainer: AppColors.lightGrey,
        onSecondaryContainer: AppColors.midnightBlue, // High contrast
        outlineVariant: Colors.grey[300],
      ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: AppColors.midnightBlue, 
        displayColor: AppColors.midnightBlue,
      ).copyWith(
        bodySmall: GoogleFonts.outfit(color: AppColors.darkGrey), // High contrast gray
        bodyMedium: GoogleFonts.outfit(color: AppColors.midnightBlue),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.midnightBlue,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.midnightBlue,
        indicatorColor: AppColors.mintIce,
        unselectedLabelTextStyle: TextStyle(color: Colors.white70),
        selectedLabelTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        unselectedIconTheme: IconThemeData(color: Colors.white70),
        selectedIconTheme: IconThemeData(color: AppColors.midnightBlue), // Icon on Mint indicator
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide.none, // Clean look, no borders by default
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    // Keeping a basic dark theme but arguably the "NexaVerse" look is specific
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.midnightBlue,
        brightness: Brightness.dark,
        surface: AppColors.midnightBlue, // Dark surface
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: const Color.fromARGB(255, 0, 225, 255), // Bright cyan
      secondary: const Color.fromARGB(255, 0, 255, 195), // Bright teal
      surface: Colors.white.withOpacity(0.08),
      background: const Color(0xFF1A1B1E), // Deep dark background
      error: const Color(0xFFFF5252),
      tertiary: const Color(0xFF4CAF50), // Neon green for accents
    ),
    scaffoldBackgroundColor: const Color(0xFF1A1B1E),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color.fromARGB(255, 36, 36, 36),
      elevation: 0,
      titleTextStyle: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white.withOpacity(0.07),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 16,
      ),
      bodyMedium: GoogleFonts.poppins(
        color: Colors.white70,
        fontSize: 14,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blue[400],
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color.fromARGB(255, 26, 26, 26),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue[400]!),
      ),
    ),
  );
}
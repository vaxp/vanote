import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Colors.blue[400]!,
      secondary: Colors.tealAccent[400]!,
      surface: Colors.white.withOpacity(0.1),
      background: const Color.fromARGB(255, 36, 36, 36),
      error: Colors.red[400]!,
    ),
    scaffoldBackgroundColor: const Color.fromARGB(255, 36, 36, 36),
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
      color: Colors.white.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
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
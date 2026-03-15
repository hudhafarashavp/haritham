import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(
    0xFF2E7FD6,
  ); // Using a vibrant blue-ish green for IG vibe or keep pure green
  static const Color harithamGreen = Color(0xFF1B5E20);
  static const Color backgroundWhite = Colors.white;
  static const Color softGrey = Color(0xFFF8F9FA);
  static const Color borderGrey = Color(0xFFDBDBDB);
  static const Color textBlack = Color(0xFF262626);
  static const Color textGrey = Color(0xFF8E8E8E);
  static const Color mintGreen = Color(0xFFE8F5E9);

  static const double borderRadius = 12.0;
  static const double padding = 16.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: mintGreen,
      colorScheme: ColorScheme.fromSeed(
        seedColor: harithamGreen,
        primary: harithamGreen,
        surface: mintGreen,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundWhite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textBlack,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textBlack),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundWhite,
        selectedItemColor: harithamGreen,
        unselectedItemColor: textGrey,
        selectedIconTheme: IconThemeData(size: 28),
        unselectedIconTheme: IconThemeData(size: 24),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: backgroundWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: borderGrey, width: 0.5),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textBlack, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(
          color: textBlack,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        bodyLarge: TextStyle(color: textBlack, fontSize: 16),
        bodyMedium: TextStyle(color: textBlack, fontSize: 14),
      ),
    );
  }

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: backgroundWhite,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: borderGrey, width: 0.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 10,
        spreadRadius: 1,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

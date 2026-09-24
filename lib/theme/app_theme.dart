import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors — Deep forest green (money/ledger), Burnished brass (CTA action accent),
  // crisp ledger paper & graphite.
  static const Color ledgerGreen = Color(0xFF143D2B); // Deep forest banknote green (Money & Hero)
  static const Color brassAccent = Color(0xFFB4782A); // Burnished brass (Single action accent / CTAs)
  static const Color brassAccentDark = Color(0xFFC88A32); // Brass for dark mode

  static const Color lightBackground = Color(0xFFF6F8F6); // Crisp ledger paper
  static const Color lightSurface = Color(0xFFFFFFFF); // Clean white card
  static const Color lightSurfaceVariant = Color(0xFFEBF1ED); // Soft ledger line
  static const Color lightOutline = Color(0xFFDDE6E0); // Ledger ruling
  static const Color lightTextMain = Color(0xFF0F1914); // Deep ledger ink black
  static const Color lightTextMuted = Color(0xFF5A6E64); // Ledger pencil / graphite

  static const Color darkBackground = Color(0xFF0C1310); // Deep midnight ink
  static const Color darkSurface = Color(0xFF141F18);
  static const Color darkSurfaceVariant = Color(0xFF1C2C23);
  static const Color darkOutline = Color(0xFF263B2F);
  static const Color darkTextMain = Color(0xFFEDF5F0);
  static const Color darkTextMuted = Color(0xFF8EA397);

  // Status colors (independent from brand & money colors)
  static const Color statusTodoBg = Color(0xFFF1F5F9);
  static const Color statusTodoText = Color(0xFF475569);
  static const Color statusInProgressBg = Color(0xFFFEF3C7);
  static const Color statusInProgressText = Color(0xFFB45309);
  static const Color statusDoneBg = Color(0xFFDCFCE7);
  static const Color statusDoneText = Color(0xFF15803D);
  static const Color statusOverdueBg = Color(0xFFFEE2E2);
  static const Color statusOverdueText = Color(0xFFB91C1C);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: ledgerGreen,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: ledgerGreen,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFD8EFE2),
        onPrimaryContainer: Color(0xFF0A2619),
        secondary: brassAccent,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFFDEFD9),
        onSecondaryContainer: Color(0xFF4A3008),
        tertiary: Color(0xFF2D5A46),
        onTertiary: Colors.white,
        error: Color(0xFFDC2626),
        onError: Colors.white,
        surface: lightSurface,
        onSurface: lightTextMain,
        surfaceContainerHighest: lightSurfaceVariant,
        outline: lightOutline,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightTextMain,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: lightTextMain,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: lightOutline),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightOutline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightOutline),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: brassAccent, width: 2),
        ),
        labelStyle: const TextStyle(color: lightTextMuted),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return const Color(0xFF94A3B8);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brassAccent;
          return const Color(0xFFE2E8F0);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brassAccent, // Action accent
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: ledgerGreen,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: ledgerGreen,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF123524),
        onPrimaryContainer: Color(0xFFD8EFE2),
        secondary: brassAccentDark,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF3D2706),
        onSecondaryContainer: Color(0xFFFDEFD9),
        tertiary: Color(0xFF34D399),
        onTertiary: Color(0xFF064E3B),
        error: Color(0xFFEF4444),
        onError: Colors.white,
        surface: darkSurface,
        onSurface: darkTextMain,
        surfaceContainerHighest: darkSurfaceVariant,
        outline: darkOutline,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkTextMain,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: darkTextMain,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: darkOutline),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkOutline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkOutline),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: brassAccentDark, width: 2),
        ),
        labelStyle: const TextStyle(color: darkTextMuted),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return const Color(0xFF64748B);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brassAccentDark;
          return const Color(0xFF1E293B);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brassAccentDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

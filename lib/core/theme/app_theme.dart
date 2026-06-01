import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Brand Colors (Deep Emerald Design System) ---
  static const Color primary = Color(0xFF064E3B);
  static const Color primaryContainer = Color(0xFF003527);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF80BEA6);

  static const Color secondary = Color(0xFF4B41E1);
  static const Color secondaryContainer = Color(0xFF645EFB);
  static const Color onSecondary = Color(0xFFFFFFFF);

  static const Color tertiary = Color(0xFF8D0028);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFFF929B);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);

  static const Color surface = Color(0xFFF8F9FA);
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF404944);
  static const Color surfaceContainer = Color(0xFFEDEEEF);
  static const Color surfaceContainerLow = Color(0xFFF3F4F5);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFE7E8E9);
  static const Color outline = Color(0xFF707974);
  static const Color outlineVariant = Color(0xFFBFC9C3);

  // Amount colors
  static const Color incomeColor = Color(0xFF064E3B);
  static const Color expenseColor = Color(0xFF8D0028);

  static ThemeData get lightTheme {
    final colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: Color(0xFFB0F0D6),
      onPrimaryContainer: Color(0xFF002117),
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: Color(0xFFE2DFFF),
      onSecondaryContainer: Color(0xFF0F0069),
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: Color(0xFFFFDADB),
      onTertiaryContainer: Color(0xFF40000D),
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: Color(0xFF93000A),
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      surfaceContainerHighest: Color(0xFFE1E3E4),
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainer: surfaceContainer,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainerLowest: surfaceContainerLowest,
      inverseSurface: Color(0xFF2E3132),
      onInverseSurface: Color(0xFFF0F1F2),
      inversePrimary: Color(0xFF95D3BA),
      scrim: Color(0xFF000000),
      shadow: Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      textTheme: _buildTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.getFont(
          'Geist',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        filled: false,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: onSurfaceVariant,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: outline,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shape: const StadiumBorder(),
          minimumSize: const Size(double.infinity, 52),
          textStyle: GoogleFonts.getFont(
            'Geist',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape: const StadiumBorder(),
          minimumSize: const Size(double.infinity, 52),
          textStyle: GoogleFonts.getFont(
            'Geist',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceContainerLowest,
        selectedItemColor: primary,
        unselectedItemColor: outline,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerLow,
        selectedColor: primary,
        labelStyle: GoogleFonts.inter(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: const StadiumBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: surfaceContainerHigh,
        thickness: 1,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2E3132),
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      // Headlines use Geist
      displayLarge: GoogleFonts.getFont(
        'Geist',
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 48,
        color: onSurface,
      ),
      displayMedium: GoogleFonts.getFont(
        'Geist',
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      displaySmall: GoogleFonts.getFont(
        'Geist',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      headlineLarge: GoogleFonts.getFont(
        'Geist',
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      headlineMedium: GoogleFonts.getFont(
        'Geist',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      headlineSmall: GoogleFonts.getFont(
        'Geist',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleLarge: GoogleFonts.getFont(
        'Geist',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      titleMedium: GoogleFonts.getFont(
        'Geist',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      titleSmall: GoogleFonts.getFont(
        'Geist',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      // Body uses Inter
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: onSurfaceVariant,
      ),
      // Labels use Inter
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: onSurfaceVariant,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: onSurfaceVariant,
      ),
    );
  }

  // JetBrains Mono text style for financial data
  static TextStyle monoStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? onSurface,
    );
  }

  static TextStyle get balanceLarge => monoStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: onPrimary,
      );

  static TextStyle get amountIncome => monoStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: incomeColor,
      );

  static TextStyle get amountExpense => monoStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: expenseColor,
      );
}

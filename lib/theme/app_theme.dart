import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// Design system for "Company Book".
///
/// Corporate finance ledger aesthetic:
/// Deep midnight navy surfaces for executive hero cards,
/// crisp cool-slate background for prolonged accounting use,
/// bold emerald green for revenue & income,
/// distinct crimson rose for expenditures, and
/// royal indigo for primary actions and corporate branding.
/// ---------------------------------------------------------------------------
class AppTheme {
  AppTheme._();

  // Core Corporate Palette
  static const Color ink = Color(0xFF0F172A); // Slate 900
  static const Color inkElevated = Color(0xFF1E293B); // Slate 800
  static const Color inkLine = Color(0xFF334155); // Slate 700

  // Brand Accent: Royal Indigo
  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryDark = Color(0xFF3730A3); // Indigo 800
  static const Color primaryLight = Color(0xFF818CF8); // Indigo 400
  static const Color primarySoft = Color(0xFFEEF2FF); // Indigo 50

  // Secondary Accent: Amber Gold
  static const Color gold = Color(0xFFD97706); // Amber 600
  static const Color goldSoft = Color(0xFFFEF3C7); // Amber 100

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color card = Color(0xFFFFFFFF);
  static const Color surfaceRecessed = Color(0xFFF1F5F9); // Slate 100
  static const Color divider = Color(0xFFE2E8F0); // Slate 200

  // Ledger Status Colors
  static const Color revenue = Color(0xFF059669); // Emerald 600
  static const Color revenueSoft = Color(0xFFD1FAE5); // Emerald 100
  static const Color expense = Color(0xFFDC2626); // Red 600
  static const Color expenseSoft = Color(0xFFFEE2E2); // Red 100

  // Backwards compatibility aliases
  static const Color incomeColor = revenue;
  static const Color expenseColor = expense;
  static const Color cream = background;
  static const Color cardBg = card;
  static const Color coral = primary;

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // Typography
  static const String _displayFont = 'Roboto';

  static const TextStyle moneyHero = TextStyle(
    fontFamily: _displayFont,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    height: 1.1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle moneyLarge = TextStyle(
    fontFamily: _displayFont,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle moneyMedium = TextStyle(
    fontFamily: _displayFont,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle moneySmall = TextStyle(
    fontFamily: _displayFont,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle heading1 = TextStyle(
    fontFamily: _displayFont,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: _displayFont,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: _displayFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static const TextStyle badgeText = TextStyle(
    fontFamily: _displayFont,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: revenue,
        surface: card,
        error: expense,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: _displayFont,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: expense, width: 1.2),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: primarySoft,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: textSecondary, size: 24);
        }),
      ),
    );
  }
}

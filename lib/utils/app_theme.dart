import 'package:flutter/material.dart';

class AppTheme {
  static const Color bgDeep = Color(0xFF0D1A0D);
  static const Color bgMid = Color(0xFF102210);
  static const Color bgCard = Color(0xFF122512);
  static const Color bgCard2 = Color(0xFF1A2C1A);
  static const Color gold = Color(0xFFC9A84C);
  static const Color goldLight = Color(0xFFFFD257);
  static const Color goldDim = Color(0xFFB99E49);
  static const Color green = Color(0xFF2E6B3E);
  static const Color greenLight = Color(0xFF8BC34A);
  static const Color textMain = Color(0xFFF8F8F2);
  static const Color textMuted = Color(0xFFB1B1B1);
  static const Color textDim = Color(0xFF9AA29A);
  static const Color borderColor = Color(0xFF274127);
  static const Color borderBright = Color(0xFF3A6C3E);

  static final ThemeData theme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: gold,
    scaffoldBackgroundColor: bgDeep,
    cardColor: bgCard,
    canvasColor: bgDeep,
    colorScheme: ColorScheme.dark(
      primary: gold,
      secondary: green,
      background: bgDeep,
      surface: bgCard,
      onBackground: textMain,
      onSurface: textMain,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgMid,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: textMain,
        fontFamily: 'Amiri',
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: textMain,
        fontFamily: 'Amiri',
        fontSize: 34,
      ),
      bodySmall: TextStyle(color: textMuted, fontSize: 14),
    ),
    iconTheme: const IconThemeData(color: textMain),
  );
}

class AppDecorations {
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: AppTheme.bgCard,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppTheme.borderColor),
    boxShadow: [
      BoxShadow(
        color: AppTheme.green.withOpacity(0.15),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static final BoxDecoration prayerCardDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [AppTheme.bgMid, AppTheme.bgCard2],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppTheme.borderColor),
    boxShadow: [
      BoxShadow(
        color: AppTheme.gold.withOpacity(0.2),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static final BoxDecoration glowCardDecoration = BoxDecoration(
    color: AppTheme.bgCard2,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppTheme.borderColor),
    boxShadow: [
      BoxShadow(
        color: AppTheme.gold.withOpacity(0.4),
        blurRadius: 18,
        offset: const Offset(0, 0),
      ),
    ],
  );
}

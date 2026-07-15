import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFF1E1B4B); // Dark indigo surface
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE5E7EB);

  static const Color primary = Color(0xFF4F46E5); // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondary = Color(0xFF6366F1); // Medium Indigo
  static const Color accent = Color(0xFF10B981); // Emerald Green

  static const Color textPrimary = Colors.black;
  static const Color textSecondaryinBlack = Color.fromARGB(190, 100, 116, 139);
  static const Color textSecondaryinWhite = Color.fromARGB(213, 71, 85, 105);
  static const Color divider = Color(0xFFE2E8F0);

  static const Map<String, Color> badgeColors = {
    'حصري': Color(0xFF4F46E5), // Indigo
    'مميز': Color(0xFF10B981), // Emerald
    'جديد': Color(0xFFF43F5E), // Rose/Pink
    'عرض خاص': Color(0xFFEF4444),
  };

  static const Map<String, Color> badgeTextColors = {
    'حصري': Color(0xFFFFFFFF),
    'مميز': Color(0xFFFFFFFF),
    'جديد': Color(0xFFFFFFFF),
    'عرض خاص': Color(0xFFFFFFFF),
  };

  static TextTheme get _tajawalTextTheme =>
      GoogleFonts.tajawalTextTheme().copyWith(
        bodyLarge: GoogleFonts.tajawal(),
        bodyMedium: GoogleFonts.tajawal(),
        bodySmall: GoogleFonts.tajawal(),
        displayLarge: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        titleMedium: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
        labelLarge: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
      );

  static ThemeData get theme => ThemeData(
        brightness: Brightness.light,
        fontFamily: GoogleFonts.tajawal().fontFamily,
        textTheme: _tajawalTextTheme,
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: secondary,
          surface: background,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: AppBarTheme(
          backgroundColor: background,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.tajawal(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: GoogleFonts.tajawal(color: Colors.grey),
        ),
        useMaterial3: true,
      );

  // Helper للحصول على TextStyle بفونت تجوال
  static TextStyle tajawal({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = textPrimary,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) =>
      GoogleFonts.tajawal(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        decoration: decoration,
      );

  // Animation helpers
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Curve defaultCurve = Curves.easeInOut;

  static Widget animatedSlideIn({
    required Widget child,
    required Animation<double> animation,
    double offset = 30,
    AxisDirection direction = AxisDirection.up,
  }) {
    final double dx = direction == AxisDirection.left
        ? -offset
        : direction == AxisDirection.right
            ? offset
            : 0;
    final double dy = direction == AxisDirection.up
        ? -offset
        : direction == AxisDirection.down
            ? offset
            : 0;

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(dx / 100, dy / 100),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }

  static Widget animatedFadeIn({
    required Widget child,
    required Animation<double> animation,
  }) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  static Widget animatedScaleIn({
    required Widget child,
    required Animation<double> animation,
    double minScale = 0.9,
  }) {
    return ScaleTransition(
      scale: Tween<double>(begin: minScale, end: 1.0).animate(animation),
      child: child,
    );
  }

  static Widget animatedSlideFadeIn({
    required Widget child,
    required Animation<double> animation,
    double offset = 20,
    AxisDirection direction = AxisDirection.up,
  }) {
    final double dx = direction == AxisDirection.left
        ? -offset
        : direction == AxisDirection.right
            ? offset
            : 0;
    final double dy = direction == AxisDirection.up
        ? -offset
        : direction == AxisDirection.down
            ? offset
            : 0;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double t = animation.value;
        return Transform.translate(
          offset: Offset(dx * (1 - t), dy * (1 - t)),
          child: Opacity(
            opacity: t,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

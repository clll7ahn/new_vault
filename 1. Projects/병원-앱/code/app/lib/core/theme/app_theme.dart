import 'package:flutter/material.dart';

/// 앱 테마 정의
///
/// 팔레트:
/// - Primary  : Navy   #1A3A5C  (신뢰감, 전문성)
/// - Secondary: Slate  #64748B  (보조 텍스트, 아이콘)
/// - Surface  : #F8FAFC
/// - Error    : #DC2626
///
/// 어르신 모드 고려:
/// - 기본 폰트 16sp (최소 14sp)
/// - 터치 타겟 최소 48dp
/// - 명도 대비 WCAG AA 이상
class AppTheme {
  AppTheme._();

  // ──────────────────────────────────────────
  // 색상 팔레트
  // ──────────────────────────────────────────
  static const Color navy = Color(0xFF1A3A5C);
  static const Color navyLight = Color(0xFF2A5080);
  static const Color navyDark = Color(0xFF0F2440);

  static const Color slate = Color(0xFF64748B);
  static const Color slateLight = Color(0xFF94A3B8);
  static const Color slateDark = Color(0xFF475569);

  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceVariant = Color(0xFFE2E8F0);
  static const Color background = Color(0xFFFFFFFF);

  static const Color errorColor = Color(0xFFDC2626);
  static const Color successColor = Color(0xFF16A34A);
  static const Color warningColor = Color(0xFFD97706);

  // ──────────────────────────────────────────
  // ColorScheme
  // ──────────────────────────────────────────
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: navy,
    onPrimary: Colors.white,
    primaryContainer: navyLight,
    onPrimaryContainer: Colors.white,
    secondary: slate,
    onSecondary: Colors.white,
    secondaryContainer: slateLight,
    onSecondaryContainer: Colors.white,
    tertiary: successColor,
    onTertiary: Colors.white,
    error: errorColor,
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: surface,
    onSurface: Color(0xFF0F172A),
    surfaceContainerHighest: surfaceVariant,
    onSurfaceVariant: slateDark,
    outline: slateLight,
    outlineVariant: Color(0xFFCBD5E1),
    shadow: Color(0x1A000000),
    scrim: Color(0x80000000),
    inverseSurface: Color(0xFF1E293B),
    onInverseSurface: Colors.white,
    inversePrimary: navyLight,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: navyLight,
    onPrimary: Colors.white,
    primaryContainer: navy,
    onPrimaryContainer: Colors.white,
    secondary: slateLight,
    onSecondary: Color(0xFF1E293B),
    secondaryContainer: slate,
    onSecondaryContainer: Colors.white,
    tertiary: successColor,
    onTertiary: Colors.white,
    error: Color(0xFFF87171),
    onError: Color(0xFF7F1D1D),
    errorContainer: Color(0xFF991B1B),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: Color(0xFF0F172A),
    onSurface: Color(0xFFF1F5F9),
    surfaceContainerHighest: Color(0xFF1E293B),
    onSurfaceVariant: slateLight,
    outline: slate,
    outlineVariant: slateDark,
    shadow: Color(0x40000000),
    scrim: Color(0x80000000),
    inverseSurface: surface,
    onInverseSurface: Color(0xFF0F172A),
    inversePrimary: navy,
  );

  // ──────────────────────────────────────────
  // 텍스트 테마 (어르신 모드 기준 16sp 베이스)
  // ──────────────────────────────────────────
  static TextTheme _buildTextTheme(ColorScheme scheme) {
    return TextTheme(
      // Display
      displayLarge: TextStyle(
        fontSize: 57, fontWeight: FontWeight.w400,
        color: scheme.onSurface, letterSpacing: -0.25,
      ),
      displayMedium: TextStyle(
        fontSize: 45, fontWeight: FontWeight.w400,
        color: scheme.onSurface,
      ),
      displaySmall: TextStyle(
        fontSize: 36, fontWeight: FontWeight.w400,
        color: scheme.onSurface,
      ),
      // Headline
      headlineLarge: TextStyle(
        fontSize: 32, fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28, fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 24, fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      // Title
      titleLarge: TextStyle(
        fontSize: 22, fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w500,
        color: scheme.onSurface, letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w500,
        color: scheme.onSurface, letterSpacing: 0.1,
      ),
      // Body (기본 16sp)
      bodyLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w400,
        color: scheme.onSurface, letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w400,
        color: scheme.onSurface, letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant, letterSpacing: 0.4,
      ),
      // Label
      labelLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w600,
        color: scheme.onSurface, letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w500,
        color: scheme.onSurface, letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w500,
        color: scheme.onSurfaceVariant, letterSpacing: 0.5,
      ),
    );
  }

  // ──────────────────────────────────────────
  // Light Theme
  // ──────────────────────────────────────────
  static ThemeData get lightTheme => _buildTheme(_lightColorScheme);

  // ──────────────────────────────────────────
  // Dark Theme
  // ──────────────────────────────────────────
  static ThemeData get darkTheme => _buildTheme(_darkColorScheme);

  static ThemeData _buildTheme(ColorScheme scheme) {
    final textTheme = _buildTextTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: scheme.onPrimary, size: 28),
      ),

      // ElevatedButton (주 버튼 — 최소 48dp 높이)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(double.infinity, 56), // 어르신 터치 타겟
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),

      // OutlinedButton (보조 버튼)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: scheme.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, 48),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // InputDecoration (폼 필드)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18, // 어르신 — 넉넉한 패딩
        ),
        labelStyle: textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        hintStyle: textTheme.bodyLarge?.copyWith(color: scheme.outline),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),

      // Card
      cardTheme: CardTheme(
        color: scheme.surface,
        elevation: 2,
        shadowColor: scheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        extendedTextStyle: textTheme.labelLarge,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

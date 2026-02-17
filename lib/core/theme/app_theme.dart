import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// VoiceFlow Premium Design System
/// 风格: Void & Pulse - 极简黑白红
class AppTheme {
  // 1. 核心色板
  static const Color background = Color(0xFF000000); // 纯黑背景
  static const Color surface = Color(0xFF1A1A1A); // 深灰表面
  static const Color surfaceHighlight = Color(0xFF2A2A2A); // 高亮表面

  static const Color primary = Color(0xFFFF0000); // 正红强调
  static const Color primaryDark = Color(0xFF8B0000); // 深红
  static const Color primaryLight = Color(0xFFFF3333); // 亮红

  static const Color textPrimary = Color(0xFFFFFFFF); // 纯白文字
  static const Color textSecondary = Color(0xFFA0A0A0); // 中灰文字
  static const Color textDisabled = Color(0xFF404040); // 暗灰文字

  static const Color border = Color(0xFF333333); // 边框色
  static const Color success = Color(0xFF10B981); // Success Green
  static const Color error =
      Color(0xFFCF6679); // 错误色 (Material Standard for Dark)

  // 2. 阴影 (Subtle Glows instead of traditional shadows)
  static List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: primary.withOpacity(0.15),
          offset: const Offset(0, 0),
          blurRadius: 20,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ];

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // 颜色方案
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primary, // Use red as secondary too for consistency
        surface: surface,
        background: background,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: Colors.black,
      ),

      // 背景色
      scaffoldBackgroundColor: background,
      canvasColor: surface,

      // 字体系统 - Inter
      textTheme: TextTheme(
        // 大标题 Display XL
        displayLarge: GoogleFonts.inter(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -1.5,
          height: 1.1,
        ),
        // 模块标题 Display L
        displayMedium: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -1.0,
          height: 1.2,
        ),
        // 卡片标题 Title M
        headlineSmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: -0.5,
          height: 1.3,
        ),
        // 正文 Body L
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.6,
        ),
        // 列表项 Body M
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color:
              textSecondary, // Default to secondary for body text to reduce contrast strain
          height: 1.5,
        ),
        // 标签 Label S
        labelSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          letterSpacing: 0.5,
        ),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: background, // Merge with background
        foregroundColor: textPrimary,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      // Card - 极简边框风格
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // Minimal rounding
          side: const BorderSide(color: border, width: 1),
        ),
        color: surface,
        margin: EdgeInsets.zero,
      ),

      // Button - 几何矩形
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2), // Almost sharp
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withOpacity(0.1);
            }
            if (states.contains(WidgetState.pressed)) {
              return Colors.black.withOpacity(0.2);
            }
            return null;
          }),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textSecondary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ).copyWith(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return textPrimary; // Highlight on hover
            }
            return textSecondary;
          }),
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111111),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: primary, width: 1),
        ),
        hintStyle: GoogleFonts.inter(color: textDisabled),
        labelStyle: GoogleFonts.inter(color: textSecondary),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: border, width: 1),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return surfaceHighlight;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),
    );
  }

  // 优先级颜色映射
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return primary;
      case 'medium':
        return const Color(0xFFFF8C00); // Dark Orange for medium in dark mode
      case 'low':
        return const Color(
            0xFF00FF00); // Green for low (maybe adjust to fit theme?)
      // Let's stick to the red theme:
      // High = Red, Medium = White, Low = Grey? Or shades of red?
      // Let's keep distinct colors for utility but desaturate them a bit or make them fit dark mode.
      default:
        return textSecondary;
    }
  }

  // 动画时长
  static const Duration fastAnimation = Duration(milliseconds: 100);
  static const Duration normalAnimation = Duration(milliseconds: 200);
  static const Duration slowAnimation = Duration(milliseconds: 300);
}

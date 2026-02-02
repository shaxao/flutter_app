import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// VoiceFlow 设计系统
/// 风格: Micro-interactions - 简洁现代的语音助手
class AppTheme {
  // 配色方案 - 基于 ui-ux-pro-max 生成
  static const Color primary = Color(0xFF3B82F6); // Fresh Blue
  static const Color secondary = Color(0xFF60A5FA); // Light Blue
  static const Color success = Color(0xFF10B981); // Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red
  static const Color background = Color(0xFFF8FAFC); // Clean White
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color textPrimary = Color(0xFF1E293B); // Dark Slate
  static const Color textSecondary = Color(0xFF475569); // Medium Slate
  static const Color textTertiary = Color(0xFF94A3B8); // Light Slate
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // 配色
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: background,
        error: error,
      ),
      
      // 脚手架背景
      scaffoldBackgroundColor: background,
      
      // 字体系统 - Inter (简洁现代)
      textTheme: TextTheme(
        // 大标题 - VoiceFlow
        displayLarge: GoogleFonts.inter(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.02,
          height: 1.1,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.01,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        
        // 标题
        headlineLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        
        // 正文
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.4,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.3,
        ),
        
        // 标签
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textTertiary,
        ),
      ),
      
      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      
      // Card - 微交互设计
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: surface,
        shadowColor: Colors.black.withValues(alpha: 0.04),
      ),
      
      // Button - 现代化按钮设计
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),
      
      // Switch - 现代化开关
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return const Color(0xFFE2E8F0);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return const Color(0xFFE2E8F0);
        }),
      ),
    );
  }
  
  // 优先级颜色
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return error;
      case 'medium':
        return warning;
      case 'low':
        return success;
      default:
        return textTertiary;
    }
  }
  
  // 微交互动画时长
  static const Duration microAnimation = Duration(milliseconds: 100);
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
}

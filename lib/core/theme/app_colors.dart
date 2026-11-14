import 'package:flutter/material.dart';

/// App Color Palette for MyMechanic
/// Modern Indian Automotive Service aesthetic:
/// Deep Charcoal/Navy base with energetic Sunset Amber/Orange accents,
/// clean slate surfaces, and high-trust status colors.
class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFFE64A19); // Rich Automotive Rust/Orange
  static const Color primaryDark = Color(0xFFBF360C);
  static const Color primaryLight = Color(0xFFFFCCBC);
  static const Color accent = Color(0xFFFF7043);

  // Secondary & Accents
  static const Color secondary = Color(0xFF1E293B); // Deep Slate Navy
  static const Color secondaryLight = Color(0xFF334155);

  // Neutrals / Surfaces
  static const Color background = Color(0xFFF8FAFC); // Very light crisp cool grey
  static const Color surface = Color(0xFFFFFFFF); // Card white
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEDF2F7);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Dark slate
  static const Color textSecondary = Color(0xFF64748B); // Muted slate
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Dark Theme Palette (Professional Layered Dark Hierarchy)
  static const Color darkBackground = Color(0xFF0B0D10); // Very dark charcoal page background
  static const Color darkSurface = Color(0xFF14171C); // Primary surface / cards
  static const Color darkElevatedSurface = Color(0xFF1B1F26); // Elevated sheets, dialogs, popups
  static const Color darkInputSurface = Color(0xFF20242B); // Input / search / secondary surface
  static const Color darkBorder = Color(0xFF2A2F37); // Subtle borders
  static const Color darkDivider = Color(0xFF2A2F37); // Subtle dividers
  static const Color darkTextPrimary = Color(0xFFF5F5F5); // Near-white primary text
  static const Color darkTextSecondary = Color(0xFFB7BCC5); // Soft gray secondary text
  static const Color darkTextMuted = Color(0xFF707782); // Dark gray muted / disabled text
  static const Color darkSearchPlaceholder = Color(0xFF9AA0AA); // Search placeholder
  static const Color darkBottomNavBg = Color(0xFF111419); // Bottom navigation background
  static const Color darkBottomNavInactive = Color(0xFF8D949F); // Inactive navigation items

  // Status & Utility Colors
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444); // Red
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF3B82F6); // Blue
  static const Color infoBg = Color(0xFFEFF6FF);

  // Category Icon Tint Colors (Subtle & Elegant)
  static const Color categoryRedBg = Color(0xFFFFECEB);
  static const Color categoryRed = Color(0xFFDC2626);

  static const Color categoryBlueBg = Color(0xFFEBF5FF);
  static const Color categoryBlue = Color(0xFF2563EB);

  static const Color categoryGreenBg = Color(0xFFECFDF5);
  static const Color categoryGreen = Color(0xFF059669);

  static const Color categoryPurpleBg = Color(0xFFF5F3FF);
  static const Color categoryPurple = Color(0xFF7C3AED);

  static const Color categoryAmberBg = Color(0xFFFFFBEB);
  static const Color categoryAmber = Color(0xFFD97706);

  static const Color categoryTealBg = Color(0xFFF0FDFA);
  static const Color categoryTeal = Color(0xFF0D9488);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE64A19), Color(0xFFFF7043)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient offerBannerGradient = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sosGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

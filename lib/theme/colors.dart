import 'package:flutter/material.dart';

/// Vertex Color System
/// Exact values from vertexishere.com CSS variables
class VertexColors {
  VertexColors._();

  // ═══════════════════════════════════
  //  DARK THEME COLORS
  // ═══════════════════════════════════
  static const Color bgDark = Color(0xFF171717); // #171717
  static const Color bgSecondaryDark = Color(0xFF2A2A2A);
  static const Color bgCardDark = Color(0xFF2E2E2E);
  static const Color textMainDark = Color(0xFFFFFFFF);
  static const Color textMutedDark = Color(0xFFD4D4D8);
  static const Color primaryDark = Color(0xFF2F6BF5); // Signal Blue
  static const Color primaryHoverDark = Color(0xFF4A7DF6);
  static const Color accentDark = Color(0xFF00E5FF); // Beam Cyan
  static const Color btnTextDark = Color(0xFFFFFFFF);
  static const Color borderDark = Color(0xFF3F3F46);
  static const Color glassBgDark = Color(0xCC222222); // rgba(34,34,34,0.8)
  static const Color glassBorderDark = Color(0x1AFFFFFF); // rgba(255,255,255,0.1)

  // ═══════════════════════════════════
  //  LIGHT THEME COLORS
  // ═══════════════════════════════════
  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color bgSecondaryLight = Color(0xFFF4F4F5);
  static const Color bgCardLight = Color(0xFFFFFFFF);
  static const Color textMainLight = Color(0xFF18181B);
  static const Color textMutedLight = Color(0xFF3F3F46);
  static const Color primaryLight = Color(0xFF2F6BF5); // Signal Blue
  static const Color primaryHoverLight = Color(0xFF1A56E0);
  static const Color accentLight = Color(0xFF00E5FF); // Beam Cyan
  static const Color btnTextLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE4E4E7);
  static const Color glassBgLight = Color(0xCCFFFFFF); // rgba(255,255,255,0.8)
  static const Color glassBorderLight = Color(0x1A000000); // rgba(0,0,0,0.1)

  // ═══════════════════════════════════
  //  SEMANTIC COLORS
  // ═══════════════════════════════════
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ═══════════════════════════════════
  //  STATUS COLORS (for task states)
  // ═══════════════════════════════════
  static const Color statusTodo = Color(0xFF71717A);
  static const Color statusInProgress = Color(0xFF3B82F6);
  static const Color statusDone = Color(0xFF22C55E);

  // ═══════════════════════════════════
  //  GRADIENTS
  // ═══════════════════════════════════

  /// Dark mode main gradient: Signal Blue to Beam Cyan
  static const LinearGradient gradientMainDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2F6BF5), Color(0xFF00E5FF)],
  );

  /// Light mode main gradient: Signal Blue to Beam Cyan
  static const LinearGradient gradientMainLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2F6BF5), Color(0xFF00E5FF)],
  );

  /// Dark mode text gradient
  static const LinearGradient gradientTextDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0)],
  );

  /// Subtle glow gradient for backgrounds
  static const RadialGradient glowGradient = RadialGradient(
    center: Alignment.center,
    radius: 0.8,
    colors: [
      Color(0x332F6BF5),
      Color(0x002F6BF5),
    ],
  );

  /// CTA background gradient
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2F6BF5),
      Color(0xFF1A56E0),
      Color(0xFF2F6BF5),
    ],
  );

  // ═══════════════════════════════════
  //  HELPER METHODS
  // ═══════════════════════════════════

  /// Get gradient based on current brightness
  static LinearGradient gradientMain(Brightness brightness) {
    return brightness == Brightness.dark ? gradientMainDark : gradientMainLight;
  }

  /// Get glass background color
  static Color glassBg(Brightness brightness) {
    return brightness == Brightness.dark ? glassBgDark : glassBgLight;
  }

  /// Get glass border color
  static Color glassBorder(Brightness brightness) {
    return brightness == Brightness.dark ? glassBorderDark : glassBorderLight;
  }

  /// Get card background color
  static Color bgCard(Brightness brightness) {
    return brightness == Brightness.dark ? bgCardDark : bgCardLight;
  }

  /// Get secondary background color
  static Color bgSecondary(Brightness brightness) {
    return brightness == Brightness.dark ? bgSecondaryDark : bgSecondaryLight;
  }

  /// Get scaffold background color
  static Color bg(Brightness brightness) {
    return brightness == Brightness.dark ? bgDark : bgLight;
  }

  /// Get text muted color
  static Color textMuted(Brightness brightness) {
    return brightness == Brightness.dark ? textMutedDark : textMutedLight;
  }

  /// Get border color
  static Color border(Brightness brightness) {
    return brightness == Brightness.dark ? borderDark : borderLight;
  }

  /// Get primary color
  static Color primary(Brightness brightness) {
    return brightness == Brightness.dark ? primaryDark : primaryLight;
  }
}

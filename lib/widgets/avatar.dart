import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';

/// Circular initials avatar that follows the active Edge theme.
class ThemeAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final bool isOnline;
  final bool isVerified;
  final IconData? icon;

  const ThemeAvatar({
    super.key,
    required this.name,
    this.radius = 20,
    this.isOnline = false,
    this.isVerified = false,
    this.icon,
  });

  static Color onAccent() {
    return AppColors.senaryColor.computeLuminance() > 0.55
        ? const Color(0xFF111827)
        : Colors.white;
  }

  String get _initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final accent = AppColors.senaryColor;
    final fg = onAccent();
    final size = radius * 2;

    return SizedBox(
      width: size + (isVerified ? 4 : 0),
      height: size + (isVerified ? 4 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent,
                  Color.lerp(accent, AppColors.background, 0.28) ?? accent,
                ],
              ),
              border: Border.all(
                color: accent.withValues(alpha: AppColors.isDarkUi ? 0.7 : 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: AppColors.isDarkUi ? 0.35 : 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: icon != null
                  ? Icon(icon, color: fg, size: radius)
                  : Text(
                      _initial,
                      style: GoogleFonts.inter(
                        color: fg,
                        fontWeight: FontWeight.w800,
                        fontSize: radius * 0.85,
                        height: 1,
                      ),
                    ),
            ),
          ),
          if (isOnline)
            Positioned(
              right: isVerified ? 2 : 0,
              bottom: isVerified ? 2 : 0,
              child: Container(
                width: radius * 0.55,
                height: radius * 0.55,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
              ),
            ),
          if (isVerified)
            Positioned(
              right: -2,
              bottom: -2,
              child: Icon(
                Icons.verified,
                size: radius * 0.8,
                color: fg == Colors.white ? Colors.white : accent,
              ),
            ),
        ],
      ),
    );
  }
}

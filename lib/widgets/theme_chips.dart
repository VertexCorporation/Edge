import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';

class ThemeChips extends StatelessWidget {
  const ThemeChips({super.key});

  @override
  Widget build(BuildContext context) {
    final currentTheme = context.watch<ThemeProvider>().currentTheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppColors.themeDefinitions.keys.map((themeKey) {
        final themeColors = AppColors.getThemeColors(themeKey);
        final selected = themeKey == currentTheme;
        final labelColor = themeColors.background.computeLuminance() < 0.5
            ? Colors.white
            : Colors.black87;

        return GestureDetector(
          onTap: () => context.read<ThemeProvider>().changeTheme(themeKey),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: themeColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.senaryColor : themeColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(
              AppColors.themeDisplayName(themeKey),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: labelColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

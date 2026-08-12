import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

/// Glassmorphic input field matching Vertex website's input style
class VertexInput extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool autofocus;

  const VertexInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.prefixIcon,
    this.errorText,
    this.onChanged,
    this.validator,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.tertiaryColor,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              onChanged: onChanged,
              validator: validator,
              autofocus: autofocus,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark
                    ? AppColors.primaryColor.inverted
                    : AppColors.primaryColor.inverted,
              ),
              cursorColor: isDark
                  ? AppColors.senaryColor
                  : AppColors.senaryColor,
              decoration: InputDecoration(
                hintText: hint,
                errorText: errorText,
                suffixIcon: suffixIcon,
                prefixIcon: prefixIcon,
                filled: true,
                fillColor: isDark
                    ? AppColors.background.withValues(alpha: 0.6)
                    : AppColors.secondaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

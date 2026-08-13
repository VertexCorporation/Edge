import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';

/// Primary button matching Vertex website's btn-primary style
class VertexButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutline;
  final IconData? icon;
  final double? width;

  const VertexButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutline = false,
    this.icon,
    this.width,
  });

  const VertexButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : isOutline = true;

  @override
  State<VertexButton> createState() => _VertexButtonState();
}

class _VertexButtonState extends State<VertexButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final isDarkUi = AppColors.getThemeColors(AppColors.currentTheme)
            .statusBarIconBrightness ==
        Brightness.light;

    final bgColor = widget.isOutline
        ? Colors.transparent
        : AppColors.senaryColor;
    final textColor = widget.isOutline
        ? (isDarkUi ? Colors.white : AppColors.primaryColor.inverted)
        : (isDarkUi ? Colors.white : AppColors.primaryColor.inverted);
    final borderColor = widget.isOutline
        ? (isDarkUi ? AppColors.border : AppColors.border)
        : bgColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.width,
        decoration: BoxDecoration(
          color: _isHovered
              ? (widget.isOutline
                  ? (isDarkUi
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05))
                  : AppColors.senaryColor)
              : bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered && widget.isOutline
                ? (isDarkUi
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.2))
                : borderColor,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: textColor,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 18, color: textColor),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

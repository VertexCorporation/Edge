import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Glassmorphic card widget matching Vertex website's card style.
/// Features: frosted glass effect, subtle border, animated hover state.
class VertexCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool animatedBorder;
  final BorderRadius? borderRadius;

  const VertexCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.animatedBorder = false,
    this.borderRadius,
  });

  @override
  State<VertexCard> createState() => _VertexCardState();
}

class _VertexCardState extends State<VertexCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _borderController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.animatedBorder) {
      _borderController.repeat();
    }
  }

  @override
  void dispose() {
    _borderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(12);

    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: widget.margin,
      transform: _isHovered
          ? (Matrix4.identity()..setTranslationRaw(0.0, -2.0, 0.0))
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: VertexColors.glassBg(brightness),
        borderRadius: borderRadius,
        border: Border.all(
          color: _isHovered
              ? VertexColors.glassBorder(brightness).withValues(alpha: 0.3)
              : VertexColors.glassBorder(brightness),
          width: 1,
        ),
        boxShadow: _isHovered
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: widget.padding ??
                const EdgeInsets.all(24),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.animatedBorder) {
      card = AnimatedBuilder(
        animation: _borderController,
        builder: (context, child) {
          return CustomPaint(
            painter: _AnimatedBorderPainter(
              progress: _borderController.value,
              borderRadius: borderRadius,
              brightness: brightness,
            ),
            child: child,
          );
        },
        child: card,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: widget.onTap != null
          ? GestureDetector(onTap: widget.onTap, child: card)
          : card,
    );
  }
}

/// Custom painter for animated border glow effect
class _AnimatedBorderPainter extends CustomPainter {
  final double progress;
  final BorderRadius borderRadius;
  final Brightness brightness;

  _AnimatedBorderPainter({
    required this.progress,
    required this.borderRadius,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    final sweepGradient = SweepGradient(
      startAngle: progress * 6.28,
      colors: brightness == Brightness.dark
          ? [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.15),
              Colors.transparent,
            ]
          : [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.1),
              Colors.transparent,
            ],
      stops: const [0.0, 0.5, 1.0],
    );

    final paint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

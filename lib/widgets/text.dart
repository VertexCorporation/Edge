import 'package:flutter/material.dart';

/// Gradient text widget matching Vertex website's .gradient-text class
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Gradient? gradient;

  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient =
        gradient ?? const LinearGradient(colors: [Color(0xFF2F6BF5), Color(0xFF00E5FF)]);

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => effectiveGradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: style ?? Theme.of(context).textTheme.displayMedium,
        textAlign: textAlign,
      ),
    );
  }
}

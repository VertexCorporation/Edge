import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';

/// Animated geometric background blobs matching Vertex website's geo-bg class.
/// Creates floating, pulsing blobs with subtle glow effects.
class GeoBackground extends StatefulWidget {
  final Widget child;

  const GeoBackground({super.key, required this.child});

  @override
  State<GeoBackground> createState() => _GeoBackgroundState();
}

class _GeoBackgroundState extends State<GeoBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat(reverse: true);

    _controller3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Stack(
      children: [
        // Blob 1 - top right
        AnimatedBuilder(
          animation: _controller1,
          builder: (context, child) {
            return Positioned(
              top: -100 + (50 * sin(_controller1.value * pi * 2)),
              right: -80 + (30 * cos(_controller1.value * pi * 2)),
              child: _GeoBlob(
                size: 300,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.02),
              ),
            );
          },
        ),
        // Blob 2 - bottom left
        AnimatedBuilder(
          animation: _controller2,
          builder: (context, child) {
            return Positioned(
              bottom: -120 + (40 * sin(_controller2.value * pi * 2)),
              left: -100 + (60 * cos(_controller2.value * pi * 2)),
              child: _GeoBlob(
                size: 350,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.black.withValues(alpha: 0.015),
              ),
            );
          },
        ),
        // Blob 3 - center
        AnimatedBuilder(
          animation: _controller3,
          builder: (context, child) {
            return Positioned(
              top: 200 + (70 * sin(_controller3.value * pi * 2)),
              left: 100 + (50 * cos(_controller3.value * pi * 2)),
              child: _GeoBlob(
                size: 250,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.015)
                    : Colors.black.withValues(alpha: 0.01),
              ),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _GeoBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GeoBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

/// Pixel-art sky for Uzay (stars + planets) and Aşk (hearts).
class ThemeAtmosphere extends StatelessWidget {
  const ThemeAtmosphere({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final theme = AppColors.currentTheme;
    if (theme != 'deepSpace' && theme != 'love') {
      return const SizedBox.shrink();
    }
    return const Positioned.fill(
      child: IgnorePointer(
        child: _ThemeSky(),
      ),
    );
  }
}

class _ThemeSky extends StatefulWidget {
  const _ThemeSky();

  @override
  State<_ThemeSky> createState() => _ThemeSkyState();
}

class _ThemeSkyState extends State<_ThemeSky>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppColors.currentTheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: theme == 'love'
              ? _PixelHeartsPainter(_controller.value)
              : _PixelSpacePainter(_controller.value),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _PixelSpacePainter extends CustomPainter {
  final double t;
  _PixelSpacePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final twinkle = (sin(t * pi * 2) + 1) / 2;

    for (var i = 0; i < 90; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final pixel = 1.0 + random.nextInt(3);
      final base = 0.25 + random.nextDouble() * 0.55;
      final pulse = (i % 5 == 0) ? (0.35 + 0.65 * twinkle) : 1.0;
      final paint = Paint()
        ..color = Color.fromRGBO(
          220 + random.nextInt(35),
          225 + random.nextInt(30),
          255,
          (base * pulse).clamp(0.12, 0.9),
        );
      canvas.drawRect(Rect.fromLTWH(x, y, pixel, pixel), paint);
    }

    _planet(
      canvas,
      Offset(size.width * 0.82, size.height * 0.18),
      38,
      const Color(0xFF6366F1),
      const Color(0xFF312E81),
      Random(7),
    );
    _planet(
      canvas,
      Offset(size.width * 0.14, size.height * 0.72),
      22,
      const Color(0xFFA78BFA),
      const Color(0xFF4C1D95),
      Random(11),
    );
  }

  void _planet(
    Canvas canvas,
    Offset center,
    double radius,
    Color fill,
    Color shadow,
    Random random,
  ) {
    canvas.drawCircle(center, radius, Paint()..color = fill);
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center.translate(radius * 0.28, -radius * 0.12),
      radius,
      Paint()..color = fill.withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      center.translate(-radius * 0.45, radius * 0.2),
      radius * 0.9,
      Paint()..color = shadow.withValues(alpha: 0.55),
    );
    for (var i = 0; i < 6; i++) {
      final dx = (random.nextDouble() - 0.5) * radius * 1.4;
      final dy = (random.nextDouble() - 0.5) * radius * 1.4;
      final crater = 2.0 + random.nextInt(4);
      canvas.drawRect(
        Rect.fromCenter(
          center: center.translate(dx, dy),
          width: crater,
          height: crater,
        ),
        Paint()..color = shadow.withValues(alpha: 0.45),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PixelSpacePainter oldDelegate) =>
      oldDelegate.t != t;
}

class _PixelHeartsPainter extends CustomPainter {
  final double t;
  _PixelHeartsPainter(this.t);

  static const _heart = [
    [0, 1, 1, 0, 1, 1, 0],
    [1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1],
    [0, 1, 1, 1, 1, 1, 0],
    [0, 0, 1, 1, 1, 0, 0],
    [0, 0, 0, 1, 0, 0, 0],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(24);
    final float = sin(t * pi * 2);

    for (var i = 0; i < 14; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height + float * (4 + (i % 3) * 2);
      final scale = 2 + random.nextInt(3);
      final blush = random.nextBool();
      final color = (blush ? const Color(0xFFFB7185) : const Color(0xFFE11D48))
          .withValues(alpha: 0.18 + random.nextDouble() * 0.22);
      _drawHeart(canvas, Offset(x, y), scale.toDouble(), color);
    }
  }

  void _drawHeart(Canvas canvas, Offset origin, double scale, Color color) {
    final paint = Paint()..color = color;
    for (var row = 0; row < _heart.length; row++) {
      for (var col = 0; col < _heart[row].length; col++) {
        if (_heart[row][col] == 0) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            origin.dx + col * scale,
            origin.dy + row * scale,
            scale,
            scale,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelHeartsPainter oldDelegate) =>
      oldDelegate.t != t;
}

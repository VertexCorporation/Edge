import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';

/// Animated geometric background blobs matching Vertex website's geo-bg class.
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
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

/// Puts Uzay / Aşk pixel sky behind [child]. Surfaces should use [AppColors.fogColor].
class ThemedSkyShell extends StatelessWidget {
  final Widget child;

  const ThemedSkyShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Stack(
      fit: StackFit.expand,
      children: [
        if (AppColors.hasThemedSky)
          const IgnorePointer(child: _ThemeSky()),
        child,
      ],
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
      duration: const Duration(seconds: 10),
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
          size: Size.infinite,
        );
      },
    );
  }
}

class _PixelSpacePainter extends CustomPainter {
  final double t;
  _PixelSpacePainter(this.t);

  static final _stars = List.generate(140, (i) {
    final r = Random(i * 17 + 42);
    return _Star(
      x: r.nextDouble(),
      y: r.nextDouble(),
      size: 2.0 + r.nextInt(3),
      baseAlpha: 0.45 + r.nextDouble() * 0.5,
      twinkle: i % 4 == 0,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final twinkle = (sin(t * pi * 2) + 1) / 2;

    for (final star in _stars) {
      final pulse = star.twinkle ? (0.5 + 0.5 * twinkle) : 1.0;
      final paint = Paint()
        ..color = Color.fromRGBO(230, 235, 255, star.baseAlpha * pulse);
      canvas.drawRect(
        Rect.fromLTWH(
          star.x * size.width,
          star.y * size.height,
          star.size,
          star.size,
        ),
        paint,
      );
    }

    _drawPlanet(
      canvas,
      Offset(size.width * 0.78, size.height * 0.16),
      44,
      const Color(0xFF6366F1),
      const Color(0xFF1E1B4B),
      Random(7),
    );
    _drawPlanet(
      canvas,
      Offset(size.width * 0.12, size.height * 0.68),
      28,
      const Color(0xFFC084FC),
      const Color(0xFF4C1D95),
      Random(11),
    );
  }

  void _drawPlanet(
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
      center.translate(radius * 0.3, -radius * 0.15),
      radius * 0.95,
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
    canvas.drawCircle(
      center.translate(-radius * 0.42, radius * 0.22),
      radius * 0.85,
      Paint()..color = shadow.withValues(alpha: 0.65),
    );
    for (var i = 0; i < 8; i++) {
      final dx = (random.nextDouble() - 0.5) * radius * 1.3;
      final dy = (random.nextDouble() - 0.5) * radius * 1.3;
      final crater = 2.0 + random.nextInt(3);
      canvas.drawRect(
        Rect.fromCenter(
          center: center.translate(dx, dy),
          width: crater,
          height: crater,
        ),
        Paint()..color = shadow.withValues(alpha: 0.5),
      );
    }
    canvas.restore();
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = fill.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _PixelSpacePainter oldDelegate) =>
      oldDelegate.t != t;
}

class _Star {
  final double x;
  final double y;
  final double size;
  final double baseAlpha;
  final bool twinkle;

  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.baseAlpha,
    required this.twinkle,
  });
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

  static final _positions = List.generate(16, (i) {
    final r = Random(i * 31 + 24);
    return (
      x: r.nextDouble(),
      y: r.nextDouble(),
      scale: 3.0 + r.nextInt(3),
      dark: r.nextBool(),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final float = sin(t * pi * 2) * 6;

    for (var i = 0; i < _positions.length; i++) {
      final p = _positions[i];
      final x = p.x * size.width;
      final y = p.y * size.height + float * (0.4 + (i % 3) * 0.2);
      final color = (p.dark ? const Color(0xFFBE123C) : const Color(0xFFFB7185))
          .withValues(alpha: 0.42 + (i % 5) * 0.08);
      _drawHeart(canvas, Offset(x, y), p.scale, color);
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

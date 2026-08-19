import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
        // Overlay is cheap on non-web (repaints every animation tick),
        // and static on web (we pass t=0). This ensures all themes get the
        // charcoal texture.
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
    final isDarkLove = AppColors.darkMode && theme == 'love';

    // Web'de animasyonu kapatınca site kasılmasını ciddi azaltıyoruz.
    // (Animasyonun kendisi CustomPaint'i her frame yeniden çizdiriyor.)
    if (kIsWeb) {
      return CustomPaint(
        painter: _pickSkyPainter(
          t: 0,
          theme: theme,
          isDarkLove: isDarkLove,
          gold: AppColors.senaryColor,
          isDark: AppColors.isDarkUi,
        ),
        size: Size.infinite,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _pickSkyPainter(
            t: _controller.value,
            theme: theme,
            isDarkLove: isDarkLove,
            gold: AppColors.senaryColor,
            isDark: AppColors.isDarkUi,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  CustomPainter _pickSkyPainter({
    required double t,
    required String theme,
    required bool isDarkLove,
    required Color gold,
    required bool isDark,
  }) {
    return _CharcoalAndThemePainter(
      t: t,
      theme: theme,
      isDarkLove: isDarkLove,
      gold: gold,
      isDark: isDark,
    );
  }
}

/// Draws a subtle "charcoal" texture for all themes.
/// - For `deepSpace` / `love` / `porcelain` we keep the existing pixel sky effects.
/// - For `mint` (Adaçayı) we add green leaf shapes.
class _CharcoalAndThemePainter extends CustomPainter {
  final double t;
  final String theme;
  final bool isDarkLove;
  final Color gold;
  final bool isDark;

  _CharcoalAndThemePainter({
    required this.t,
    required this.theme,
    required this.isDarkLove,
    required this.gold,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // 1) Charcoal base (always).
    _CharcoalTexturePainter.draw(canvas, size, t: t, isDark: isDark);

    // 2) Optional mint leaves.
    if (theme == 'mint') {
      _MintLeavesPainter.draw(canvas, size, t: t, leafColor: gold, isDark: isDark);
    }

    // 3) Existing themed pixel sky.
    if (theme == 'love') {
      _PixelHeartsPainter(t, isDark: isDarkLove).paint(canvas, size);
      return;
    }
    if (theme == 'porcelain') {
      _PorcelainShardsPainter(t, gold: gold, isDark: isDark).paint(canvas, size);
      return;
    }
    if (theme == 'deepSpace') {
      _PixelSpacePainter(t).paint(canvas, size);
      return;
    }
    // For all other themes we only show charcoal (+ optional mint leaves above).
  }

  @override
  bool shouldRepaint(covariant _CharcoalAndThemePainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.theme != theme ||
      oldDelegate.isDarkLove != isDarkLove ||
      oldDelegate.gold != gold ||
      oldDelegate.isDark != isDark;
}

class _CharcoalTexturePainter {
  static void draw(Canvas canvas, Size size, {required double t, required bool isDark}) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);

    // Vignette.
    final vignette = RadialGradient(
      center: const Alignment(0.5, 0.35),
      radius: 1.1,
      colors: [
        Colors.transparent,
        (isDark ? Colors.black : Colors.black).withValues(alpha: 0.28),
      ],
      stops: const [0.55, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = vignette);

    // Charcoal smudges (seeded, deterministic).
    for (var i = 0; i < 18; i++) {
      final r = Random(i * 31 + 7);
      final x = r.nextDouble() * w;
      final y = r.nextDouble() * h;
      final base = 40.0 + r.nextDouble() * 120.0;

      final drift = isDark ? 1.0 : 0.8;
      final dx = sin(t * pi * 2 + i) * base * 0.003 * drift;
      final dy = cos(t * pi * 2 + i) * base * 0.002 * drift;

      final paint = Paint()
        ..color = Colors.black.withValues(alpha: (isDark ? 0.06 : 0.04) + r.nextDouble() * 0.05)
        ..blendMode = BlendMode.srcOver;

      canvas.drawCircle(Offset(x + dx, y + dy), base * (0.4 + r.nextDouble() * 0.3), paint);
    }

    // Fine grain / specks.
    for (var i = 0; i < 85; i++) {
      final r = Random(i * 19 + 3);
      final x = r.nextDouble() * w;
      final y = r.nextDouble() * h;
      final s = 0.8 + r.nextDouble() * 2.2;
      final a = (isDark ? 0.05 : 0.035) + r.nextDouble() * 0.05;
      final paint = Paint()..color = Colors.black.withValues(alpha: a);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: s, height: s),
        paint,
      );
    }

    // Subtle diagonal streaks.
    final streakPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.05 : 0.035)
      ..strokeWidth = 2;
    final streakCount = 7;
    for (var i = 0; i < streakCount; i++) {
      final r = Random(i * 13 + 1);
      final y = r.nextDouble() * h;
      final offset = sin(t * pi * 2 + i) * 12;
      canvas.drawLine(
        Offset(-w * 0.1, y + offset),
        Offset(w * 1.1, y - offset),
        streakPaint,
      );
    }
  }
}

class _MintLeavesPainter {
  static final _leaves = List.generate(22, (i) {
    final r = Random(i * 91 + 17);
    return (
      x: r.nextDouble(),
      y: r.nextDouble(),
      scale: 0.55 + r.nextDouble() * 0.9,
      rot: (r.nextDouble() - 0.5) * 1.6,
      phase: r.nextDouble() * pi * 2,
      sway: 0.75 + r.nextDouble() * 1.6,
      alpha: 0.12 + r.nextDouble() * 0.16,
      big: r.nextBool(),
    );
  });

  static void draw(
    Canvas canvas,
    Size size, {
    required double t,
    required Color leafColor,
    required bool isDark,
  }) {
    final w = size.width;
    final h = size.height;

    final base = leafColor.withValues(alpha: isDark ? 0.32 : 0.28);

    for (var i = 0; i < _leaves.length; i++) {
      final l = _leaves[i];
      final x = l.x * w;
      final y = l.y * h;

      final sway = sin(t * pi * 2 * 0.22 + l.phase) * (6.0 * l.sway);
      final dx = sin(t * pi * 2 * 0.28 + l.rot) * (10.0 * l.sway);

      final scale = l.scale * (l.big ? 1.05 : 0.95);
      final rot = l.rot + sin(t * pi * 2 * 0.14 + l.phase) * 0.18;

      canvas.save();
      canvas.translate(x + dx, y + sway);
      canvas.rotate(rot);

      final leafW = 22.0 * scale;
      final leafH = (36.0 + (l.big ? 6.0 : 0.0)) * scale;
      final alpha = l.alpha;
      final fill = base.withValues(alpha: alpha);

      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(leafW * 0.5, -leafH * 0.55, leafW, 0)
        ..quadraticBezierTo(leafW * 0.5, leafH * 0.55, 0, 0)
        ..close();

      canvas.drawPath(path, Paint()..color = fill);

      // Vein.
      final vein = leafColor.withValues(alpha: alpha * 0.55);
      canvas.drawLine(
        Offset(leafW * 0.5, 0),
        Offset(leafW * 0.5, leafH * 0.35),
        Paint()
          ..color = vein
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );

      canvas.restore();
    }
  }
}

class _PixelSpacePainter extends CustomPainter {
  final double t;
  _PixelSpacePainter(this.t);

  static final _stars = List.generate(90, (i) {
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
  final bool isDark;

  _PixelHeartsPainter(this.t, {this.isDark = false});

  static const _heart = [
    [0, 1, 1, 0, 1, 1, 0],
    [1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1],
    [0, 1, 1, 1, 1, 1, 0],
    [0, 0, 1, 1, 1, 0, 0],
    [0, 0, 0, 1, 0, 0, 0],
  ];

  static final _positions = List.generate(12, (i) {
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
      final color = (p.dark
              ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFBE123C))
              : (isDark ? const Color(0xFF991B1B) : const Color(0xFFFB7185)))
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
      oldDelegate.t != t || oldDelegate.isDark != isDark;
}

class _PorcelainShardsPainter extends CustomPainter {
  final double t;
  final Color gold;
  final bool isDark;

  _PorcelainShardsPainter(this.t, {required this.gold, required this.isDark});

  static final _shards = List.generate(48, (i) {
    final r = Random(i * 97 + 11);
    final points = List.generate(5, (p) {
      // Normalized jagged polygon points around (0,0)
      final x = (r.nextDouble() - 0.5) * 1.1;
      final y = (r.nextDouble() - 0.5) * 1.1;
      return Offset(x, y);
    });
    return (
      x: r.nextDouble(),
      y: r.nextDouble(),
      scale: 14.0 + r.nextDouble() * 22.0,
      rot: (r.nextDouble() - 0.5) * 3.14,
      alpha: 0.10 + r.nextDouble() * 0.20,
      phase: r.nextDouble() * pi * 2,
      points: points,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final base = min(size.width, size.height);
    final wobble = sin(t * pi * 2) * 10;

    for (var i = 0; i < _shards.length; i++) {
      final s = _shards[i];
      final pos = Offset(s.x * size.width, s.y * size.height);
      final shardSize = s.scale * (base / 420);

      final dx = sin(t * pi * 2 + s.phase) * (1.0 + (i % 4) * 0.5);
      final dy = cos(t * pi * 2 + s.phase) * (1.0 + (i % 3) * 0.6);

      canvas.save();
      canvas.translate(pos.dx + dx, pos.dy + dy + wobble * 0.02);
      canvas.rotate(s.rot + dx * 0.003);

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = gold.withValues(alpha: (isDark ? 0.08 : 0.10) + s.alpha);

      final outlinePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = gold.withValues(alpha: (isDark ? 0.18 : 0.24) + s.alpha * 0.4);

      final points = s.points;
      final path = Path();
      for (var p = 0; p < points.length; p++) {
        final pt = points[p];
        final local = Offset(pt.dx * shardSize, pt.dy * shardSize);
        if (p == 0) {
          path.moveTo(local.dx, local.dy);
        } else {
          path.lineTo(local.dx, local.dy);
        }
      }
      path.close();

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, outlinePaint);

      // Thin "crack" lines for a porcelain-break look.
      final crackPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = gold.withValues(alpha: (isDark ? 0.10 : 0.14) + s.alpha * 0.25);

      if (points.length >= 4) {
        final p0 = Offset(points[0].dx * shardSize, points[0].dy * shardSize);
        final p2 = Offset(points[2].dx * shardSize, points[2].dy * shardSize);
        final p3 = Offset(points[3].dx * shardSize, points[3].dy * shardSize);
        canvas.drawLine(p0, p2, crackPaint);
        canvas.drawLine(p2, p3, crackPaint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PorcelainShardsPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.gold != gold ||
      oldDelegate.isDark != isDark;
}

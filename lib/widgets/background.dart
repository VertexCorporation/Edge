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

/// Themed pixel-art background behind [child]. Surfaces should use [AppColors.fogColor].
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
    final isDarkLove = AppColors.darkMode && theme == 'love';

    if (kIsWeb) {
      return CustomPaint(
        painter: _pickSkyPainter(
          t: 0,
          theme: theme,
          isDarkLove: isDarkLove,
          accent: AppColors.senaryColor,
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
            accent: AppColors.senaryColor,
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
    required Color accent,
    required bool isDark,
  }) {
    switch (theme) {
      case 'love':
        return _PixelHeartsPainter(t, isDark: isDarkLove);
      case 'porcelain':
        return _PorcelainShardsPainter(t, gold: accent, isDark: isDark);
      case 'deepSpace':
        return _PixelSpacePainter(t);
      case 'mint':
        return _MintLeavesPainter(t, leafColor: accent, isDark: isDark);
      case 'sunset':
        return _SunsetPainter(t, accent: accent, isDark: isDark);
      case 'ocean':
        return _OceanWavesPainter(t, accent: accent, isDark: isDark);
      case 'nature':
        return _NatureTreesPainter(t, accent: accent, isDark: isDark);
      case 'aurora':
        return _AuroraPainter(t, accent: accent, isDark: isDark);
      case 'nord':
        return _NordIcePainter(t, accent: accent, isDark: isDark);
      default:
        return _EmptyPainter();
    }
  }
}

class _EmptyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// deepSpace — stars + planets
// ---------------------------------------------------------------------------
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

    _drawPlanet(canvas, Offset(size.width * 0.78, size.height * 0.16), 44,
        const Color(0xFF6366F1), const Color(0xFF1E1B4B), Random(7));
    _drawPlanet(canvas, Offset(size.width * 0.12, size.height * 0.68), 28,
        const Color(0xFFC084FC), const Color(0xFF4C1D95), Random(11));
  }

  void _drawPlanet(Canvas canvas, Offset center, double radius, Color fill,
      Color shadow, Random random) {
    canvas.drawCircle(center, radius, Paint()..color = fill);
    canvas.save();
    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)));
    canvas.drawCircle(center.translate(radius * 0.3, -radius * 0.15),
        radius * 0.95, Paint()..color = Colors.white.withValues(alpha: 0.22));
    canvas.drawCircle(center.translate(-radius * 0.42, radius * 0.22),
        radius * 0.85, Paint()..color = shadow.withValues(alpha: 0.65));
    for (var i = 0; i < 8; i++) {
      final dx = (random.nextDouble() - 0.5) * radius * 1.3;
      final dy = (random.nextDouble() - 0.5) * radius * 1.3;
      final crater = 2.0 + random.nextInt(3);
      canvas.drawRect(
        Rect.fromCenter(
            center: center.translate(dx, dy), width: crater, height: crater),
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
          ..color = fill.withValues(alpha: 0.5));
  }

  @override
  bool shouldRepaint(covariant _PixelSpacePainter oldDelegate) =>
      oldDelegate.t != t;
}

class _Star {
  final double x, y, size, baseAlpha;
  final bool twinkle;
  const _Star(
      {required this.x,
      required this.y,
      required this.size,
      required this.baseAlpha,
      required this.twinkle});
}

// ---------------------------------------------------------------------------
// love — pixel hearts
// ---------------------------------------------------------------------------
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
    return (x: r.nextDouble(), y: r.nextDouble(), scale: 3.0 + r.nextInt(3), dark: r.nextBool());
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
          Rect.fromLTWH(origin.dx + col * scale, origin.dy + row * scale, scale, scale),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelHeartsPainter o) => o.t != t || o.isDark != isDark;
}

// ---------------------------------------------------------------------------
// porcelain — broken gold shards
// ---------------------------------------------------------------------------
class _PorcelainShardsPainter extends CustomPainter {
  final double t;
  final Color gold;
  final bool isDark;
  _PorcelainShardsPainter(this.t, {required this.gold, required this.isDark});

  static final _shards = List.generate(48, (i) {
    final r = Random(i * 97 + 11);
    final points = List.generate(5, (_) => Offset((r.nextDouble() - 0.5) * 1.1, (r.nextDouble() - 0.5) * 1.1));
    return (
      x: r.nextDouble(), y: r.nextDouble(), scale: 14.0 + r.nextDouble() * 22.0,
      rot: (r.nextDouble() - 0.5) * 3.14, alpha: 0.10 + r.nextDouble() * 0.20,
      phase: r.nextDouble() * pi * 2, points: points,
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
      final fill = Paint()..color = gold.withValues(alpha: (isDark ? 0.08 : 0.10) + s.alpha);
      final outline = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = gold.withValues(alpha: (isDark ? 0.18 : 0.24) + s.alpha * 0.4);
      final pts = s.points;
      final path = Path()..moveTo(pts[0].dx * shardSize, pts[0].dy * shardSize);
      for (var p = 1; p < pts.length; p++) {
        path.lineTo(pts[p].dx * shardSize, pts[p].dy * shardSize);
      }
      path.close();
      canvas.drawPath(path, fill);
      canvas.drawPath(path, outline);
      if (pts.length >= 4) {
        final crack = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = gold.withValues(alpha: (isDark ? 0.10 : 0.14) + s.alpha * 0.25);
        canvas.drawLine(Offset(pts[0].dx * shardSize, pts[0].dy * shardSize),
            Offset(pts[2].dx * shardSize, pts[2].dy * shardSize), crack);
        canvas.drawLine(Offset(pts[2].dx * shardSize, pts[2].dy * shardSize),
            Offset(pts[3].dx * shardSize, pts[3].dy * shardSize), crack);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PorcelainShardsPainter o) =>
      o.t != t || o.gold != gold || o.isDark != isDark;
}

// ---------------------------------------------------------------------------
// mint (Adaçayı) — green leaves
// ---------------------------------------------------------------------------
class _MintLeavesPainter extends CustomPainter {
  final double t;
  final Color leafColor;
  final bool isDark;
  _MintLeavesPainter(this.t, {required this.leafColor, required this.isDark});

  static final _leaves = List.generate(22, (i) {
    final r = Random(i * 91 + 17);
    return (
      x: r.nextDouble(), y: r.nextDouble(), scale: 0.55 + r.nextDouble() * 0.9,
      rot: (r.nextDouble() - 0.5) * 1.6, phase: r.nextDouble() * pi * 2,
      sway: 0.75 + r.nextDouble() * 1.6, alpha: 0.12 + r.nextDouble() * 0.16,
      big: r.nextBool(),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final base = leafColor.withValues(alpha: isDark ? 0.32 : 0.28);

    for (var i = 0; i < _leaves.length; i++) {
      final l = _leaves[i];
      final sway = sin(t * pi * 2 * 0.22 + l.phase) * (6.0 * l.sway);
      final dx = sin(t * pi * 2 * 0.28 + l.rot) * (10.0 * l.sway);
      final scale = l.scale * (l.big ? 1.05 : 0.95);
      final rot = l.rot + sin(t * pi * 2 * 0.14 + l.phase) * 0.18;
      canvas.save();
      canvas.translate(l.x * w + dx, l.y * h + sway);
      canvas.rotate(rot);
      final leafW = 22.0 * scale;
      final leafH = (36.0 + (l.big ? 6.0 : 0.0)) * scale;
      final fill = base.withValues(alpha: l.alpha);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(leafW * 0.5, -leafH * 0.55, leafW, 0)
        ..quadraticBezierTo(leafW * 0.5, leafH * 0.55, 0, 0)
        ..close();
      canvas.drawPath(path, Paint()..color = fill);
      canvas.drawLine(
        Offset(leafW * 0.5, 0),
        Offset(leafW * 0.5, leafH * 0.35),
        Paint()
          ..color = leafColor.withValues(alpha: l.alpha * 0.55)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _MintLeavesPainter o) =>
      o.t != t || o.leafColor != leafColor || o.isDark != isDark;
}

// ---------------------------------------------------------------------------
// sunset (Gün Batımı) — pixel sun + warm glow
// ---------------------------------------------------------------------------
class _SunsetPainter extends CustomPainter {
  final double t;
  final Color accent;
  final bool isDark;
  _SunsetPainter(this.t, {required this.accent, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;

    // Sun position: slightly right, upper third, gentle bob.
    final sunX = w * 0.72;
    final sunY = h * 0.22 + sin(t * pi * 2 * 0.3) * 6;
    final sunR = min(w, h) * 0.09;

    // Warm radial glow behind the sun.
    final glowRect = Rect.fromCircle(center: Offset(sunX, sunY), radius: sunR * 5);
    final glowShader = RadialGradient(
      colors: [
        accent.withValues(alpha: isDark ? 0.12 : 0.10),
        accent.withValues(alpha: 0),
      ],
    ).createShader(glowRect);
    canvas.drawRect(glowRect, Paint()..shader = glowShader);

    // Sun disc (pixel-style: concentric squares).
    final sunColor = accent.withValues(alpha: isDark ? 0.45 : 0.40);
    final px = sunR / 6;
    for (var ring = 6; ring >= 0; ring--) {
      final alpha = (0.15 + (6 - ring) * 0.04).clamp(0.0, 1.0);
      final p = Paint()..color = sunColor.withValues(alpha: alpha);
      final side = px * ring * 2;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(sunX, sunY), width: side, height: side),
        p,
      );
    }

    // Sun rays as pixel lines.
    final rayPaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.18 : 0.14)
      ..strokeWidth = 2;
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * pi * 2 + t * pi * 0.3;
      final inner = sunR * 1.3;
      final outer = sunR * (2.0 + sin(t * pi * 2 + i) * 0.4);
      canvas.drawLine(
        Offset(sunX + cos(angle) * inner, sunY + sin(angle) * inner),
        Offset(sunX + cos(angle) * outer, sunY + sin(angle) * outer),
        rayPaint,
      );
    }

    // Horizon line bands.
    for (var i = 0; i < 5; i++) {
      final bandY = h * (0.75 + i * 0.05);
      final bandAlpha = (0.06 - i * 0.01).clamp(0.0, 1.0);
      canvas.drawRect(
        Rect.fromLTWH(0, bandY, w, 3),
        Paint()..color = accent.withValues(alpha: bandAlpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SunsetPainter o) =>
      o.t != t || o.accent != accent || o.isDark != isDark;
}

// ---------------------------------------------------------------------------
// ocean (Okyanus) — pixel waves
// ---------------------------------------------------------------------------
class _OceanWavesPainter extends CustomPainter {
  final double t;
  final Color accent;
  final bool isDark;
  _OceanWavesPainter(this.t, {required this.accent, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;

    // Draw 4 wave layers from bottom.
    for (var layer = 0; layer < 4; layer++) {
      final baseY = h * (0.55 + layer * 0.12);
      final amp = 12.0 - layer * 2;
      final freq = 3.0 + layer * 0.5;
      final phase = t * pi * 2 * (0.2 + layer * 0.08) + layer * 1.2;
      final alpha = (isDark ? 0.14 : 0.10) - layer * 0.02;

      final path = Path()..moveTo(0, h);
      for (var x = 0.0; x <= w; x += 4) {
        final y = baseY + sin(x / w * pi * freq + phase) * amp;
        path.lineTo(x, y);
      }
      path.lineTo(w, h);
      path.close();

      canvas.drawPath(path, Paint()..color = accent.withValues(alpha: alpha.clamp(0.02, 1.0)));
    }

    // Foam pixels along the top wave.
    final foamY = h * 0.55;
    final foamPhase = t * pi * 2 * 0.2;
    final foamPaint = Paint()..color = Colors.white.withValues(alpha: isDark ? 0.08 : 0.06);
    for (var i = 0; i < 30; i++) {
      final r = Random(i * 53 + 9);
      final fx = r.nextDouble() * w;
      final fy = foamY + sin(fx / w * pi * 3 + foamPhase) * 12 - 4 + r.nextDouble() * 6;
      canvas.drawRect(Rect.fromLTWH(fx, fy, 3, 3), foamPaint);
    }

    // Subtle reflection sparkles.
    final sparkle = (sin(t * pi * 2 * 1.5) + 1) / 2;
    for (var i = 0; i < 12; i++) {
      final r = Random(i * 71 + 3);
      final sx = r.nextDouble() * w;
      final sy = h * (0.6 + r.nextDouble() * 0.35);
      final sa = (0.04 + sparkle * 0.06) * (isDark ? 1.2 : 0.9);
      canvas.drawRect(
        Rect.fromLTWH(sx, sy, 2, 2),
        Paint()..color = Colors.white.withValues(alpha: sa),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OceanWavesPainter o) =>
      o.t != t || o.accent != accent || o.isDark != isDark;
}

// ---------------------------------------------------------------------------
// nature (Doğa) — pixel trees
// ---------------------------------------------------------------------------
class _NatureTreesPainter extends CustomPainter {
  final double t;
  final Color accent;
  final bool isDark;
  _NatureTreesPainter(this.t, {required this.accent, required this.isDark});

  static final _trees = List.generate(10, (i) {
    final r = Random(i * 43 + 7);
    return (
      x: r.nextDouble(),
      height: 0.12 + r.nextDouble() * 0.18,
      trunkW: 3.0 + r.nextDouble() * 2,
      crownW: 0.04 + r.nextDouble() * 0.04,
      sway: r.nextDouble() * pi * 2,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;

    for (var i = 0; i < _trees.length; i++) {
      final tr = _trees[i];
      final baseX = tr.x * w;
      final treeH = tr.height * h;
      final baseY = h * 0.92;
      final sway = sin(t * pi * 2 * 0.15 + tr.sway) * 3;

      // Trunk (pixel rectangles).
      final trunkPaint = Paint()
        ..color = (isDark ? const Color(0xFF3D2B1A) : const Color(0xFF5D4037))
            .withValues(alpha: 0.35);
      canvas.drawRect(
        Rect.fromLTWH(baseX - tr.trunkW / 2, baseY - treeH, tr.trunkW, treeH),
        trunkPaint,
      );

      // Crown: 3 stacked triangles (pixel-ish).
      final crownColor = accent.withValues(alpha: isDark ? 0.22 : 0.18);
      for (var layer = 0; layer < 3; layer++) {
        final layerY = baseY - treeH + layer * treeH * 0.15;
        final layerW = tr.crownW * w * (1.0 - layer * 0.2);
        final layerH = treeH * 0.45;
        final path = Path()
          ..moveTo(baseX + sway, layerY - layerH)
          ..lineTo(baseX - layerW / 2 + sway * 0.5, layerY)
          ..lineTo(baseX + layerW / 2 + sway * 0.5, layerY)
          ..close();
        canvas.drawPath(
          path,
          Paint()..color = crownColor.withValues(alpha: crownColor.alpha - layer * 0.03),
        );
      }
    }

    // Ground line.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.92, w, 2),
      Paint()..color = accent.withValues(alpha: isDark ? 0.10 : 0.08),
    );
  }

  @override
  bool shouldRepaint(covariant _NatureTreesPainter o) =>
      o.t != t || o.accent != accent || o.isDark != isDark;
}

// ---------------------------------------------------------------------------
// aurora — northern lights bands
// ---------------------------------------------------------------------------
class _AuroraPainter extends CustomPainter {
  final double t;
  final Color accent;
  final bool isDark;
  _AuroraPainter(this.t, {required this.accent, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;

    // 3 aurora bands with different phases and colors.
    final colors = [
      accent,
      Color.lerp(accent, Colors.green, 0.4)!,
      Color.lerp(accent, Colors.purple, 0.3)!,
    ];

    for (var band = 0; band < 3; band++) {
      final baseY = h * (0.15 + band * 0.12);
      final phase = t * pi * 2 * (0.12 + band * 0.04) + band * 2.1;
      final amp = 30.0 + band * 10;
      final bandColor = colors[band].withValues(alpha: isDark ? 0.12 : 0.08);

      final path = Path();
      path.moveTo(0, baseY);
      for (var x = 0.0; x <= w; x += 3) {
        final y = baseY +
            sin(x / w * pi * 2 + phase) * amp +
            sin(x / w * pi * 4 + phase * 1.7) * amp * 0.3;
        path.lineTo(x, y);
      }
      // Close band with thickness.
      for (var x = w; x >= 0; x -= 3) {
        final y = baseY +
            sin(x / w * pi * 2 + phase) * amp +
            sin(x / w * pi * 4 + phase * 1.7) * amp * 0.3 +
            (40 + band * 15);
        path.lineTo(x, y);
      }
      path.close();

      canvas.drawPath(path, Paint()..color = bandColor);

      // Shimmer along the top edge.
      final shimmer = (sin(t * pi * 2 * 0.8 + band) + 1) / 2;
      for (var i = 0; i < 15; i++) {
        final r = Random(i * 37 + band * 99);
        final sx = r.nextDouble() * w;
        final sy = baseY + sin(sx / w * pi * 2 + phase) * amp - 2;
        canvas.drawRect(
          Rect.fromLTWH(sx, sy, 2, 2),
          Paint()..color = Colors.white.withValues(alpha: 0.04 + shimmer * 0.04),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter o) =>
      o.t != t || o.accent != accent || o.isDark != isDark;
}

// ---------------------------------------------------------------------------
// nord — pixel ice crystals
// ---------------------------------------------------------------------------
class _NordIcePainter extends CustomPainter {
  final double t;
  final Color accent;
  final bool isDark;
  _NordIcePainter(this.t, {required this.accent, required this.isDark});

  static final _crystals = List.generate(28, (i) {
    final r = Random(i * 61 + 23);
    return (
      x: r.nextDouble(),
      y: r.nextDouble(),
      size: 3.0 + r.nextDouble() * 5.0,
      rot: r.nextDouble() * pi,
      phase: r.nextDouble() * pi * 2,
      alpha: 0.10 + r.nextDouble() * 0.15,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;

    for (var i = 0; i < _crystals.length; i++) {
      final c = _crystals[i];
      final cx = c.x * w;
      final cy = c.y * h;
      final drift = sin(t * pi * 2 * 0.18 + c.phase) * 4;
      final rot = c.rot + sin(t * pi * 2 * 0.1 + c.phase) * 0.15;

      canvas.save();
      canvas.translate(cx + drift, cy);
      canvas.rotate(rot);

      final px = c.size;
      final color = accent.withValues(alpha: c.alpha);
      final paint = Paint()..color = color;

      // 6-armed pixel snowflake/crystal.
      for (var arm = 0; arm < 6; arm++) {
        final angle = arm * pi / 3;
        // Main arm — 3 pixel blocks.
        for (var seg = 1; seg <= 3; seg++) {
          final ox = cos(angle) * px * seg;
          final oy = sin(angle) * px * seg;
          canvas.drawRect(
            Rect.fromCenter(center: Offset(ox, oy), width: px * 0.9, height: px * 0.9),
            paint,
          );
        }
        // Branch at segment 2.
        final branchAngle = angle + pi / 6;
        final bx = cos(angle) * px * 2 + cos(branchAngle) * px;
        final by = sin(angle) * px * 2 + sin(branchAngle) * px;
        canvas.drawRect(
          Rect.fromCenter(center: Offset(bx, by), width: px * 0.7, height: px * 0.7),
          paint,
        );
      }
      // Center pixel.
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: px, height: px),
        paint,
      );

      canvas.restore();
    }

    // Frost edge along the bottom.
    final frostPaint = Paint()..color = accent.withValues(alpha: isDark ? 0.08 : 0.06);
    for (var i = 0; i < 40; i++) {
      final r = Random(i * 29 + 5);
      final fx = r.nextDouble() * w;
      final fy = h - r.nextDouble() * h * 0.06;
      final fs = 2.0 + r.nextDouble() * 3;
      canvas.drawRect(Rect.fromLTWH(fx, fy, fs, fs), frostPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NordIcePainter o) =>
      o.t != t || o.accent != accent || o.isDark != isDark;
}

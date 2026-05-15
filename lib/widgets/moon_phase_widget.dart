import 'package:flutter/material.dart';
import 'dart:math';
import '../models/menstrual_data.dart';

class MoonPhaseWidget extends StatelessWidget {
  final MoonPhase phase;
  final double illumination;
  final double size;
  final Animation<double>? pulseAnimation;

  const MoonPhaseWidget({
    super.key,
    required this.phase,
    required this.illumination,
    this.size = 120,
    this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _EnhancedMoonPainter(
        phase: phase,
        illumination: illumination,
        pulseValue: pulseAnimation?.value ?? 0.0,
      ),
    );
  }
}

class _EnhancedMoonPainter extends CustomPainter {
  final MoonPhase phase;
  final double illumination;
  final double pulseValue;

  _EnhancedMoonPainter({
    required this.phase,
    required this.illumination,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // 绘制脉冲光晕（点击时）
    if (pulseValue > 0) {
      _drawPulseGlow(canvas, center, r);
    }

    // 外发光（持续）
    _drawOuterGlow(canvas, center, r);

    // 月球底色
    canvas.drawCircle(center, r, Paint()..color = const Color(0xFF3A3A4A));

    // 照明区域
    _drawIllumination(canvas, center, r);

    // 月球纹理（陨石坑 + 阴影细节）
    _drawCraters(canvas, center, r);
    _drawMarePatterns(canvas, center, r);

    // 边缘高光
    _drawEdgeHighlight(canvas, center, r);
  }

  /// 脉冲光晕（点击反馈）
  void _drawPulseGlow(Canvas canvas, Offset center, double r) {
    final glowRadius = r + (20 * pulseValue);
    final opacity = 0.3 * (1 - pulseValue);

    canvas.drawCircle(
      center,
      glowRadius,
      Paint()
        ..color = const Color(0xFFD4A8E1).withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
    );
  }

  /// 外发光（持续）
  void _drawOuterGlow(Canvas canvas, Offset center, double r) {
    // 内层光晕
    canvas.drawCircle(
      center,
      r + 6,
      Paint()
        ..color = const Color(0xFFD4A8E1).withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // 外层光晕
    canvas.drawCircle(
      center,
      r + 12,
      Paint()
        ..color = const Color(0xFFD4A8E1).withOpacity(0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
  }

  /// 照明区域（发光部分）
  void _drawIllumination(Canvas canvas, Offset center, double r) {
    final phaseVal = _phaseValue();
    if (phaseVal < 0.01) return; // 新月不发光

    // 渐变光照
    final lightPaint =
        Paint()
          ..shader = RadialGradient(
            center: Alignment.center,
            colors: [
              const Color(0xFFFFF5E6), // 中心亮白
              const Color(0xFFF5E6D0), // 中间象牙白
              const Color(0xFFD4C0A8), // 边缘米黄
            ],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: r));

    final moonCircle =
        Path()..addOval(Rect.fromCircle(center: center, radius: r));

    // 根据月相计算明暗分界线
    final Path litPath;
    if (phaseVal <= 0.5) {
      // 上半周期（新月 → 满月）：从右侧逐渐发光
      final phase = phaseVal * 2; // 0 -> 1
      final xOffset = r * (1 - phase * 2); // r -> -r

      final litRegion =
          Path()..addOval(
            Rect.fromCenter(
              center: Offset(center.dx + xOffset, center.dy),
              width: r * 2 * phase.clamp(0.1, 1.0),
              height: r * 2,
            ),
          );

      litPath = Path.combine(PathOperation.intersect, moonCircle, litRegion);
    } else {
      // 下半周期（满月 → 残月）：从左侧逐渐变暗
      final phase = (phaseVal - 0.5) * 2; // 0 -> 1
      final xOffset = -r * (1 - phase * 2); // -r -> r

      final litRegion =
          Path()..addOval(
            Rect.fromCenter(
              center: Offset(center.dx + xOffset, center.dy),
              width: r * 2 * (1 - phase).clamp(0.1, 1.0),
              height: r * 2,
            ),
          );

      litPath = Path.combine(PathOperation.intersect, moonCircle, litRegion);
    }

    canvas.drawPath(litPath, lightPaint);

    // 发光边缘加强
    canvas.drawPath(
      litPath,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.topRight,
          radius: 1.2,
          colors: [
            const Color(0xFFFFFFFF).withOpacity(0.3),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r))
        ..style = PaintingStyle.fill,
    );
  }

  /// 陨石坑纹理
  void _drawCraters(Canvas canvas, Offset center, double r) {
    final craterPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.12)
          ..style = PaintingStyle.fill;

    final craterHighlight =
        Paint()
          ..color = Colors.white.withOpacity(0.04)
          ..style = PaintingStyle.fill;

    // 大陨石坑
    final crater1 = Offset(center.dx + r * 0.25, center.dy - r * 0.15);
    canvas.drawCircle(crater1, r * 0.13, craterPaint);
    canvas.drawCircle(
      crater1 + const Offset(-1, -1),
      r * 0.06,
      craterHighlight,
    );

    // 中陨石坑
    final crater2 = Offset(center.dx - r * 0.35, center.dy + r * 0.25);
    canvas.drawCircle(crater2, r * 0.09, craterPaint);
    canvas.drawCircle(
      crater2 + const Offset(-0.5, -0.5),
      r * 0.04,
      craterHighlight,
    );

    // 小陨石坑
    final crater3 = Offset(center.dx + r * 0.1, center.dy + r * 0.4);
    canvas.drawCircle(crater3, r * 0.06, craterPaint);

    final crater4 = Offset(center.dx - r * 0.15, center.dy - r * 0.35);
    canvas.drawCircle(crater4, r * 0.055, craterPaint);

    final crater5 = Offset(center.dx + r * 0.45, center.dy + r * 0.1);
    canvas.drawCircle(crater5, r * 0.045, craterPaint);
  }

  /// 月海纹理（深色区域）
  void _drawMarePatterns(Canvas canvas, Offset center, double r) {
    final marePaint =
        Paint()
          ..color = Colors.black.withOpacity(0.06)
          ..style = PaintingStyle.fill;

    // 月海1（大面积深色区）
    final mare1 =
        Path()..addOval(
          Rect.fromCenter(
            center: Offset(center.dx - r * 0.2, center.dy - r * 0.1),
            width: r * 0.6,
            height: r * 0.5,
          ),
        );
    canvas.drawPath(mare1, marePaint);

    // 月海2
    final mare2 =
        Path()..addOval(
          Rect.fromCenter(
            center: Offset(center.dx + r * 0.3, center.dy + r * 0.2),
            width: r * 0.4,
            height: r * 0.35,
          ),
        );
    canvas.drawPath(mare2, marePaint);
  }

  /// 边缘高光（增强立体感）
  void _drawEdgeHighlight(Canvas canvas, Offset center, double r) {
    final highlightPaint =
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.4),
            radius: 1.5,
            colors: [Colors.white.withOpacity(0.15), Colors.transparent],
          ).createShader(Rect.fromCircle(center: center, radius: r))
          ..style = PaintingStyle.fill;

    canvas.drawCircle(center, r, highlightPaint);
  }

  double _phaseValue() {
    switch (phase) {
      case MoonPhase.newMoon:
        return 0.0;
      case MoonPhase.waxingCrescent:
        return 0.125;
      case MoonPhase.firstQuarter:
        return 0.25;
      case MoonPhase.waxingGibbous:
        return 0.375;
      case MoonPhase.fullMoon:
        return 0.5;
      case MoonPhase.waningGibbous:
        return 0.625;
      case MoonPhase.lastQuarter:
        return 0.75;
      case MoonPhase.waningCrescent:
        return 0.875;
    }
  }

  @override
  bool shouldRepaint(covariant _EnhancedMoonPainter old) =>
      old.phase != phase || old.pulseValue != pulseValue;
}

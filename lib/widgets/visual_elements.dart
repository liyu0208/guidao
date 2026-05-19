import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui'; // 就是这一行，它是实现毛玻璃效果的“入场券”

class FloatingHudFrame extends StatelessWidget {
  final Widget child;
  final dynamic title;
  final List<Widget>? actions;

  const FloatingHudFrame({
    super.key,
    required this.child,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          /// 深空背景
          const DynamicStarBackground(),

          /// HUD轨道层
          const OrbitHudLayer(),

          /// 主内容
          SafeArea(
            child: Column(
              children: [

/// 顶部悬浮 HUD
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      DeepSpaceCapsule(
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: Colors.cyanAccent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.8), blurRadius: 12)],
              ),
            ),
            const SizedBox(width: 10),
            const Text("AI ONLINE", style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.2)),
          ],
        ),
      ),
    ],
  ),
),

                /// 页面标题
                Padding(
                  padding: const EdgeInsets.only(
                    left: 28,
                    right: 28,
                    top: 12,
                    bottom: 20,
                  ),
                  child: Row(
                    children: [

GestureDetector(
  onTap: () => Navigator.maybePop(context),
  child: Text(
    title,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 28,
      fontWeight: FontWeight.w300,
      letterSpacing: 1.5,
    ),
  ),
),

                      const Spacer(),

                      if (actions != null)
                        ...actions!,
                    ],
                  ),
                ),

                /// 内容区域
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeString() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }
}

class StarThemedDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  const StarThemedDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: const Color(0xFF000B18),
    insetPadding: const EdgeInsets.symmetric(horizontal: 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(25),
      side: const BorderSide(color: Colors.white10),
    ),
    child: Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 30),
          content,
          const SizedBox(height: 35),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: actions,
          ),
        ],
      ),
    ),
  );
}

class DynamicStarBackground extends StatefulWidget {
  const DynamicStarBackground({super.key});
  @override
  State<DynamicStarBackground> createState() => _DSBState();
}

class _DSBState extends State<DynamicStarBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  final List<StarModel> _stars = List.generate(140, (i) => StarModel());
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color.fromARGB(255, 0, 8, 17), Color.fromARGB(255, 0, 7, 22), Color.fromARGB(255, 0, 11, 21)],//从上到下 的渐变色，模拟深空的层次感
      ),
    ),
    child: AnimatedBuilder(
      animation: _c,
      builder:
          (ctx, child) =>
              CustomPaint(size: Size.infinite, painter: StarPainter(_stars)),
    ),
  );
}

class StarModel {
  double x = Random().nextDouble(),
      y = Random().nextDouble(),
      r = Random().nextDouble() * 2.5 + 0.5,
      us = Random().nextDouble() * 0.002 + 0.0005,
      ds = (Random().nextDouble() - 0.5) * 0.001,
      tp = Random().nextDouble() * pi * 2,
      ts = Random().nextDouble() * 0.4 + 0.1;
}

class StarPainter extends CustomPainter {
  final List<StarModel> stars;
  StarPainter(this.stars);
  @override
  void paint(Canvas canvas, Size size) {
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final p = Paint();
    for (var s in stars) {
      double cY = ((s.y - t * s.us) % 1.0 + 1.0) % 1.0,
          cX = ((s.x + t * s.ds + sin(t * 2 + s.tp) * 0.005) % 1.0 + 1.0) % 1.0;
      p.color = Colors.white.withValues(
  alpha: (0.1 + 0.9 * sin(t * pi * s.ts + s.tp)).clamp(0.0, 1.0),
);
      canvas.drawCircle(Offset(cX * size.width, cY * size.height), s.r, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AnimatedScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  const AnimatedScaleButton({
    super.key,
    required this.child,
    required this.onPressed,
  });
  @override
  State<AnimatedScaleButton> createState() => _ASBState();
}

class _ASBState extends State<AnimatedScaleButton> {
  double _s = 1.0;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _s = 0.92),
    onTapUp: (_) => setState(() => _s = 1.0),
    onTapCancel: () => setState(() => _s = 1.0),
    onTap: widget.onPressed,
    child: AnimatedScale(
      scale: _s,
      duration: const Duration(milliseconds: 100),
      child: widget.child,
    ),
  );
}

class MoonPhaseIcon extends StatelessWidget {
  const MoonPhaseIcon({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 18,
    height: 18,
    child: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
        Positioned(
          left: DateTime.now().day % 30 < 15 ? 6.0 : -6.0,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF00040A),
            ),
          ),
        ),
      ],
    ),
  );
}

class CustomWhitePlanetIcon extends StatelessWidget {
  const CustomWhitePlanetIcon({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 26,
    height: 26,
    child: CustomPaint(painter: PlanetPainter()),
  );
}

class PlanetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.35,
      p,
    );
    canvas.drawArc(
      Rect.fromLTRB(-2, size.height * 0.3, size.width + 2, size.height * 0.7),
      -0.2,
      3.5,
      false,
      p,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.4, size.height * 0.2, 3, 3),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class PlanetRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
    canvas.drawOval(
      Rect.fromLTRB(
        -3,
        size.height / 2 - 3,
        size.width + 3,
        size.height / 2 + 3,
      ),
      p,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CustomGlobeIcon extends StatelessWidget {
  final Color color;
  const CustomGlobeIcon({super.key, this.color = Colors.white});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 26,
    height: 26,
    child: CustomPaint(painter: GlobePainter(color)),
  );
}

class GlobePainter extends CustomPainter {
  final Color color;
  GlobePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
    // 画地球外圈
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.4,
      p,
    );
    // 画经纬线 (呈现立体感)
    canvas.drawOval(
      Rect.fromLTRB(
        size.width * 0.3,
        size.height * 0.1,
        size.width * 0.7,
        size.height * 0.9,
      ),
      p,
    );
    canvas.drawLine(
      Offset(size.width * 0.1, size.height / 2),
      Offset(size.width * 0.9, size.height / 2),
      p,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ── 月相图标（渐变月牙+陨石坑）──
// ── 月相图标 ──
// --------------------------------------------------
// --- 扁平单色风格：月相 (Flat Moon) ---
// --------------------------------------------------
// --------------------------------------------------
// --- 扁平单色风格：月相 (Flat Moon) ---
// --------------------------------------------------
class FlatMoonIcon extends StatelessWidget {
  final double size; // 🌟 就是缺了这个定义导致报错
  const FlatMoonIcon({super.key, this.size = 28});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size, height: size,
    child: CustomPaint(painter: _FlatMoonPainter()),
  );
}

class _FlatMoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.30;
    final dashPaint = Paint()..color = Colors.white.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 1.2..strokeCap = StrokeCap.round;
    _drawDashedCircle(canvas, center, size.width * 0.45, dashPaint, 3, 4);
    final fillPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    Path moon = Path()..addOval(Rect.fromCircle(center: center, radius: r));
    Path shadow = Path()..addOval(Rect.fromCircle(center: Offset(center.dx - r * 0.4, center.dy - r * 0.4), radius: r * 1.05));
    canvas.drawPath(Path.combine(PathOperation.difference, moon, shadow), fillPaint);
  }
  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Paint paint, double dashLen, double gapLen) {
    final circumference = 2 * pi * radius;
    final count = (circumference / (dashLen + gapLen)).floor();
    for (int i = 0; i < count; i++) {
      final startAngle = i * (dashLen + gapLen) / radius;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, dashLen / radius, false, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

  class OrbitHudLayer extends StatelessWidget {
  const OrbitHudLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [

          /// 左上轨道
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
            ),
          ),

          /// 右侧HUD圆环
          Positioned(
            right: -80,
            top: 180,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.cyanAccent.withOpacity(0.08),
                  width: 1,
                ),
              ),
            ),
          ),

          /// 下方轨道线
          Positioned(
            bottom: 120,
            left: -40,
            right: -40,
            child: Container(
              height: 1,
              color: Colors.white.withOpacity(0.04),
            ),
          ),
        ],
      ),
    );
  }
}



// 2. 优化后的极窄高透玻璃外壳
// --- 最完美的五芒星与玻璃气泡零件 ---
// --- 极简线条星球头像 ---
// --- 纯白线条形变：赛博星球图标 ---
// --- 智能随机科技头像：从你选出的 4 个图标中随机分发 ---
class PlanetAvatar extends StatelessWidget {
  final String seed;
  final double size;
  final double radius;
  const PlanetAvatar({super.key, required this.seed, this.size = 40, this.radius = 50});

  @override
  Widget build(BuildContext context) {
    // 1. 定义你选出的四个图标列表
    final List<IconData> cyberIcons = [
      Icons.satellite_alt,
      Icons.motion_photos_on,
      Icons.sensor_occupied,
      Icons.brightness_low,
    ];

    // 2. 根据种子（ID或名字）的哈希值来选择一个图标
    // 这样同一个用户永远会显示同一个图标，不会乱跳
    final int index = seed.hashCode.abs() % cyberIcons.length;
    final IconData selectedIcon = cyberIcons[index];

    return Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(radius),
  ),
      child: Center(
        child: Icon(
          selectedIcon,
          color: Colors.white, // 纯白线条，你最喜欢的极简风
          size: 24,
        ),
      ),
    );
  }
}

class CyberGlassContainer extends StatelessWidget {
  final Widget child;
  final bool isMe;
  const CyberGlassContainer({super.key, required this.child, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            // 极低透明度，让图标更突出
            color: isMe 
                ? Colors.blueAccent.withOpacity(0.08) 
                : Colors.white.withOpacity(0.03), 
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.05), // 细微的边缘
              width: 0.4,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class DeepSpaceCapsule extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const DeepSpaceCapsule({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
        ),
        child: Container(
          padding: padding ??
              const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.03),
                blurRadius: 30,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

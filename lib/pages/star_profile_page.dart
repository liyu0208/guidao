import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_role.dart';
import '../widgets/visual_elements.dart';

class StarProfilePage extends StatefulWidget {
  const StarProfilePage({super.key});
  @override
  State<StarProfilePage> createState() => _StarProfilePageState();
}

class _StarProfilePageState extends State<StarProfilePage> {
  String _getZodiac(String birthday) {
    try {
      final parts = birthday.split('-');
      if (parts.length < 2) return '';
      final month = int.parse(parts[0]);
      final day = int.parse(parts[1]);
      const signs = [
        [1, 20, '摩羯座'],
        [2, 19, '水瓶座'],
        [3, 21, '双鱼座'],
        [4, 20, '牡羊座'],
        [5, 21, '金牛座'],
        [6, 21, '双子座'],
        [7, 23, '巨蟹座'],
        [8, 23, '狮子座'],
        [9, 23, '处女座'],
        [10, 23, '天秤座'],
        [11, 22, '天蝎座'],
        [12, 22, '射手座'],
      ];
      for (int i = 0; i < signs.length; i++) {
        final s = signs[i];
        if (month == s[0]) {
          if (day < (s[1] as int)) return s[2] as String;
          return signs[(i + 1) % 12][2] as String;
        }
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  String get _mostChattedRole {
    if (ChatData.roles.isEmpty) return '暂无';
    final sorted = [...ChatData.roles]
      ..sort((a, b) => b.messages.length.compareTo(a.messages.length));
    if (sorted.first.messages.isEmpty) return '暂无';
    return sorted.first.remark.isNotEmpty
        ? sorted.first.remark
        : sorted.first.name;
  }

  int get _totalMessages =>
      ChatData.roles.fold(0, (s, r) => s + r.messages.length);

  void _showEditDialog() {
    final nC = TextEditingController(text: ChatData.userName);
    final sC = TextEditingController(text: ChatData.userSign);
    final mC = TextEditingController(text: ChatData.userMood);
    final lC = TextEditingController(text: ChatData.userLocation);
    final bC = TextEditingController(text: ChatData.userBirthday);

    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: const Color(0xFF000B18),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: const BorderSide(color: Colors.white10),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "编辑资料",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _editField(nC, "名字"),
                    _editField(lC, "所在地"),
                    _editField(bC, "生日 (格式: 月-日，如 3-15)"),
                    _editField(mC, "心情"),
                    _editField(sC, "个性签名"),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() => ChatData.userAvatar = '');
                            ChatData.saveUser();
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            "重置头像",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => ChatData.userBg = '');
                            ChatData.saveUser();
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            "重置背景",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent.withValues(
                              alpha: 0.2,
                            ),
                            side: const BorderSide(color: Colors.blueAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              if (nC.text.trim().isNotEmpty) {
                                ChatData.userName = nC.text.trim();
                              }
                              ChatData.userSign = sC.text.trim();
                              ChatData.userMood = mC.text.trim();
                              ChatData.userLocation = lC.text.trim();
                              ChatData.userBirthday = bC.text.trim();
                            });
                            ChatData.saveUser();
                            Navigator.pop(ctx);
                          },
                          child: const Text("保存"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _editField(TextEditingController c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: Colors.white38),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    ),
  );

  Future<void> _pickBg() async {
    final r = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (r != null) {
      final b = await r.readAsBytes();
      setState(() => ChatData.userBg = base64Encode(b));
      ChatData.saveUser();
    }
  }

  Future<void> _pickAvatar() async {
    final r = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (r != null) {
      final b = await r.readAsBytes();
      setState(() => ChatData.userAvatar = base64Encode(b));
      ChatData.saveUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final zodiac = _getZodiac(ChatData.userBirthday);

    return FloatingHudFrame(
      title: "星籍",
      actions: [
        IconButton(
          icon: const Icon(
            Icons.edit_outlined,
            color: Colors.blueAccent,
            size: 20,
          ),
          onPressed: _showEditDialog,
        ),
      ],
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── 背景封面 + 头像 ──
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: _pickBg,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF000000),
                        Color(0xFF050505),
                        Color(0xFF0A0A0A),
                      ],
                    ),
                    image:
                        ChatData.userBg.isNotEmpty
                            ? DecorationImage(
                              image: MemoryImage(base64Decode(ChatData.userBg)),
                              fit: BoxFit.cover,
                            )
                            : null,
                  ),
                  child:
                      ChatData.userBg.isEmpty
                          ? Stack(
                            children: [
                              // 星点装饰
                              ...List.generate(20, (i) {
                                final rand = Random(i);
                                return Positioned(
                                  left: rand.nextDouble() * 400,
                                  top: rand.nextDouble() * 150,
                                  child: Container(
                                    width: rand.nextDouble() * 2 + 1,
                                    height: rand.nextDouble() * 2 + 1,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(
                                        alpha: rand.nextDouble() * 0.6 + 0.2,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          )
                          : null,
                ),
              ),
              Positioned(
                bottom: -40,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color.fromARGB(78, 209, 229, 252),
                          width: 1,
                        ),
                      ),
                      child: ClipOval(
                        child:
                            ChatData.userAvatar.isEmpty
                                ? Container(
                                  color: const Color.fromARGB(83, 0, 1, 5),
                                  child: const _DefaultAvatarPlanet(),
                                )
                                : Image.memory(
                                  base64Decode(ChatData.userAvatar),
                                  fit: BoxFit.cover,
                                ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 50),

          // ── 基础信息（顺序：名字→地址+生日→心情→签名）──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 名字
                Text(
                  ChatData.userName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // 地址 + 生日 一行
                if (ChatData.userLocation.isNotEmpty ||
                    ChatData.userBirthday.isNotEmpty)
                  Wrap(
                    spacing: 16,
                    children: [
                      if (ChatData.userLocation.isNotEmpty)
                        _tag(Icons.location_on_outlined, ChatData.userLocation),
                      if (ChatData.userBirthday.isNotEmpty)
                        _tag(Icons.cake_outlined, ChatData.userBirthday),
                      if (zodiac.isNotEmpty)
                        _tag(Icons.auto_awesome_outlined, zodiac),
                    ],
                  ),

                // 心情
                if (ChatData.userMood.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.mood,
                        size: 14,
                        color: Colors.amberAccent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        ChatData.userMood,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],

                // 签名
                if (ChatData.userSign.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    ChatData.userSign,
                    style: const TextStyle(fontSize: 13, color: Colors.white54),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── 数据统计 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "星轨数据",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _statCard(
                      "星友",
                      "${ChatData.roles.length}",
                      Icons.people_outline,
                    ),
                    const SizedBox(width: 10),
                    _statCard(
                      "消息",
                      "$_totalMessages",
                      Icons.chat_bubble_outline,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _wideStatCard("最常聊", _mostChattedRole, Icons.favorite_border),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── 星际伙伴 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "星际伙伴",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(child: _buildPet(ChatData.userPet)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              ['卫星', '星球', '宇航员'].map((pet) {
                                final selected = ChatData.userPet == pet;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => ChatData.userPet = pet);
                                    ChatData.saveUser();
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          selected
                                              ? Colors.blueAccent.withValues(
                                                alpha: 0.2,
                                              )
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            selected
                                                ? Colors.blueAccent
                                                : Colors.white24,
                                      ),
                                    ),
                                    child: Text(
                                      pet,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            selected
                                                ? Colors.blueAccent
                                                : Colors.white38,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPet(String type) {
    switch (type) {
      case '卫星':
        return const _SatellitePet();
      case '星球':
        return const _PlanetPet();
      case '宇航员':
        return const _AstronautPet();
      default:
        return const _SatellitePet();
    }
  }

  Widget _tag(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: Colors.white38),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 12, color: Colors.white54)),
    ],
  );

  Widget _statCard(String label, String value, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white38),
          ),
        ],
      ),
    ),
  );

  Widget _wideStatCard(String label, String value, IconData icon) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white10),
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white38),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════
//  桌宠：小卫星
// ══════════════════════════════════════════════
class _SatellitePet extends StatefulWidget {
  const _SatellitePet();
  @override
  State<_SatellitePet> createState() => _SatellitePetState();
}

class _SatellitePetState extends State<_SatellitePet>
    with TickerProviderStateMixin {
  late AnimationController _orbit;
  late AnimationController _float;
  late Animation<double> _floatAnim;
  double _tapScale = 1.0;

  @override
  void initState() {
    super.initState();
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _floatAnim = Tween(
      begin: -6.0,
      end: 6.0,
    ).animate(CurvedAnimation(parent: _float, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _orbit.dispose();
    _float.dispose();
    super.dispose();
  }

  void _onTap() async {
    setState(() => _tapScale = 1.3);
    await Future.delayed(const Duration(milliseconds: 150));
    setState(() => _tapScale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_orbit, _float]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnim.value),
            child: AnimatedScale(
              scale: _tapScale,
              duration: const Duration(milliseconds: 150),
              child: CustomPaint(
                size: const Size(100, 100),
                painter: _SatellitePainter(_orbit.value * 2 * pi),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SatellitePainter extends CustomPainter {
  final double angle;
  _SatellitePainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = Colors.white.withValues(alpha: 0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 28, height: 18),
        const Radius.circular(4),
      ),
      paint,
    );

    paint.color = Colors.blueAccent.withValues(alpha: 0.8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 26, cy), width: 18, height: 8),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 26, cy), width: 18, height: 8),
        const Radius.circular(2),
      ),
      paint,
    );

    final linePaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, cy - 9), Offset(cx, cy - 18), linePaint);
    canvas.drawCircle(
      Offset(cx, cy - 19),
      2,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );

    final dotX = cx + 45 * cos(angle);
    final dotY = cy + 15 * sin(angle);
    paint.color = Colors.blueAccent.withValues(alpha: 0.6);
    canvas.drawCircle(Offset(dotX, dotY), 3, paint);

    final orbitPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 90, height: 30),
      orbitPaint,
    );
  }

  @override
  bool shouldRepaint(_SatellitePainter old) => old.angle != angle;
}

// ══════════════════════════════════════════════
//  桌宠：小星球
// ══════════════════════════════════════════════
class _PlanetPet extends StatefulWidget {
  const _PlanetPet();
  @override
  State<_PlanetPet> createState() => _PlanetPetState();
}

class _PlanetPetState extends State<_PlanetPet> with TickerProviderStateMixin {
  late AnimationController _rotate;
  late AnimationController _float;
  late Animation<double> _floatAnim;
  double _tapScale = 1.0;

  @override
  void initState() {
    super.initState();
    _rotate = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(parent: _float, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _rotate.dispose();
    _float.dispose();
    super.dispose();
  }

  void _onTap() async {
    setState(() => _tapScale = 1.25);
    await Future.delayed(const Duration(milliseconds: 150));
    setState(() => _tapScale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotate, _float]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnim.value),
            child: AnimatedScale(
              scale: _tapScale,
              duration: const Duration(milliseconds: 150),
              child: CustomPaint(
                size: const Size(100, 100),
                painter: _PlanetPainter(_rotate.value * 2 * pi),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlanetPainter extends CustomPainter {
  final double angle;
  _PlanetPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.drawCircle(
      Offset(cx, cy),
      28,
      Paint()
        ..color = Colors.purpleAccent.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    final shader = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      radius: 1.0,
      colors: [
        Colors.purple.shade300,
        Colors.purple.shade800,
        Colors.indigo.shade900,
      ],
    ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 24));

    canvas.drawCircle(Offset(cx, cy), 24, Paint()..shader = shader);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-0.3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 64, height: 16),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.restore();

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: 24)),
    );
    final linePaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    for (int i = 0; i < 3; i++) {
      final offset = angle * 8 + i * 16.0;
      canvas.drawLine(
        Offset(cx - 24, cy - 8 + offset % 48),
        Offset(cx + 24, cy - 8 + offset % 48),
        linePaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PlanetPainter old) => old.angle != angle;
}

// ══════════════════════════════════════════════
//  桌宠：小宇航员
// ══════════════════════════════════════════════
class _AstronautPet extends StatefulWidget {
  const _AstronautPet();
  @override
  State<_AstronautPet> createState() => _AstronautPetState();
}

class _AstronautPetState extends State<_AstronautPet>
    with TickerProviderStateMixin {
  late AnimationController _float;
  late AnimationController _wave;
  late Animation<double> _floatAnim;
  late Animation<double> _waveAnim;
  double _tapScale = 1.0;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _floatAnim = Tween(
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(parent: _float, curve: Curves.easeInOut));
    _waveAnim = Tween(
      begin: -0.3,
      end: 0.3,
    ).animate(CurvedAnimation(parent: _wave, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _float.dispose();
    _wave.dispose();
    super.dispose();
  }

  void _onTap() async {
    setState(() => _tapScale = 1.2);
    await Future.delayed(const Duration(milliseconds: 150));
    setState(() => _tapScale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_float, _wave]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnim.value),
            child: AnimatedScale(
              scale: _tapScale,
              duration: const Duration(milliseconds: 150),
              child: CustomPaint(
                size: const Size(100, 100),
                painter: _AstronautPainter(_waveAnim.value),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DefaultAvatarPlanet extends StatefulWidget {
  const _DefaultAvatarPlanet();
  @override
  State<_DefaultAvatarPlanet> createState() => _DefaultAvatarPlanetState();
}

class _DefaultAvatarPlanetState extends State<_DefaultAvatarPlanet>
    with TickerProviderStateMixin {
  late AnimationController _rotate;
  late AnimationController _glow;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _rotate = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnim = Tween(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _glow, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _rotate.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotate, _glow]),
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 80),
          painter: _DefaultPlanetPainter(
            _rotate.value * 2 * pi,
            _glowAnim.value,
          ),
        );
      },
    );
  }
}

class _DefaultPlanetPainter extends CustomPainter {
  final double angle;
  final double glowAlpha;
  _DefaultPlanetPainter(this.angle, this.glowAlpha);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.32;

    // 闪烁光晕
    canvas.drawCircle(
      Offset(cx, cy),
      r * 1.4,
      Paint()
        ..color = Colors.white.withValues(alpha: glowAlpha * 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 星球主体（单色半透明）
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );

    // 星球边缘线
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // 光环
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-0.3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 2.8, height: r * 0.5),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.restore();

    // 自转纹路
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );
    final linePaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
    for (int i = 0; i < 3; i++) {
      final offset = angle * 6 + i * 14.0;
      canvas.drawLine(
        Offset(cx - r, cy - 6 + offset % (r * 2.5)),
        Offset(cx + r, cy - 6 + offset % (r * 2.5)),
        linePaint,
      );
    }
    canvas.restore();

    // 闪烁小星点
    final starPaint =
        Paint()..color = Colors.white.withValues(alpha: glowAlpha * 0.8);
    canvas.drawCircle(Offset(cx - r * 0.3, cy - r * 0.4), 1.5, starPaint);
    canvas.drawCircle(Offset(cx + r * 0.4, cy - r * 0.2), 1, starPaint);
    canvas.drawCircle(Offset(cx - r * 0.1, cy + r * 0.35), 1.2, starPaint);
  }

  @override
  bool shouldRepaint(_DefaultPlanetPainter old) =>
      old.angle != angle || old.glowAlpha != glowAlpha;
}

class _AstronautPainter extends CustomPainter {
  final double waveAngle;
  _AstronautPainter(this.waveAngle);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = Colors.white.withValues(alpha: 0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 8), width: 28, height: 30),
        const Radius.circular(8),
      ),
      paint,
    );

    paint.color = Colors.white.withValues(alpha: 0.95);
    canvas.drawCircle(Offset(cx, cy - 10), 18, paint);

    paint.color = Colors.blueAccent.withValues(alpha: 0.4);
    canvas.drawCircle(Offset(cx, cy - 10), 13, paint);

    paint.color = Colors.white.withValues(alpha: 0.3);
    canvas.drawCircle(Offset(cx - 5, cy - 15), 5, paint);

    canvas.save();
    canvas.translate(cx - 18, cy + 2);
    canvas.rotate(waveAngle);
    paint.color = Colors.white.withValues(alpha: 0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 8, height: 18),
        const Radius.circular(4),
      ),
      paint,
    );
    canvas.restore();

    paint.color = Colors.white.withValues(alpha: 0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 18, cy + 2), width: 8, height: 18),
        const Radius.circular(4),
      ),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 8, cy + 28), width: 10, height: 16),
        const Radius.circular(4),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 8, cy + 28), width: 10, height: 16),
        const Radius.circular(4),
      ),
      paint,
    );

    paint.color = Colors.blueAccent.withValues(alpha: 0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 8), width: 10, height: 16),
        const Radius.circular(3),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_AstronautPainter old) => old.waveAngle != waveAngle;
}

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/star_bridge_api.dart';
import 'models/chat_role.dart';
import 'widgets/visual_elements.dart';
import 'pages/app_shell.dart';
import 'pages/star_bridge_page.dart';
import 'pages/chat_page.dart';
import 'models/world_book_data.dart';
import 'pages/world_book_page.dart';
import 'pages/stardust_warehouse_page.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'pages/core_cabin_page.dart';
import 'pages/star_profile_page.dart';
import 'pages/moon_phase_page.dart';
import 'models/menstrual_data.dart';
import 'models/habit_data.dart';
import 'pages/star_track_page.dart'; // 稍后创建
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../pages/star_diary_page.dart'; // 如果是在 pages 文件夹下
import 'dart:math';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WebViewPlatform.instance ??
      (WebViewPlatform.instance = AndroidWebViewPlatform());
  // 🔥 临时加这三行，清除旧的月经数据
  final prefs = await SharedPreferences.getInstance();
  // 恢复这两行代码的运行，App 启动时就会去硬盘/浏览器缓存里读取数据了
  await StarBridgeData.loadAll();
  await WorldBookManager.loadAll();
  await ChatData.loadAll();
  await ChatData.loadUser();
  await MenstrualData.loadAll();
  await HabitManager.load();

  runApp(const StarOrbitApp());
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class StarOrbitApp extends StatelessWidget {
  const StarOrbitApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
  scrollBehavior: MyCustomScrollBehavior(),
  debugShowCheckedModeBanner: false,
theme: ThemeData(
  brightness: Brightness.dark,
  fontFamily: 'sans-serif',
  useMaterial3: false,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  scaffoldBackgroundColor: Colors.transparent,
),
    home: const VirtualDesktop(),
  );
}

class VirtualDesktop extends StatefulWidget {
  const VirtualDesktop({super.key});
  @override
  State<VirtualDesktop> createState() => _VDState();
}

class _VDState extends State<VirtualDesktop>
    with SingleTickerProviderStateMixin {
  final _pC = PageController();
  final _bat = Battery();
  int _curP = 0;
  String _curT = "";
  int _batL = 100;
  late Timer _timer;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  String? _widgetImage;
  bool _heroFlipped = false;
  @override
  void initState() {
    super.initState();
    _up();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => _up());
    _loadWidgetImage();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  void _loadWidgetImage() async {
    final prefs = await SharedPreferences.getInstance();
    final img = prefs.getString('widget_image');
    if (mounted) setState(() => _widgetImage = img);
  }

  void _up() async {
    final n = DateTime.now();
    final l = await _bat.batteryLevel;
    if (mounted) {
      setState(() {
        _curT =
            "${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}";
        _batL = l;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double cw = w > 600 ? 450 : double.infinity;
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: Stack(
        children: [
          const DynamicStarBackground(),
          Center(
            child: SizedBox(
              width: cw,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SafeArea(
                  child: Column(
                    children: [
                      _top(),
                      const SizedBox(height: 8),
                      _heroCard(),
                      const SizedBox(height: 14),
                      Expanded(
                        child: PageView(
                          controller: _pC,
                          onPageChanged: (i) => setState(() => _curP = i),
                          children: [
                            _page(["星语", "星历", "星云", "星轨", "核心舱", "货舱", "月相"]),
                            _page(["星籍", "双星轨道"]),
                          ],
                        ),
                      ),
                      _ind(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _dock(cw),
        ],
      ),
    );
  }

  Widget _top() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const FlatMoonIcon(size: 20),
        Text(
          _curT,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
        Row(
          children: [
            const Icon(Icons.signal_cellular_alt, size: 14),
            const SizedBox(width: 5),
            Text(
              "$_batL%",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ],
    ),
  );
  Widget _card() => GestureDetector(
    onTap:
        () => Navigator.push(
          context,
          ElasticPageRoute(page: const StarProfilePage()),
        ),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ChatData.userAvatar.isEmpty
              ? Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 36,
                  color: Colors.white24,
                ),
              )
              : CircleAvatar(
                radius: 18,
                backgroundImage: MemoryImage(base64Decode(ChatData.userAvatar)),
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ChatData.userName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                if (ChatData.userMood.isNotEmpty)
                  Text(
                    ChatData.userMood,
                    style: const TextStyle(fontSize: 10, color: Colors.white24),
                  ),
              ],
            ),
          ),
          Text(
            ChatData.userSign,
            style: const TextStyle(fontSize: 9, color: Colors.white24),
          ),
        ],
      ),
    ),
  );
  Widget _statChip(String label, String value) => RichText(
    text: TextSpan(
      children: [
        TextSpan(
          text: "$label ",
          style: const TextStyle(fontSize: 9, color: Colors.white24),
        ),
        TextSpan(
          text: value,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );


Widget _heroCard() {
  // 取最近聊天的角色
  ChatRole? lastRole;
  if (ChatData.roles.isNotEmpty) {
    lastRole = ChatData.roles.reduce((a, b) => a.lastTime.isAfter(b.lastTime) ? a : b);
  }

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 25),
    height: 80,
    child: GestureDetector(
      onTap: () => setState(() => _heroFlipped = !_heroFlipped),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, anim) {
          final rotate = Tween(begin: pi, end: 0.0).animate(anim);
          return AnimatedBuilder(
            animation: rotate,
            child: child,
            builder: (ctx, child) {
              final isBack = rotate.value > pi / 2;
              return Transform(
                transform: Matrix4.rotationX(rotate.value),
                alignment: Alignment.center,
                child: isBack
                    ? Transform(
                        transform: Matrix4.rotationX(pi),
                        alignment: Alignment.center,
                        child: child,
                      )
                    : child,
              );
            },
          );
        },
        child: _heroFlipped
            ? _heroBack(lastRole)
            : _heroFront(),
      ),
    ),
  );
}

Widget _heroFront() => Stack(
  key: const ValueKey('front'),
  clipBehavior: Clip.none,
  children: [
    Positioned(
      top: 12, left: 8, right: 8, bottom: -6,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withValues(alpha: 0.5),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    Positioned(
      top: 6, left: 4, right: 4, bottom: -3,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withValues(alpha: 0.8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    ),
    Positioned(
      top: 0, left: 0, right: 0, bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D1F).withValues(alpha: 0.95),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: const Color(0xFF7B8FFF).withOpacity(0.08), blurRadius: 20),
            BoxShadow(color: Colors.white.withOpacity(0.03), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome, size: 13, color: Colors.white38),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text("星语", style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.white24),
              ],
            ),
            const SizedBox(height: 6),
            const Text("点击开始今天的对话...", style: TextStyle(fontSize: 10, color: Colors.white24)),
          ],
        ),
      ),
    ),
  ],
);

Widget _heroBack(ChatRole? role) => Container(
  key: const ValueKey('back'),
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  decoration: BoxDecoration(
    color: const Color(0xFF0D0D1F).withValues(alpha: 0.95),
    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(color: const Color(0xFF7B8FFF).withOpacity(0.08), blurRadius: 20),
    ],
  ),
  child: role == null
      ? const Center(child: Text("暂无聊天记录", style: TextStyle(fontSize: 11, color: Colors.white24)))
      : Row(
          children: [
            role.avatar.isEmpty
                ? Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white24),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      base64Decode(role.avatar),
                      width: 36, height: 36,
                      fit: BoxFit.cover,
                    ),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(role.name, style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    role.lastMessage.isEmpty ? "还没有消息..." : role.lastMessage,
                    style: const TextStyle(fontSize: 10, color: Colors.white38),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() => _heroFlipped = false);
                Navigator.push(context, ElasticPageRoute(page: const ChatPage()));
              },
              child: const Icon(Icons.chevron_right, size: 16, color: Colors.white24),
            ),
          ],
        ),
);
  Widget _ind() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      2,
      (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _curP == i ? 18 : 6,
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: _curP == i ? Colors.white70 : Colors.white12,
        ),
      ),
    ),
  );
  Widget _page(List<String> ns) {
    final Map<String, IconData> im = {
      "星语": Icons.auto_awesome,
      "星历": Icons.edit_note_rounded,
      "星云": Icons.filter_tilt_shift_rounded,
      "星轨": Icons.track_changes_rounded,
      "核心舱": Icons.rocket,
      "货舱": Icons.inventory_2_outlined,
      "星籍": Icons.auto_awesome,
      "双星轨道": Icons.join_inner_rounded,
      "月相": Icons.dark_mode,
    };
    return Column(
      children: [
        if (_curP == 0) ...[
          const SizedBox(height: 8),
          _card(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final file = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (file != null) {
                        final bytes = await file.readAsBytes();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString(
                          'widget_image',
                          base64Encode(bytes),
                        );
                        setState(() => _widgetImage = base64Encode(bytes));
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child:
                          _widgetImage != null
                              ? Container(
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  image: DecorationImage(
                                    image: MemoryImage(
                                      base64Decode(_widgetImage!),
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                              : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  border: Border(
                                    left: BorderSide(
                                      color: const Color(
                                        0xFF7B8FFF,
                                      ).withOpacity(0.6),
                                      width: 2,
                                    ),
                                    top: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.06,
                                      ),
                                    ),
                                    right: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.06,
                                      ),
                                    ),
                                    bottom: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.06,
                                      ),
                                    ),
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 20,
                                      color: Colors.white24,
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      "点击上传图片",
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.white24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        border: Border(
                          left: BorderSide(
                            color: const Color(0xFF7FFFD4).withOpacity(0.6),
                            width: 2,
                          ),
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                          right: BorderSide(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "今日月相",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white38,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              FlatMoonIcon(size: 16),
                              SizedBox(width: 8),
                              Text(
                                "月相",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ] else ...[
          const SizedBox(height: 14),
        ],
        Expanded(
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children:
                ns
                    .map(
                      (n) => AnimatedScaleButton(
                        onPressed: () {
                          Future.delayed(const Duration(milliseconds: 150), () {
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                ElasticPageRoute(
                                  page: Builder(
                                    builder: (c) {
                                      if (n == "星语") return const ChatPage();
                                      if (n == "星历")
                                        return const StarDiaryPage();
                                      if (n == "核心舱")
                                        return const CoreCabinPage();
                                      if (n == "星轨")
                                        return const StarTrackPage();
                                      if (n == "月相")
                                        return const MoonPhasePage();
                                      return AppShellPage(title: n);
                                    },
                                  ),
                                ),
                              );
                            }
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A2E).withOpacity(0.6),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                  width: 0.8,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.04),
                                    blurRadius: 12,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.04),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Icon(
                                im[n] ?? Icons.apps,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              n,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }

  Widget _dock(double cw) => Positioned(
    bottom: 25,
    left: 0,
    right: 0,
    child: Center(
      child: SizedBox(
        width: cw - 40,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 悬浮星星暂时隐藏
            const SizedBox(height: 12),
            // Dock栏
            _WaveDock(
              items: [
                _DockItem(
                  icon: Icons.settings,
                  onTap:
                      () => Navigator.push(
                        context,
                        ElasticPageRoute(page: const CoreCabinPage()),
                      ),
                ),
                _DockItem(
                  icon: Icons.chat_bubble_outline,
                  onTap:
                      () => Navigator.push(
                        context,
                        ElasticPageRoute(page: const ChatPage()),
                      ),
                ),
                _DockItem(
                  icon: Icons.public,
                  onTap:
                      () => Navigator.push(
                        context,
                        ElasticPageRoute(page: const WorldBookPage()),
                      ),
                ),
                _DockItem(
                  icon: Icons.badge_outlined,
                  onTap:
                      () => Navigator.push(
                        context,
                        ElasticPageRoute(page: const StarProfilePage()),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _StarWidget extends StatefulWidget {
  const _StarWidget();
  @override
  State<_StarWidget> createState() => _StarWidgetState();
}

class _StarWidgetState extends State<_StarWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;
  late AnimationController _tapCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _tapAnim;
  bool _tapped = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnim = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _tapAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _tapCtrl.dispose();
    super.dispose();
  }

  void _onTap() {
    setState(() => _tapped = !_tapped);
    _tapCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseCtrl, _rotateCtrl, _tapCtrl]),
        builder: (ctx, child) {
          return Transform.scale(
            scale: _pulseAnim.value + (_tapAnim.value * 0.3),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 光晕
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(
                          0.08 + _tapAnim.value * 0.1,
                        ),
                        blurRadius: 10 + _tapAnim.value * 10,
                        spreadRadius: 1 + _tapAnim.value * 3,
                      ),
                    ],
                  ),
                ),
                // 旋转外圈
                Transform.rotate(
                  angle: _rotateCtrl.value * 2 * pi,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 28,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                // 中心星星
                Icon(
                  _tapped ? Icons.star : Icons.auto_awesome,
                  size: 26,
                  color:
                      _tapped
                          ? Colors.cyanAccent
                          : Colors.white.withOpacity(0.8),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ElasticPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  ElasticPageRoute({required this.page})
    : super(
        pageBuilder: (ctx, anim, secondAnim) => page,
        transitionsBuilder: (ctx, anim, secondAnim, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: FadeTransition(
              opacity: Tween<double>(
                begin: 0.5,
                end: 1.0,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      );
}

class _DockItem {
  final IconData icon;
  final VoidCallback onTap;
  _DockItem({required this.icon, required this.onTap});
}

class _WaveDock extends StatefulWidget {
  final List<_DockItem> items;
  const _WaveDock({required this.items});
  @override
  State<_WaveDock> createState() => _WaveDockState();
}

class _WaveDockState extends State<_WaveDock> {
  int? _pressedIndex;

  double _getScale(int index) {
    if (_pressedIndex == null) return 1.0;
    final distance = (index - _pressedIndex!).abs();
    if (distance == 0) return 1.3;
    if (distance == 1) return 1.1;
    if (distance == 2) return 1.05;
    return 1.0;
  }

  double _getOffset(int index) {
    if (_pressedIndex == null) return 0.0;
    final distance = (index - _pressedIndex!).abs();
    if (distance == 0) return -12.0;
    if (distance == 1) return -6.0;
    if (distance == 2) return -2.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(35),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                widget.items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return GestureDetector(
                    onTapDown: (_) => setState(() => _pressedIndex = i),
                    onTapUp: (_) {
                      item.onTap();
                      Future.delayed(const Duration(milliseconds: 400), () {
                        if (mounted) setState(() => _pressedIndex = null);
                      });
                    },
                    onTapCancel: () => setState(() => _pressedIndex = null),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _getOffset(i)),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      builder:
                          (ctx, offset, child) => Transform.translate(
                            offset: Offset(0, offset),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 1.0, end: _getScale(i)),
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.elasticOut,
                              builder:
                                  (ctx, scale, child) => Transform.scale(
                                    scale: scale,
                                    child: Icon(
                                      item.icon,
                                      size: 26,
                                      color: Colors.white,
                                    ),
                                  ),
                            ),
                          ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }
}

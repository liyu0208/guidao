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


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WebViewPlatform.instance ?? (WebViewPlatform.instance = AndroidWebViewPlatform());
  // 🔥 临时加这三行，清除旧的月经数据
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('menstrual_records');
  await prefs.remove('menstrual_settings');
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
    theme: ThemeData(brightness: Brightness.dark, fontFamily: 'sans-serif'),
    home: const VirtualDesktop(),
  );
}

class VirtualDesktop extends StatefulWidget {
  const VirtualDesktop({super.key});
  @override
  State<VirtualDesktop> createState() => _VDState();
}

class _VDState extends State<VirtualDesktop> {
  final _pC = PageController();
  final _bat = Battery();
  int _curP = 0;
  String _curT = "";
  int _batL = 100;
  late Timer _timer;
  @override
  void initState() {
    super.initState();
    _up();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => _up());
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
              child: SafeArea(
                child: Column(
                  children: [
                    _top(),
                    const SizedBox(height: 35),
                    _card(),
                    const SizedBox(height: 12),
                    _sign(),
                    const SizedBox(height: 35),
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
                    const SizedBox(height: 110),
                  ],
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
        const MoonPhaseIcon(),
        Text(
          _curT,
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
        Row(
          children: [
            const Icon(Icons.signal_cellular_alt, size: 14),
            const SizedBox(width: 5),
            Text("$_batL%", style: const TextStyle(fontSize: 13)),
          ],
        ),
      ],
    ),
  );
  Widget _card() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 25),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.015),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        ChatData.userAvatar.isEmpty
            ? Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 48,
                color: Colors.white24,
              ),
            )
            : CircleAvatar(
              radius: 24,
              backgroundImage: MemoryImage(base64Decode(ChatData.userAvatar)),
            ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ChatData.userName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ChatData.userSign,
                style: const TextStyle(fontSize: 10, color: Colors.white38),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _sign() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 25),
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.015),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      children: [
        const Icon(Icons.edit_outlined, size: 14, color: Colors.white24),
        const SizedBox(width: 8),
        Text(
          ChatData.userMood.isEmpty ? "编写心情..." : ChatData.userMood,
          style: TextStyle(
            fontSize: 11,
            color: ChatData.userMood.isEmpty ? Colors.white24 : Colors.white54,
          ),
        ),
      ],
    ),
  );
  Widget _ind() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      2,
      (i) => Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _curP == i ? Colors.white : Colors.white12,
        ),
      ),
    ),
  );
  Widget _page(List<String> ns) {
    // 1. 在这里把图标名字映射好
final Map<String, IconData> im = {
      "星语": Icons.auto_awesome,           
      "星历": Icons.edit_note_rounded,
      "星云": Icons.filter_tilt_shift_rounded,
      "星轨": Icons.track_changes_rounded,
      "核心舱": Icons.rocket,
      "货舱": Icons.inventory_2_outlined,
      "星籍": Icons.auto_awesome,           // 🌟 这里改为星星图标
      "双星轨道": Icons.join_inner_rounded,
      "月相": Icons.dark_mode,
    };

    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 25,
      childAspectRatio: 0.75,
      padding: const EdgeInsets.symmetric(horizontal: 35),
      children:
          ns
              .map(
  (n) => AnimatedScaleButton(
  onPressed: () {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (context.mounted) {
        Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (c) {
              if (n == "星语") return const ChatPage();
              if (n == "星历") return const StarDiaryPage();
              if (n == "核心舱") return const CoreCabinPage();
              if (n == "星轨") return const StarTrackPage();
              if (n == "月相") return const MoonPhasePage(); // 🌟 加这一行
              return AppShellPage(title: n); // 其他占位
            },
          ),
        );
      }
    });
  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.015),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        // 2. 🌟 极简逻辑：现在所有图标都直接从 im 字典里取，不用再单独判断“月相”了
                        child: Icon(
                          im[n] ?? Icons.apps,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        n,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _dock(double cw) => Positioned(
    bottom: 25,
    left: 0,
    right: 0,
    child: Center(
      child: SizedBox(
        width: cw - 40,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.015),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              AnimatedScaleButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => const CoreCabinPage()),
                    ),
                child: const Icon(Icons.settings, size: 26),
              ),
              const Icon(Icons.chat_bubble_outline, size: 26),
              AnimatedScaleButton(
                onPressed: () {
                  Future.delayed(const Duration(milliseconds: 150), () {
                    if (context.mounted) {
                      Navigator.push(
                        // ignore: use_build_context_synchronously
                        context,
                        MaterialPageRoute(
                          builder: (c) => const WorldBookPage(),
                        ),
                      );
                    }
                  });
                },
                child: const Icon(Icons.public, size: 26, color: Colors.white),
              ),
AnimatedScaleButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (c) => const StarProfilePage()),
  ),
  child: const Icon(Icons.badge_outlined, size: 26), // 🌟 换成了证件卡
),
            ],
          ),
        ),
      ),
    ),
  );
}

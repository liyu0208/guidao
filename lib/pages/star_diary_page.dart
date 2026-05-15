import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/visual_elements.dart';

// --- 星历 (日记APP) 主页面 ---
class StarDiaryPage extends StatefulWidget {
  const StarDiaryPage({super.key});

  @override
  State<StarDiaryPage> createState() => _StarDiaryPageState();
}

class _StarDiaryPageState extends State<StarDiaryPage> {
  int _tabIndex = 0;

  // 核心数据库：按日期 (YYYY-MM-DD) 存放日志列表
  // 结构: {"2023-10-05": {"weather": "☀️", "mood": "😊", "records": [ {time, text, image} ]} }
  final Map<String, Map<String, dynamic>> _logs = {};

  // 写日记的状态
  DateTime _selectedDate = DateTime.now();
  String _currentWeather = "☀️"; // 默认晴天
  String _currentMood = "平静"; // 默认心情
  final TextEditingController _textController = TextEditingController();
  List<String> _currentImages = []; // 当前选中的图片 base64

  // 天气和心情库 (点击可循环切换)
  final List<String> _weathers = ["☀️", "☁️", "🌧️", "❄️", "🌩️"];
  final List<String> _moods = ["平静", "开心", "低落", "愤怒", "灵感"];

  // 工具：格式化日期为 YYYY-MM-DD
  String _formatDate(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  // 工具：获取星期几
  String _getWeekday(DateTime date) {
    const days = ["一", "二", "三", "四", "五", "六", "日"];
    return "星期${days[date.weekday - 1]}";
  }

  // 交互：选择日期
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.cyanAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF0A192F),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // 交互：选择图片
  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (x != null) {
      final bytes = await x.readAsBytes();
      setState(() => _currentImages.add(base64Encode(bytes)));
    }
  }

  // 逻辑：保存/追加 日志
  void _saveLog({DateTime? targetDate, String? text, List<String>? images}) {
    final dateKey = _formatDate(targetDate ?? _selectedDate);
    final contentText = text ?? _textController.text.trim();
    final contentImages = images ?? List.from(_currentImages);

    if (contentText.isEmpty && contentImages.isEmpty) return;

    setState(() {
      // 如果这一天还没写过，初始化一天的数据
      if (!_logs.containsKey(dateKey)) {
        _logs[dateKey] = {
          "weather": _currentWeather,
          "mood": _currentMood,
          "records": <Map<String, dynamic>>[],
        };
      }
      // 追加一条新记录
      (_logs[dateKey]!["records"] as List).add({
        "time":
            "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
        "text": contentText,
        "images": contentImages,
      });

      // 清空当前输入框
      if (text == null) {
        _textController.clear();
        _currentImages.clear();
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.cyanAccent.withOpacity(0.2),
            content: const Text(
              "✔️ 星历已记录至矩阵",
              style: TextStyle(color: Colors.cyanAccent),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white70,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "STAR LOG // 星历",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            letterSpacing: 2,
            fontFamily: 'monospace',
          ),
        ),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [_buildWriteTab(), _buildCalendarTab(), _buildInfoTab()],
      ),
      bottomNavigationBar: _buildTabBar(),
    );
  }

  // ===================== 底部导航栏 =====================
  Widget _buildTabBar() {
    return Container(
      height: 70,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xE6000B18),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            alignment: Alignment(-0.82 + (_tabIndex * 0.82), 0),
            child: FractionallySizedBox(
              widthFactor: 0.28,
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(21),
                ),
              ),
            ),
          ),
          Row(
            children: List.generate(3, (i) {
              final icons = [
                Icons.edit_note,
                Icons.calendar_month_outlined,
                Icons.memory,
              ];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _tabIndex = i),
                  child: Icon(
                    icons[i],
                    size: 24,
                    color: _tabIndex == i ? Colors.cyanAccent : Colors.white30,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ===================== Tab 1: 编写星历 =====================
  Widget _buildWriteTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部信息控制栏
          Row(
            children: [
              // 1. 点击改日期
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${_formatDate(_selectedDate)}  ${_getWeekday(_selectedDate)}",
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // 2. 点击换天气
              GestureDetector(
                onTap:
                    () => setState(
                      () =>
                          _currentWeather =
                              _weathers[(_weathers.indexOf(_currentWeather) +
                                      1) %
                                  _weathers.length],
                    ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _currentWeather,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 3. 点击换心情
              GestureDetector(
                onTap:
                    () => setState(
                      () =>
                          _currentMood =
                              _moods[(_moods.indexOf(_currentMood) + 1) %
                                  _moods.length],
                    ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    _currentMood,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // 输入框主体
          Expanded(
            child: CyberGlassContainer(
              isMe: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.6,
                      ),
                      decoration: InputDecoration(
                        hintText: "记录今日星际坐标...\n(支持文字与图片)",
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.2),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  // 图片预览区
                  if (_currentImages.isNotEmpty)
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _currentImages.length,
                        itemBuilder:
                            (ctx, i) => Container(
                              margin: const EdgeInsets.only(right: 10, top: 10),
                              width: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: MemoryImage(
                                    base64Decode(_currentImages[i]),
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 底部工具栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: Colors.cyanAccent,
                ),
                onPressed: _pickImage, // 添加图片
              ),
              GestureDetector(
                onTap: _saveLog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.cyanAccent.withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Text(
                    "归档 (SAVE)",
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================== Tab 2: 矩阵日历 =====================
  Widget _buildCalendarTab() {
    int daysInMonth = DateUtils.getDaysInMonth(
      DateTime.now().year,
      DateTime.now().month,
    );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "// TIME MATRIX  ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}",
            style: const TextStyle(
              color: Colors.white54,
              fontFamily: 'monospace',
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: daysInMonth,
              itemBuilder: (context, index) {
                int day = index + 1;
                String dateKey =
                    "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
                bool hasLog = _logs.containsKey(dateKey);

                // 寻找当天的第一张图片作为封面
                String? coverImg;
                if (hasLog) {
                  for (var record in _logs[dateKey]!['records']) {
                    if ((record['images'] as List).isNotEmpty) {
                      coverImg = record['images'][0];
                      break;
                    }
                  }
                }

                return GestureDetector(
                  onTap: () => _showDayDetailDialog(dateKey), // 点击打开详情/追加
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          hasLog
                              ? Colors.cyanAccent.withOpacity(0.1)
                              : Colors.white.withOpacity(0.02),
                      border: Border.all(
                        color:
                            hasLog
                                ? Colors.cyanAccent.withOpacity(0.5)
                                : Colors.white.withOpacity(0.05),
                        width: hasLog ? 1.5 : 0.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      // 如果有图，用图片做底色，并加一层黑色遮罩保证数字可见
                      image:
                          coverImg != null
                              ? DecorationImage(
                                image: MemoryImage(base64Decode(coverImg)),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.4),
                                  BlendMode.darken,
                                ),
                              )
                              : null,
                    ),
                    child: Center(
                      child: Text(
                        day.toString().padLeft(2, '0'),
                        style: TextStyle(
                          color: hasLog ? Colors.white : Colors.white30,
                          fontFamily: 'monospace',
                          fontWeight:
                              hasLog ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 点击日历弹出的“追加与查看”面板
  void _showDayDetailDialog(String dateKey) {
    if (!_logs.containsKey(dateKey)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("该日无归档记录", style: TextStyle(color: Colors.white30)),
        ),
      );
      return;
    }

    final dayData = _logs[dateKey]!;
    final records = dayData["records"] as List;
    final appendController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (ctx) => StatefulBuilder(
            builder: (sheetCtx, sheetSetState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A192F),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(25),
                  ),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DATE: $dateKey",
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontFamily: 'monospace',
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      "WEATHER: ${dayData['weather']}  MOOD: ${dayData['mood']}",
                      style: const TextStyle(color: Colors.white54),
                    ),
                    const Divider(color: Colors.white10, height: 30),

                    // 历史记录列表
                    Expanded(
                      child: ListView.builder(
                        itemCount: records.length,
                        itemBuilder:
                            (c, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    records[i]['time'],
                                    style: const TextStyle(
                                      color: Colors.white30,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (records[i]['text']
                                            .toString()
                                            .isNotEmpty)
                                          Text(
                                            records[i]['text'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        if ((records[i]['images'] as List)
                                            .isNotEmpty)
                                          Wrap(
                                            spacing: 8,
                                            children:
                                                (records[i]['images'] as List)
                                                    .map(
                                                      (img) => Container(
                                                        margin:
                                                            const EdgeInsets.only(
                                                              top: 8,
                                                            ),
                                                        width: 80,
                                                        height: 80,
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          image: DecorationImage(
                                                            image: MemoryImage(
                                                              base64Decode(img),
                                                            ),
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ),
                    ),

                    // 追加输入区
                    Container(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(ctx).viewInsets.bottom,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: CyberGlassContainer(
                              isMe: false,
                              child: TextField(
                                controller: appendController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: "追加航行日志...",
                                  hintStyle: TextStyle(color: Colors.white24),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Colors.cyanAccent,
                            ),
                            onPressed: () {
                              if (appendController.text.trim().isEmpty) return;
                              _saveLog(
                                targetDate: DateTime.parse(dateKey),
                                text: appendController.text.trim(),
                                images: [],
                              );
                              sheetSetState(() {}); // 刷新当前弹窗
                              setState(() {}); // 刷新后面日历
                              appendController.clear();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  // ===================== Tab 3: 基础信息 =====================
  Widget _buildInfoTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.fingerprint, size: 60, color: Colors.cyanAccent),
          const SizedBox(height: 15),
          const Text(
            "USER_ID: STAR_TRAVELER",
            style: TextStyle(color: Colors.white, letterSpacing: 2),
          ),
          const SizedBox(height: 40),

          Row(
            children: [
              _infoCard(
                "归档总数",
                "${_logs.length} 篇",
                Icons.inventory_2_outlined,
              ),
              const SizedBox(width: 15),
              _infoCard("运行状态", "ACTIVE", Icons.rocket_launch_outlined),
            ],
          ),

          const SizedBox(height: 15),
          CyberGlassContainer(
            isMe: false,
            child: const ListTile(
              leading: Icon(Icons.security, color: Colors.white54),
              title: Text("生物识别加密", style: TextStyle(color: Colors.white)),
              trailing: Icon(
                Icons.toggle_on,
                color: Colors.cyanAccent,
                size: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Expanded(
      child: CyberGlassContainer(
        isMe: false,
        child: Column(
          children: [
            Icon(icon, color: Colors.cyanAccent, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

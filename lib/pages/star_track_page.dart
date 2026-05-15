import 'package:flutter/material.dart';
import '../models/habit_data.dart';
import '../widgets/visual_elements.dart';
import 'package:intl/intl.dart';

class StarTrackPage extends StatefulWidget {
  const StarTrackPage({super.key});
  @override
  State<StarTrackPage> createState() => _StarTrackPageState();
}

class _StarTrackPageState extends State<StarTrackPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabC;
  DateTime _viewDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabC = TabController(length: 3, vsync: this);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return FloatingHudFrame(
      title: "星轨航线",
      child: Column(
        children: [
          TabBar(
            controller: _tabC,
            indicatorColor: Colors.blueAccent,
            tabs: const [Tab(text: "每日打卡"), Tab(text: "习惯舱"), Tab(text: "星轨图")],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabC,
              children: [
                _buildCalendarTab(),
                _buildHabitListTab(),
                _buildStarMapTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Tab 1: 每日打卡 (日历视图) ---
  Widget _buildCalendarTab() {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        Text(
          DateFormat('yyyy年MM月').format(_viewDate),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        // 这里简化实现一个 7列网格日历
        _buildCalendarGrid(),
        const SizedBox(height: 20),
        const Text(
          "今日任务",
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        ...HabitManager.habits.map(
          (h) => ListTile(
            leading: Icon(h.icon, color: h.color),
            title: Text(h.name),
            trailing: Checkbox(
              value: h.checkInDates.contains(today),
              onChanged: (v) {
                setState(() => HabitManager.toggleCheckIn(h.id, today));
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    // 简易日历逻辑：显示所有习惯的彩色点
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
        ),
        itemCount: 31, // 简化固定 31 天
        itemBuilder: (context, index) {
          int day = index + 1;
          String dateStr =
              "${_viewDate.year}-${_viewDate.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";

          // 找出这一天打卡的所有习惯颜色
          List<Color> dots =
              HabitManager.habits
                  .where((h) => h.checkInDates.contains(dateStr))
                  .map((h) => h.color)
                  .toList();

          return Column(
            children: [
              Text("$day", style: const TextStyle(fontSize: 12)),
              Wrap(
                children:
                    dots
                        .take(3)
                        .map(
                          (c) => Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c,
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Tab 2: 习惯管理 ---
  Widget _buildHabitListTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHabitDlg,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
      body:
          HabitManager.habits.isEmpty
              ? const Center(
                child: Text(
                  "还没有航线，点击 + 开启你的星轨",
                  style: TextStyle(color: Colors.white38),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: HabitManager.habits.length,
                itemBuilder: (c, i) => _habitCard(HabitManager.habits[i]),
              ),
    );
  }

  Widget _habitCard(Habit h) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: h.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: h.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(h.icon, color: h.color),
          const SizedBox(width: 15),
          Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(
            "${h.checkInDates.length} 天",
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  // --- Tab 3: 星轨图 (示意) ---
  Widget _buildStarMapTab() {
    return const Center(
      child: Icon(
        Icons.auto_awesome_motion_rounded,
        size: 80,
        color: Colors.white12,
      ),
    );
  }

  void _showAddHabitDlg() {
    // 弹窗添加习惯逻辑（简化版）
    final c = TextEditingController();
    showDialog(
      context: context,
      builder:
          (ctx) => StarThemedDialog(
            title: "开启新航线",
            content: TextField(
              controller: c,
              decoration: const InputDecoration(hintText: "习惯名称，如：多喝水"),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  HabitManager.habits.add(
                    Habit(
                      id: DateTime.now().toString(),
                      name: c.text,
                      icon: Icons.water_drop_rounded, // 默认图标
                      color: Colors.blueAccent, // 默认颜色
                    ),
                  );
                  HabitManager.save();
                  _refresh();
                  Navigator.pop(ctx);
                },
                child: const Text("建立"),
              ),
            ],
          ),
    );
  }
}

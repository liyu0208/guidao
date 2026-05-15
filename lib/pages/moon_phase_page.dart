import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../providers/menstrual_provider.dart';
import '../models/menstrual_data.dart';
import '../utils/moon_calculator.dart';
import '../widgets/moon_phase_widget.dart';
import 'dart:ui' as ui;

class MoonPhasePage extends StatefulWidget {
  const MoonPhasePage({super.key});

  @override
  State<MoonPhasePage> createState() => _MoonPhasePageState();
}

class _MoonPhasePageState extends State<MoonPhasePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('zh_CN', null);
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MenstrualProvider()..loadData(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: Column(
          children: [
            SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white54,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFFD4A8E1),
                      labelColor: const Color(0xFFD4A8E1),
                      unselectedLabelColor: Colors.white38,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: const [
                        Tab(text: '当下'),
                        Tab(text: '预测'),
                        Tab(text: '日志'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [_HomeTab(), _PredictionTab(), _JournalTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════
//  TAB 1：当下
// ════════════════════════════════════════
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  bool _periodStarted = false;
  int _dysmenorrhea = 0;
  String _mood = '';
  String _discharge = '';
  int _bloodFlow = 0;

  final List<String> _moods = [
    '😊 愉悦',
    '😐 平静',
    '😢 低落',
    '😤 烦躁',
    '😴 疲倦',
    '🌸 温柔',
  ];
  final List<String> _discharges = ['无', '白色', '透明拉丝', '黄色', '褐色'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadToday());
  }

  void _loadToday() {
    final provider = context.read<MenstrualProvider>();
    final record = provider.getRecordForDate(DateTime.now());
    if (record != null && mounted) {
      setState(() {
        _periodStarted = record.periodStarted;
        _dysmenorrhea = record.dysmenorrhea;
        _mood = record.mood;
        _discharge = record.discharge;
        _bloodFlow = record.bloodFlow;
      });
    }
  }

  Future<void> _save() async {
    final provider = context.read<MenstrualProvider>();
    await provider.saveRecord(
      MenstrualRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        periodStarted: _periodStarted,
        dysmenorrhea: _dysmenorrhea,
        mood: _mood,
        discharge: _discharge,
        bloodFlow: _bloodFlow,
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('已记录 ✨'),
          backgroundColor: const Color(0xFF9B6FA8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final phase = MoonCalculator.getMoonPhase(today);
    final illumination = MoonCalculator.getMoonIllumination(today);

    return CustomScrollView(
      slivers: [
        // 月相展示区
        SliverToBoxAdapter(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.45,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.2,
                colors: [const Color(0xFF2A1A3E), const Color(0xFF0D0D1A)],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MoonPhaseWidget(
                  phase: phase,
                  illumination: illumination as double,
                  size: 130,
                ),
                const SizedBox(height: 16),
                Text(
                  phase.chineseName,
                  style: const TextStyle(
                    color: Color(0xFFD4A8E1),
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    phase.bodyState,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 照明度
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '月亮照明度',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '${(illumination * 100).round()}%',
                            style: const TextStyle(
                              color: Color(0xFFD4A8E1),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: illumination,
                          backgroundColor: Colors.white.withOpacity(0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFD4A8E1),
                          ),
                          minHeight: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 快速记录
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '今日记录',
                  style: TextStyle(
                    color: Color(0xFFD4A8E1),
                    fontSize: 15,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 14),
                _toggleCard(),
                const SizedBox(height: 10),
                _sliderCard(
                  icon: '💧',
                  title: '经血量',
                  value: _bloodFlow.toDouble(),
                  labels: ['无', '少', '正常', '偏多', '多', '很多'],
                  color: const Color(0xFFE8A0BF),
                  onChanged: (v) => setState(() => _bloodFlow = v.toInt()),
                ),
                const SizedBox(height: 10),
                _sliderCard(
                  icon: '🌀',
                  title: '痛经程度',
                  value: _dysmenorrhea.toDouble(),
                  labels: ['无', '轻微', '可忍受', '明显', '强烈', '剧烈'],
                  color: const Color(0xFFA78BFA),
                  onChanged: (v) => setState(() => _dysmenorrhea = v.toInt()),
                ),
                const SizedBox(height: 10),
                _chipCard(
                  icon: '✨',
                  title: '情绪',
                  options: _moods,
                  selected: _mood,
                  onSelect: (v) => setState(() => _mood = v),
                ),
                const SizedBox(height: 10),
                _chipCard(
                  icon: '🌿',
                  title: '分泌物',
                  options: _discharges,
                  selected: _discharge,
                  onSelect: (v) => setState(() => _discharge = v),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B3FA0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '保存今日记录',
                      style: TextStyle(fontSize: 14, letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _toggleCard() => GestureDetector(
    onTap: () => setState(() => _periodStarted = !_periodStarted),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            _periodStarted
                ? const Color(0xFF6B3FA0).withOpacity(0.25)
                : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              _periodStarted
                  ? const Color(0xFFD4A8E1).withOpacity(0.5)
                  : Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        children: [
          const Text('🌸', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '经期开始',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                Text(
                  _periodStarted ? '今天标记为经期第一天' : '点击标记经期开始',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            _periodStarted ? Icons.check_circle : Icons.radio_button_unchecked,
            color:
                _periodStarted
                    ? const Color(0xFFD4A8E1)
                    : Colors.white.withOpacity(0.25),
            size: 20,
          ),
        ],
      ),
    ),
  );

  Widget _sliderCard({
    required String icon,
    required String title,
    required double value,
    required List<String> labels,
    required Color color,
    required ValueChanged<double> onChanged,
  }) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.07)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            const Spacer(),
            Text(
              labels[value.round()],
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: color,
            inactiveTrackColor: Colors.white.withOpacity(0.08),
            thumbColor: color,
            overlayColor: color.withOpacity(0.15),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 5,
            divisions: 5,
            onChanged: onChanged,
          ),
        ),
      ],
    ),
  );

  Widget _chipCard({
    required String icon,
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.07)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children:
              options.map((opt) {
                final sel = selected == opt;
                return GestureDetector(
                  onTap: () => onSelect(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          sel
                              ? const Color(0xFF6B3FA0).withOpacity(0.35)
                              : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color:
                            sel ? const Color(0xFFD4A8E1) : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(
                        color:
                            sel
                                ? const Color(0xFFD4A8E1)
                                : Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    ),
  );
}

// ════════════════════════════════════════
//  TAB 2：预测
// ════════════════════════════════════════
class _PredictionTab extends StatefulWidget {
  const _PredictionTab();

  @override
  State<_PredictionTab> createState() => _PredictionTabState();
}

class _PredictionTabState extends State<_PredictionTab> {
  late TextEditingController _cycleCtrl;
  late TextEditingController _periodCtrl;

  @override
  void initState() {
    super.initState();
    final s = context.read<MenstrualProvider>().cycleSettings;
    _cycleCtrl = TextEditingController(text: s.cycleDays.toString());
    _periodCtrl = TextEditingController(text: s.periodDays.toString());
  }

  @override
  void dispose() {
    _cycleCtrl.dispose();
    _periodCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    await context.read<MenstrualProvider>().updateSettings(
      CycleSettings(
        cycleDays: int.tryParse(_cycleCtrl.text) ?? 28,
        periodDays: int.tryParse(_periodCtrl.text) ?? 5,
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('周期设置已更新 🌙'),
          backgroundColor: const Color(0xFF9B6FA8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MenstrualProvider>(
      builder: (ctx, provider, _) {
        final pred = MoonCalculator.predictCycle(
          periodStartDates: provider.periodStartDates,
          settings: provider.cycleSettings,
        );
        final daysLeft = pred.nextPeriodStart.difference(DateTime.now()).inDays;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '智能预测',
                style: TextStyle(
                  color: Color(0xFFD4A8E1),
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              if (provider.periodStartDates.length >= 2)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '基于 ${provider.periodStartDates.length} 次记录推算，实际周期约 ${pred.calculatedCycleDays} 天',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // 倒计时卡片
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2A1A3E), Color(0xFF1A1030)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFD4A8E1).withOpacity(0.18),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '下次经期',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      daysLeft < 0
                          ? '已延迟 ${-daysLeft} 天'
                          : daysLeft == 0
                          ? '今天'
                          : '$daysLeft 天后',
                      style: const TextStyle(
                        color: Color(0xFFD4A8E1),
                        fontSize: 38,
                        fontWeight: FontWeight.w200,
                      ),
                    ),
                    Text(
                      DateFormat('M月d日').format(pred.nextPeriodStart),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 排卵日
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2A2A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF7ECEC4).withOpacity(0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🌕', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '预测排卵日',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          Text(
                            DateFormat('M月d日').format(pred.ovulationDay),
                            style: const TextStyle(
                              color: Color(0xFF7ECEC4),
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '易孕期',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          '${DateFormat('M.d').format(pred.fertileStart)}-${DateFormat('M.d').format(pred.fertileEnd)}',
                          style: const TextStyle(
                            color: Color(0xFF7ECEC4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 周期阶段
              Text(
                '周期阶段',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              _phaseRow(
                '🌑',
                '经期',
                pred.lastPeriodStart,
                pred.lastPeriodStart.add(
                  Duration(days: provider.cycleSettings.periodDays - 1),
                ),
                '蛰伏与更新',
                const Color(0xFFE8A0BF),
              ),
              _phaseRow(
                '🌒',
                '卵泡期',
                pred.follicularPhaseStart,
                pred.follicularPhaseEnd,
                '能量萌发，充满活力',
                const Color(0xFFA78BFA),
              ),
              _phaseRow(
                '🌕',
                '排卵期',
                pred.fertileStart,
                pred.fertileEnd,
                '巅峰能量，对外开放',
                const Color(0xFF7ECEC4),
              ),
              _phaseRow(
                '🌘',
                '黄体期',
                pred.lutealPhaseStart,
                pred.lutealPhaseEnd,
                '内省沉淀，准备更新',
                const Color(0xFFD4A8E1),
              ),
              const SizedBox(height: 20),

              // 设置
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '我的周期设置',
                      style: TextStyle(
                        color: Color(0xFFD4A8E1),
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '填入大致周期，系统会结合记录智能调整',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _numField('周期天数', _cycleCtrl)),
                        const SizedBox(width: 12),
                        Expanded(child: _numField('经期天数', _periodCtrl)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _saveSettings,
                        style: OutlinedButton.styleFrom(
                          // ← 正确拼写
                          foregroundColor: const Color(0xFFD4A8E1),
                          side: const BorderSide(
                            color: Color(0xFFD4A8E1),
                            width: 0.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        child: const Text('更新设置'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _phaseRow(
    String icon,
    String name,
    DateTime start,
    DateTime end,
    String desc,
    Color color,
  ) {
    final now = DateTime.now();
    final isActive = !now.isBefore(start) && !now.isAfter(end);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isActive ? color.withOpacity(0.12) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: isActive ? color.withOpacity(0.4) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isActive ? color : Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '当前',
                          style: TextStyle(color: color, fontSize: 9),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${DateFormat('M.d').format(start)}-${DateFormat('M.d').format(end)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _numField(String label, TextEditingController ctrl) => TextField(
    controller: ctrl,
    keyboardType: TextInputType.number,
    style: const TextStyle(color: Colors.white, fontSize: 15),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      suffixText: '天',
      suffixStyle: TextStyle(
        color: Colors.white.withOpacity(0.35),
        fontSize: 12,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    ),
  );
}

// ════════════════════════════════════════
//  TAB 3：日志
// ════════════════════════════════════════
class _JournalTab extends StatefulWidget {
  const _JournalTab();

  @override
  State<_JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<_JournalTab> {
  MenstrualRecord? _selected;
  final List<String> _keywords = [
    '蛰伏',
    '绽放',
    '消退',
    '新生',
    '流动',
    '静默',
    '涌动',
    '释放',
  ];
  List<String> _pickedKeywords = [];
  String _noteText = '';
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MenstrualProvider>(
      builder: (ctx, provider, _) {
        return Column(
          children: [
            // 月亮圆环
            SizedBox(
              height: 220,
              child: GestureDetector(
                onTapDown:
                    (d) => _handleRingTap(
                      d.localPosition,
                      provider.records,
                      context,
                    ),
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, 220),
                  painter: _MoonRingPainter(
                    records: provider.records,
                    selected: _selected,
                  ),
                ),
              ),
            ),

            // 详情或写随感
            Expanded(
              child:
                  _selected != null
                      ? _recordDetail(provider)
                      : _writeNote(provider),
            ),
          ],
        );
      },
    );
  }

  void _handleRingTap(
    Offset pos,
    List<MenstrualRecord> records,
    BuildContext context,
  ) {
    final w = MediaQuery.of(context).size.width;
    const cx = 0.0; // 用相对
    final centerX = w / 2;
    const centerY = 110.0;
    const radius = 80.0;

    for (final r in records) {
      final idx = records.indexOf(r);
      final angle = (idx / records.length) * 2 * pi - pi / 2;
      final x = centerX + radius * cos(angle);
      final y = centerY + radius * sin(angle);
      if ((pos - Offset(x, y)).distance < 18) {
        setState(() => _selected = _selected?.id == r.id ? null : r);
        return;
      }
    }
    setState(() => _selected = null);
    // 忽略 cx 未使用警告
    // ignore: unused_local_variable
    final _ = cx;
  }

  Widget _recordDetail(MenstrualProvider provider) {
    final r = _selected!;
    final phase = MoonCalculator.getMoonPhase(r.date);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(phase.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('M月d日 EEEE', 'zh_CN').format(r.date),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  Text(
                    phase.chineseName,
                    style: const TextStyle(
                      color: Color(0xFFD4A8E1),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _selected = null),
                child: Text(
                  '关闭',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (r.periodStarted) _tag('🌸 经期开始', const Color(0xFFE8A0BF)),
          const SizedBox(height: 6),
          if (r.bloodFlow > 0)
            _row('经血量', List.filled(r.bloodFlow, '🩸').join()),
          if (r.dysmenorrhea > 0)
            _row('痛经', List.filled(r.dysmenorrhea, '💫').join()),
          if (r.mood.isNotEmpty) _row('情绪', r.mood),
          if (r.discharge.isNotEmpty) _row('分泌物', r.discharge),
          if (r.keywords.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children:
                  r.keywords
                      .map((k) => _tag(k, const Color(0xFF6B3FA0)))
                      .toList(),
            ),
          ],
          if (r.note != null && r.note!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                r.note!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _writeNote(MenstrualProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '写随感',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '点击圆环节点查看历史，或写下今天的感受',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children:
                _keywords.map((k) {
                  final sel = _pickedKeywords.contains(k);
                  return GestureDetector(
                    onTap:
                        () => setState(() {
                          if (sel) {
                            _pickedKeywords.remove(k);
                          } else {
                            _pickedKeywords.add(k);
                          }
                        }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            sel
                                ? const Color(0xFF6B3FA0).withOpacity(0.35)
                                : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color:
                              sel
                                  ? const Color(0xFFD4A8E1)
                                  : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        k,
                        style: TextStyle(
                          color:
                              sel
                                  ? const Color(0xFFD4A8E1)
                                  : Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _noteCtrl,
            maxLines: 4,
            onChanged: (v) => _noteText = v,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: '此刻的感受、身体的低语……',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 12,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final existing = provider.getRecordForDate(DateTime.now());
                await provider.saveRecord(
                  MenstrualRecord(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    date: DateTime.now(),
                    periodStarted: existing?.periodStarted ?? false,
                    dysmenorrhea: existing?.dysmenorrhea ?? 0,
                    mood: existing?.mood ?? '',
                    discharge: existing?.discharge ?? '',
                    bloodFlow: existing?.bloodFlow ?? 0,
                    note: _noteText,
                    keywords: List.from(_pickedKeywords),
                  ),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('随感已保存 🌙'),
                      backgroundColor: const Color(0xFF9B6FA8),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  setState(() {
                    _pickedKeywords = [];
                    _noteText = '';
                    _noteCtrl.clear();
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B3FA0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('保存随感'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
        ),
        const SizedBox(width: 10),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    ),
  );

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.18),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: color.withOpacity(0.35)),
    ),
    child: Text(text, style: TextStyle(color: color, fontSize: 11)),
  );
}

// ════════════════════════════════════════
//  月亮圆环 Painter
// ════════════════════════════════════════
class _MoonRingPainter extends CustomPainter {
  final List<MenstrualRecord> records;
  final MenstrualRecord? selected;

  _MoonRingPainter({required this.records, this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const cy = 110.0;
    const radius = 80.0;

    // 轨道圆
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // 节点
    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      final angle = (i / records.length) * 2 * pi - pi / 2;
      final x = cx + radius * cos(angle);
      final y = cy + radius * sin(angle);
      final isSel = selected?.id == r.id;

      Color dot =
          r.periodStarted
              ? const Color(0xFFE8A0BF)
              : (r.note != null && r.note!.isNotEmpty)
              ? const Color(0xFFD4A8E1)
              : Colors.white.withOpacity(0.35);

      double sz = r.periodStarted ? 7 : 5;
      if (isSel) sz += 3;

      // 辉光
      if (isSel || r.periodStarted) {
        canvas.drawCircle(
          Offset(x, y),
          sz * 2,
          Paint()
            ..color = dot.withOpacity(0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      canvas.drawCircle(Offset(x, y), sz, Paint()..color = dot);

      // 选中时显示月相文字
      if (isSel) {
        final phase = MoonCalculator.getMoonPhase(r.date);
        final tp = TextPainter(
          text: TextSpan(
            text: phase.emoji,
            style: const TextStyle(fontSize: 13),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, y - sz - tp.height - 3));
      }
    }

    // 中心今日月相
    final todayPhase = MoonCalculator.getMoonPhase(DateTime.now());
    final tp = TextPainter(
      text: TextSpan(
        text: todayPhase.emoji,
        style: const TextStyle(fontSize: 36),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MoonRingPainter old) =>
      old.records != records || old.selected != selected;
}

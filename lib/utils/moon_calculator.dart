import '../models/menstrual_data.dart';

class MoonCalculator {
  /// 计算给定日期的天文月相（仅供参考）
  static MoonPhase getMoonPhase(DateTime date) {
    final baseNewMoon = DateTime(2000, 1, 6);
    final diff = date.difference(baseNewMoon).inDays;
    const synodicMonth = 29.53058867;
    final phase = (diff % synodicMonth) / synodicMonth;

    if (phase < 0.0625) return MoonPhase.newMoon;
    if (phase < 0.1875) return MoonPhase.waxingCrescent;
    if (phase < 0.3125) return MoonPhase.firstQuarter;
    if (phase < 0.4375) return MoonPhase.waxingGibbous;
    if (phase < 0.5625) return MoonPhase.fullMoon;
    if (phase < 0.6875) return MoonPhase.waningGibbous;
    if (phase < 0.8125) return MoonPhase.lastQuarter;
    if (phase < 0.9375) return MoonPhase.waningCrescent;
    return MoonPhase.newMoon;
  }

  /// 计算当天在周期中的位置，返回对应月相
  static CycleDayInfo calculateCycleDay({
    
    required DateTime today,
    required List<MenstrualRecord> records,
    required CycleSettings settings,
  }) {
    // 如果没有记录，显示新月
    if (records.isEmpty) {
      return CycleDayInfo(
        phase: MoonPhase.newMoon,
        illumination: 0.0,
        dayText: '点击下方开始记录',
        cycleDay: 0,
      );
    }

    // 找到最近的经期开始日
    final periodStarts = records
        .where((r) => r.periodStarted)
        .map((r) => r.date)
        .toList()
      ..sort();

    if (periodStarts.isEmpty) {
      return CycleDayInfo(
        phase: MoonPhase.newMoon,
        illumination: 0.0,
        dayText: '暂未标记经期开始',
        cycleDay: 0,
      );
    }

    // 计算实际周期天数
    int actualCycleDays = settings.cycleDays;
    if (periodStarts.length >= 2) {
      final intervals = <int>[];
      for (int i = 1; i < periodStarts.length; i++) {
        final d = periodStarts[i].difference(periodStarts[i - 1]).inDays;
        if (d > 15 && d < 60) intervals.add(d);
      }
      if (intervals.isNotEmpty) {
        actualCycleDays =
            (intervals.reduce((a, b) => a + b) / intervals.length).round();
      }
    }

    final lastPeriodStart = periodStarts.last;
    final daysSinceStart = today.difference(lastPeriodStart).inDays + 1;

    // 判断是否在经期内
    final inPeriod = daysSinceStart > 0 && daysSinceStart <= settings.periodDays;

    // 计算周期天数（循环）
    int cycleDay = daysSinceStart;
    if (cycleDay > actualCycleDays) {
      cycleDay = ((cycleDay - 1) % actualCycleDays) + 1;
    }

    // 根据周期天数映射月相
    final phase = _mapCycleDayToPhase(cycleDay, actualCycleDays);
    final illumination = _calculateIllumination(cycleDay, actualCycleDays);

    final dayText = inPeriod ? '经期第 $daysSinceStart 天' : '周期第 $cycleDay 天';

    return CycleDayInfo(
      phase: phase,
      illumination: illumination,
      dayText: dayText,
      cycleDay: cycleDay,
    );
  }

  /// 将周期天数映射到月相
  static MoonPhase _mapCycleDayToPhase(int cycleDay, int totalDays) {
    // 新月 = 第1天（经期开始）
    // 满月 = 排卵日（约第14天，或周期中点）
    final ovulationDay = totalDays - 14; // 排卵日通常在经期前14天

    if (cycleDay <= 1) return MoonPhase.newMoon;
    if (cycleDay <= (ovulationDay * 0.25).round()) return MoonPhase.waxingCrescent;
    if (cycleDay <= (ovulationDay * 0.5).round()) return MoonPhase.firstQuarter;
    if (cycleDay <= (ovulationDay * 0.9).round()) return MoonPhase.waxingGibbous;
    if (cycleDay <= ovulationDay + 2) return MoonPhase.fullMoon; // 排卵期
    if (cycleDay <= (totalDays * 0.65).round()) return MoonPhase.waningGibbous;
    if (cycleDay <= (totalDays * 0.8).round()) return MoonPhase.lastQuarter;
    return MoonPhase.waningCrescent;
  }

  /// 计算照明度（0.0 ~ 1.0）
  static double _calculateIllumination(int cycleDay, int totalDays) {
    final ovulationDay = totalDays - 14;
    if (cycleDay <= ovulationDay) {
      // 上半周期：0 -> 1
      return (cycleDay / ovulationDay).clamp(0.0, 1.0);
    } else {
      // 下半周期：1 -> 0
      final daysAfterOvulation = cycleDay - ovulationDay;
      final remainingDays = totalDays - ovulationDay;
      return (1 - (daysAfterOvulation / remainingDays)).clamp(0.0, 1.0);
    }
  }

  /// 智能预测周期
  static CyclePrediction predictCycle({
    required List<DateTime> periodStartDates,
    required CycleSettings settings,
  }) {
    int actualCycleDays = settings.cycleDays;

    if (periodStartDates.length >= 2) {
      final sorted = [...periodStartDates]..sort();
      final intervals = <int>[];
      for (int i = 1; i < sorted.length; i++) {
        final d = sorted[i].difference(sorted[i - 1]).inDays;
        if (d > 15 && d < 60) intervals.add(d);
      }
      if (intervals.isNotEmpty) {
        actualCycleDays =
            (intervals.reduce((a, b) => a + b) / intervals.length).round();
      }
    }

    final lastPeriod = periodStartDates.isEmpty
        ? DateTime.now().subtract(const Duration(days: 14))
        : (periodStartDates..sort()).last;

    final nextPeriodStart = lastPeriod.add(Duration(days: actualCycleDays));
    final ovulationDay = nextPeriodStart.subtract(const Duration(days: 14));
    final fertileStart = ovulationDay.subtract(const Duration(days: 5));
    final fertileEnd = ovulationDay.add(const Duration(days: 1));

    return CyclePrediction(
      lastPeriodStart: lastPeriod,
      nextPeriodStart: nextPeriodStart,
      ovulationDay: ovulationDay,
      fertileStart: fertileStart,
      fertileEnd: fertileEnd,
      follicularPhaseStart: lastPeriod.add(Duration(days: settings.periodDays)),
      follicularPhaseEnd: ovulationDay.subtract(const Duration(days: 1)),
      lutealPhaseStart: ovulationDay.add(const Duration(days: 1)),
      lutealPhaseEnd: nextPeriodStart.subtract(const Duration(days: 1)),
      calculatedCycleDays: actualCycleDays,
    );
  }

  static Object? getMoonIllumination(DateTime today) {}
}

/// 周期天数信息
class CycleDayInfo {
  final MoonPhase phase;
  final double illumination;  // ← 保持 double，不加问号
  final String dayText;
  final int cycleDay;

  CycleDayInfo({
    required this.phase,
    required this.illumination,
    required this.dayText,
    required this.cycleDay,
  });
}

/// 周期预测结果
class CyclePrediction {
  final DateTime lastPeriodStart;
  final DateTime nextPeriodStart;
  final DateTime ovulationDay;
  final DateTime fertileStart;
  final DateTime fertileEnd;
  final DateTime follicularPhaseStart;
  final DateTime follicularPhaseEnd;
  final DateTime lutealPhaseStart;
  final DateTime lutealPhaseEnd;
  final int calculatedCycleDays;

  CyclePrediction({
    required this.lastPeriodStart,
    required this.nextPeriodStart,
    required this.ovulationDay,
    required this.fertileStart,
    required this.fertileEnd,
    required this.follicularPhaseStart,
    required this.follicularPhaseEnd,
    required this.lutealPhaseStart,
    required this.lutealPhaseEnd,
    required this.calculatedCycleDays,
  });
}
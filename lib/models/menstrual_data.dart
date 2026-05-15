import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 月经记录单条数据
class MenstrualRecord {
  final String id;
  final DateTime date;
  final bool periodStarted;
  final int dysmenorrhea;   // 痛经 0-5
  final String mood;
  final String discharge;
  final int bloodFlow;       // 经血量 0-5
  final String? note;
  final List<String> keywords;

  MenstrualRecord({
    required this.id,
    required this.date,
    this.periodStarted = false,
    this.dysmenorrhea = 0,
    this.mood = '',
    this.discharge = '',
    this.bloodFlow = 0,
    this.note,
    this.keywords = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'periodStarted': periodStarted,
    'dysmenorrhea': dysmenorrhea,
    'mood': mood,
    'discharge': discharge,
    'bloodFlow': bloodFlow,
    'note': note,
    'keywords': keywords,
  };

  factory MenstrualRecord.fromJson(Map<String, dynamic> json) => MenstrualRecord(
    id: json['id'],
    date: DateTime.parse(json['date']),
    periodStarted: json['periodStarted'] ?? false,
    dysmenorrhea: json['dysmenorrhea'] ?? 0,
    mood: json['mood'] ?? '',
    discharge: json['discharge'] ?? '',
    bloodFlow: json['bloodFlow'] ?? 0,
    note: json['note'],
    keywords: List<String>.from(json['keywords'] ?? []),
  );
}

/// 用户周期设置
class CycleSettings {
  final int cycleDays;
  final int periodDays;

  CycleSettings({this.cycleDays = 28, this.periodDays = 5});

  Map<String, dynamic> toJson() => {
    'cycleDays': cycleDays,
    'periodDays': periodDays,
  };

  factory CycleSettings.fromJson(Map<String, dynamic> json) => CycleSettings(
    cycleDays: json['cycleDays'] ?? 28,
    periodDays: json['periodDays'] ?? 5,
  );
}

/// 月相枚举
enum MoonPhase {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  fullMoon,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

extension MoonPhaseExt on MoonPhase {
  String get chineseName {
    switch (this) {
      case MoonPhase.newMoon: return '新月';
      case MoonPhase.waxingCrescent: return '娥眉月';
      case MoonPhase.firstQuarter: return '上弦月';
      case MoonPhase.waxingGibbous: return '盈凸月';
      case MoonPhase.fullMoon: return '满月';
      case MoonPhase.waningGibbous: return '亏凸月';
      case MoonPhase.lastQuarter: return '下弦月';
      case MoonPhase.waningCrescent: return '残月';
    }
  }

  String get bodyState {
    switch (this) {
      case MoonPhase.newMoon: return '能量归零，适合休息与内观';
      case MoonPhase.waxingCrescent: return '能量萌发，设定新意图';
      case MoonPhase.firstQuarter: return '行动力上升，突破阻碍';
      case MoonPhase.waxingGibbous: return '精力充沛，完善计划';
      case MoonPhase.fullMoon: return '能量顶峰，情绪饱满';
      case MoonPhase.waningGibbous: return '收获感恩，整理思绪';
      case MoonPhase.lastQuarter: return '释放清理，放下不需要的';
      case MoonPhase.waningCrescent: return '深度蛰伏，聆听内心';
    }
  }

  String get emoji {
    switch (this) {
      case MoonPhase.newMoon: return '🌑';
      case MoonPhase.waxingCrescent: return '🌒';
      case MoonPhase.firstQuarter: return '🌓';
      case MoonPhase.waxingGibbous: return '🌔';
      case MoonPhase.fullMoon: return '🌕';
      case MoonPhase.waningGibbous: return '🌖';
      case MoonPhase.lastQuarter: return '🌗';
      case MoonPhase.waningCrescent: return '🌘';
    }
  }
}

/// 数据持久化（兼容你项目现有风格）
class MenstrualData {
  static List<MenstrualRecord> _records = [];
  static CycleSettings _settings = CycleSettings();

  static List<MenstrualRecord> get records => _records;
  static CycleSettings get settings => _settings;

  static Future<void> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('menstrual_records') ?? [];
    _records = list.map((e) => MenstrualRecord.fromJson(jsonDecode(e))).toList();
    final s = prefs.getString('menstrual_settings');
    if (s != null) _settings = CycleSettings.fromJson(jsonDecode(s));
  }

  static Future<void> saveRecord(MenstrualRecord record) async {
    final idx = _records.indexWhere((r) =>
        r.date.year == record.date.year &&
        r.date.month == record.date.month &&
        r.date.day == record.date.day);
    if (idx >= 0) {
      _records[idx] = record;
    } else {
      _records.add(record);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('menstrual_records',
        _records.map((r) => jsonEncode(r.toJson())).toList());
  }

  static Future<void> saveSettings(CycleSettings s) async {
    _settings = s;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('menstrual_settings', jsonEncode(s.toJson()));
  }
}
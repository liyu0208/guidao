import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menstrual_data.dart';

class MentrualProvider extends ChangeNotifier {
  List<MenstrualRecord> records = [];
  CycleSettings cycleSettings = CycleSettings();

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = prefs.getStringList('records') ?? [];
    records = recordsJson
        .map((e) => MenstrualRecord.fromJson(jsonDecode(e)))
        .toList();

    final settingsJson = prefs.getString('cycleSettings');
    if (settingsJson != null) {
      cycleSettings = CycleSettings.fromJson(jsonDecode(settingsJson));
    }
    notifyListeners();
  }

  Future<void> saveRecord(MenstrualRecord record) async {
    final existing = records.indexWhere((r) =>
        r.date.year == record.date.year &&
        r.date.month == record.date.month &&
        r.date.day == record.date.day);
    if (existing >= 0) {
      records[existing] = record;
    } else {
      records.add(record);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> updateSettings(CycleSettings settings) async {
    cycleSettings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cycleSettings', jsonEncode(settings.toJson()));
    notifyListeners();
  }

  MenstrualRecord? getRecordForDate(DateTime date) {
    try {
      return records.firstWhere((r) =>
          r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day);
    } catch (_) {
      return null;
    }
  }

  List<DateTime> get periodStartDates =>
      records.where((r) => r.periodStarted).map((r) => r.date).toList();

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'records', records.map((r) => jsonEncode(r.toJson())).toList());
  }
}
import 'package:flutter/material.dart';
import '../models/menstrual_data.dart';

class MenstrualProvider extends ChangeNotifier {
  List<MenstrualRecord> records = [];
  CycleSettings cycleSettings = CycleSettings();

  Future<void> loadData() async {
    await MenstrualData.loadAll();
    records = MenstrualData.records;
    cycleSettings = MenstrualData.settings;
    notifyListeners();
  }

  Future<void> saveRecord(MenstrualRecord record) async {
    await MenstrualData.saveRecord(record);
    records = MenstrualData.records;
    notifyListeners();
  }

  Future<void> updateSettings(CycleSettings settings) async {
    await MenstrualData.saveSettings(settings);
    cycleSettings = settings;
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
}
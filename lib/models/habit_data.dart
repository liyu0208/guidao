import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 习惯模型
class Habit {
  String id;
  String name;
  IconData icon;
  Color color;
  List<String> checkInDates; // 存储格式为 "2023-10-27" 的字符串列表

  Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    List<String>? dates,
  }) : checkInDates = dates ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'iconCode': icon.codePoint, // 存储图标代码
    'colorValue': color.value,   // 存储颜色数值
    'dates': checkInDates,
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'],
    name: json['name'],
    icon: IconData(json['iconCode'], fontFamily: 'MaterialIcons'),
    color: Color(json['colorValue']),
    dates: List<String>.from(json['dates']),
  );
}

// 习惯管理器
class HabitManager {
  static List<Habit> habits = [];

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(habits.map((e) => e.toJson()).toList());
    await prefs.setString('star_track_data_v1', data);
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('star_track_data_v1');
    if (data != null) {
      habits = (json.decode(data) as List).map((e) => Habit.fromJson(e)).toList();
    }
  }

  // 切换打卡状态
  static void toggleCheckIn(String habitId, String date) {
    final habit = habits.firstWhere((e) => e.id == habitId);
    if (habit.checkInDates.contains(date)) {
      habit.checkInDates.remove(date);
    } else {
      habit.checkInDates.add(date);
    }
    save();
  }
}
import 'dart:math';
import 'package:flutter/material.dart';

class AppShellPage extends StatelessWidget {
  final String title; const AppShellPage({super.key, required this.title});
  static const List<String> _humors = [
    "等待超新星爆发，功能积蓄能量中...",
    "宇宙正在深呼吸，动态稍后浮现...",
    "星星还没写完日记，晚点再来看看吧...",
    "黑洞吞噬了这段代码，程序员正在抢救中..."
  ];
  @override Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.auto_awesome, size: 60, color: Colors.blueAccent),
    const SizedBox(height: 25),
    Text(_humors[Random().nextInt(_humors.length)], style: const TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
  ]));
}
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// 世界书词条模型
class WorldBookEntry {
  String id;
  String keyword;  // 触发关键词
  String content;  // 设定内容
  bool isGlobal;   // 是否全局生效
  bool enabled;
  String characterId;

  WorldBookEntry({
    required this.id, required this.keyword, required this.content, this.isGlobal = true,
this.enabled = true,
this.characterId = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'keyword': keyword, 'content': content, 'isGlobal': isGlobal,
'enabled': enabled,
'characterId': characterId,
  };

  factory WorldBookEntry.fromJson(Map<String, dynamic> json) => WorldBookEntry(
    id: json['id'] ?? '',
    keyword: json['keyword'] ?? '',
    content: json['content'] ?? '',
    isGlobal: json['isGlobal'] ?? true,
    enabled: json['enabled'] ?? true,
    characterId: json['characterId'] ?? '',
  );
}

// 硬盘储存管理器
class WorldBookManager {
  static List<WorldBookEntry> entries = [];

  static Future<void> saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('world_book_v1', json.encode(entries.map((e) => e.toJson()).toList()));
  }

  static Future<void> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('world_book_v1');
    if (str != null) {
      entries = (json.decode(str) as List).map((e) => WorldBookEntry.fromJson(e)).toList();
    }
  }
  /// 给定对话文本，返回所有被触发的条目
/// [text] 要匹配的文本（通常是最近几条消息拼起来）
/// [characterId] 当前角色ID，null表示只匹配全局条目
static List<WorldBookEntry> getTriggered(String text, {String? characterId}) {
  final lower = text.toLowerCase();
  return entries.where((e) {
if (!e.enabled) return false;

    // 全局条目：直接参与匹配
    // 专属条目：只有 characterId 匹配时才参与
    if (!e.isGlobal) {
      if (characterId == null) return false;
      if (e.characterId != characterId) return false;
    }

    // 关键词匹配（后续支持多关键词时改这里）
    return lower.contains(e.keyword.toLowerCase());
  }).toList();
}

/// 把触发的条目内容拼成一段，注入到系统提示词前面
static String buildInjection(String text, {String? characterId}) {
  final triggered = entries.where((e) {
    if (!e.enabled) return false;
    if (e.isGlobal) return true; // 全局条目永远注入
    if (characterId == null) return false;
    return e.characterId == characterId; // 专属条目匹配角色
  }).toList();
  
  if (triggered.isEmpty) return '';
  final buffer = StringBuffer('[世界设定]\n');
  for (final e in triggered) {
    buffer.writeln('- ${e.content}');
  }
  return buffer.toString();
}
}
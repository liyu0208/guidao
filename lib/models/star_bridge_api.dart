import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StarBridgeApi {
  String id; String name; String url; String key;
  String selectedModel; double temperature;
  bool isDefault;

  // 语音与生图配置
  String minimaxGroupId; String minimaxKey; String minimaxModel;
  String novelAiKey; String novelAiModel;

  // --- 🌟 新增：GitHub 备份配置 ---
  String githubToken; String githubUser; String githubRepo; String githubPath;

  StarBridgeApi({
    required this.id, required this.name, required this.url, required this.key,
    this.selectedModel = "", this.temperature = 0.8,
    this.isDefault = false,
    this.minimaxGroupId = "", this.minimaxKey = "", this.minimaxModel = "",
    this.novelAiKey = "", this.novelAiModel = "nai-diffusion-3",
    this.githubToken = "", this.githubUser = "", this.githubRepo = "", this.githubPath = "",
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'url': url, 'key': key, 'selectedModel': selectedModel,
    'temperature': temperature, 'isDefault': isDefault,
    'minimaxGroupId': minimaxGroupId, 'minimaxKey': minimaxKey, 'minimaxModel': minimaxModel,
    'novelAiKey': novelAiKey, 'novelAiModel': novelAiModel,
    'githubToken': githubToken, 'githubUser': githubUser, 'githubRepo': githubRepo, 'githubPath': githubPath,
  };

  factory StarBridgeApi.fromJson(Map<String, dynamic> json) => StarBridgeApi(
    id: json['id'] ?? "", name: json['name'] ?? "", url: json['url'] ?? "", key: json['key'] ?? "",
    selectedModel: json['selectedModel'] ?? "",
    temperature: (json['temperature'] ?? 0.8).toDouble(),
    isDefault: json['isDefault'] ?? false,
    minimaxGroupId: json['minimaxGroupId'] ?? "",
    minimaxKey: json['minimaxKey'] ?? "",
    minimaxModel: json['minimaxModel'] ?? "",
    novelAiKey: json['novelAiKey'] ?? "",
    novelAiModel: json['novelAiModel'] ?? "nai-diffusion-3",
    githubToken: json['githubToken'] ?? "",
    githubUser: json['githubUser'] ?? "",
    githubRepo: json['githubRepo'] ?? "",
    githubPath: json['githubPath'] ?? "",
  );
}

class StarBridgeData {
  static List<StarBridgeApi> apiList = [];
  static Future<void> saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('star_bridge_v13_data', json.encode(apiList.map((e) => e.toJson()).toList()));
  }
  static Future<void> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString('star_bridge_v13_data');
    if (encoded != null) apiList = (json.decode(encoded) as List).map((e) => StarBridgeApi.fromJson(e)).toList();
  }
}
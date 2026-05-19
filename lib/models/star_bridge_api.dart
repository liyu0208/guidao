import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StarBridgeApi {
  String id; String name; String url; String key;
  String selectedModel; double temperature;
  bool isDefault;

  String minimaxGroupId; String minimaxKey; String minimaxModel;
  String novelAiKey; String novelAiModel;
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

  // 内置默认API
  static final StarBridgeApi _builtInApi = StarBridgeApi(
    id: "builtin_default",
    name: "星桥公益站",
    url: "https://api.242243.xyz/",
    key: "sk-ECEaIH4n4GJgnN2WlX6lrkgV5x3C73lIhGRIbVEhU892kqup",
    selectedModel: "",
    temperature: 0.8,
    isDefault: true,
  );

  static Future<void> saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('star_bridge_v13_data', json.encode(apiList.map((e) => e.toJson()).toList()));
  }

  static Future<void> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString('star_bridge_v13_data');
    if (encoded != null) {
      apiList = (json.decode(encoded) as List).map((e) => StarBridgeApi.fromJson(e)).toList();
    }
    // 如果列表里没有内置API，就自动插入到第一位
    final hasBuiltIn = apiList.any((e) => e.id == "builtin_default");
    if (!hasBuiltIn) {
      apiList.insert(0, _builtInApi);
      await saveAll();
    }
  }
}
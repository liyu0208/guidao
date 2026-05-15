import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class ChatRole {
  String id; String name; String remark; String persona; String avatar;
  String lastMessage; DateTime lastTime; bool isPinned;
String heartEmotion;
String heartThought;
String heartFeeling;
String heartUnsaid;
String heartStatus;
String heartMood;
String heartSecret;
String heartScene;
String heartRecent;
String heartUpdateMode; // "每次" "手动" "每N次"
int heartUpdateEvery;
bool isOfflineMode;
bool showEmotionInBar;double fontSize;
String replyLength;
bool replyLengthEnabled;int memoryCount;
String longTermMemory;
List<String> sensitiveWords;
String customBubbleCss;
  List<Map<String, String>> messages;

  bool showAvatar; bool showBubble; bool showTime; bool showName;
  String myBubbleStyle; String theirBubbleStyle;
  String fontColor; 
  double headerOpacity;  // 新增：标题栏透明度位置
  double footerOpacity;  // 新增：工具栏透明度位置
  String chatBackground;
  String worldBook;
  List<String> stickers;



  ChatRole({
    required this.id, required this.name, this.remark = "", this.persona = "",
    this.avatar = "", this.lastMessage = "", required this.lastTime,
    this.isPinned = false,
    this.heartEmotion = "",
this.heartThought = "",
this.heartFeeling = "",
this.heartUnsaid = "",
this.heartStatus = "",
this.heartMood = "",
this.heartSecret = "",
this.heartScene = "",
this.heartRecent = "",
this.heartUpdateMode = "每次",
this.heartUpdateEvery = 3,
this.isOfflineMode = false,
this.showEmotionInBar = false,this.fontSize = 14,
this.replyLength = "适中",
this.replyLengthEnabled = false,this.memoryCount = 20,
this.longTermMemory = "",
this.sensitiveWords = const [], List<Map<String, String>>? msgs,
    this.customBubbleCss = "",
    this.showAvatar = true, this.showBubble = true, this.showTime = true, this.showName = true,
    this.myBubbleStyle = "透明", this.theirBubbleStyle = "黑",
    this.fontColor = "#FFFFFF", 
    this.headerOpacity = 0.7, 
    this.footerOpacity = 0.3, this.chatBackground = "", this.worldBook = "无",
    List<String>? stickerList,
  }) : messages = msgs ?? [],stickers = stickerList ?? [];

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'remark': remark, 'persona': persona, 'avatar': avatar,
    'lastTime': lastTime.toIso8601String(), 'lastMessage': lastMessage,
    'messages': messages, 'isPinned': isPinned,'heartEmotion': heartEmotion,
'heartThought': heartThought,
'heartFeeling': heartFeeling,
'heartUnsaid': heartUnsaid,
'heartStatus': heartStatus,
'heartMood': heartMood,
'heartSecret': heartSecret,
'heartScene': heartScene,
'heartRecent': heartRecent,
'heartUpdateMode': heartUpdateMode,
'heartUpdateEvery': heartUpdateEvery,'isOfflineMode': isOfflineMode,
'showEmotionInBar': showEmotionInBar,
    'fontSize': fontSize,
'replyLength': replyLength,
'replyLengthEnabled': replyLengthEnabled,'memoryCount': memoryCount,
'longTermMemory': longTermMemory,
'sensitiveWords': sensitiveWords,'customBubbleCss': customBubbleCss,'showAvatar': showAvatar,
    'showBubble': showBubble, 'showTime': showTime, 'showName': showName,
    'myBubbleStyle': myBubbleStyle, 'theirBubbleStyle': theirBubbleStyle,
    'fontColor': fontColor, 
    'footerOpacity': footerOpacity, 'chatBackground': chatBackground,
    'worldBook': worldBook, 'stickers': stickers,
  };

// 定位于 ChatRole 类内部
  factory ChatRole.fromJson(Map<String, dynamic> json) => ChatRole(
    id: json['id'] ?? "", 
    name: json['name'] ?? "", 
    remark: json['remark'] ?? "",
    persona: json['persona'] ?? "", 
    avatar: json['avatar'] ?? "",
    lastTime: DateTime.parse(json['lastTime'] ?? DateTime.now().toIso8601String()), 
    lastMessage: json['lastMessage'] ?? "",
    msgs: List<Map<String, String>>.from((json['messages'] ?? []).map((i) => Map<String, String>.from(i))),
    isPinned: json['isPinned'] ?? false,
    heartEmotion: json['heartEmotion'] ?? "",
heartThought: json['heartThought'] ?? "",
heartFeeling: json['heartFeeling'] ?? "",
heartUnsaid: json['heartUnsaid'] ?? "",
heartStatus: json['heartStatus'] ?? "",
heartMood: json['heartMood'] ?? "",
heartSecret: json['heartSecret'] ?? "",
heartScene: json['heartScene'] ?? "",
heartRecent: json['heartRecent'] ?? "",
heartUpdateMode: json['heartUpdateMode'] ?? "每次",
heartUpdateEvery: json['heartUpdateEvery'] ?? 3,isOfflineMode: json['isOfflineMode'] ?? false,
showEmotionInBar: json['showEmotionInBar'] ?? false,fontSize: (json['fontSize'] ?? 14).toDouble(),
replyLength: json['replyLength'] ?? "适中",
replyLengthEnabled: json['replyLengthEnabled'] ?? false,memoryCount: json['memoryCount'] ?? 20,
longTermMemory: json['longTermMemory'] ?? "",
sensitiveWords: List<String>.from(json['sensitiveWords'] ?? []),
    customBubbleCss: json['customBubbleCss'] ?? "",
    showAvatar: json['showAvatar'] ?? true, 
    showBubble: json['showBubble'] ?? true,
    showTime: json['showTime'] ?? true, 
    showName: json['showName'] ?? true,
    myBubbleStyle: json['myBubbleStyle'] ?? "透明", 
    theirBubbleStyle: json['theirBubbleStyle'] ?? "黑",
    fontColor: json['fontColor'] ?? "#FFFFFF",

    // --- 核心修复：确保这里永远不会拿到 Null ---
    headerOpacity: (json['headerOpacity'] ?? 0.7).toDouble(),
    footerOpacity: (json['footerOpacity'] ?? 0.3).toDouble(),
    chatBackground: json['chatBackground'] ?? "", 
    worldBook: json['worldBook'] ?? "无",
  );
}

class ChatData {
  static List<ChatRole> roles = [];
  static String userName = "小行星";
  static String userSign = "穿梭于群星之间...";
  static String userMood = "";
  static String userAvatar = "";
  static String userBg = "";
  static String userLocation = "";
  static String userBirthday = "";
  static String userPet = "卫星";

  static Future<void> saveUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', userName);
    await prefs.setString('user_sign', userSign);
    await prefs.setString('user_mood', userMood);
    await prefs.setString('user_avatar', userAvatar);
    await prefs.setString('user_bg', userBg);
    await prefs.setString('user_location', userLocation);
    await prefs.setString('user_birthday', userBirthday);
    await prefs.setString('user_pet', userPet);
  }

  static Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('user_name') ?? "小行星";
    userSign = prefs.getString('user_sign') ?? "穿梭于群星之间...";
    userMood = prefs.getString('user_mood') ?? "";
    userAvatar = prefs.getString('user_avatar') ?? "";
    userBg = prefs.getString('user_bg') ?? "";
    userLocation = prefs.getString('user_location') ?? "";
    userBirthday = prefs.getString('user_birthday') ?? "";
    userPet = prefs.getString('user_pet') ?? "卫星";
  }
  static Future<void> saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_roles_final_v20', json.encode(roles.map((e) => e.toJson()).toList()));
  }
  static Future<void> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    String? d = prefs.getString('chat_roles_final_v20');
    if (d != null) roles = (json.decode(d) as List).map((e) => ChatRole.fromJson(e)).toList();
  }
}
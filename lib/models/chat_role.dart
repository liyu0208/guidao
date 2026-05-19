import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class ChatRole {
  String id; String name; String remark;List<String> openings;
String selectedOpening;
String patPat;
String userRelation;
String callUser; String persona; String avatar;
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
bool isOfflineMode;String offlineOutputMode;String bubbleRadius;String bubbleBorder;String bubbleShadow;String inputStyle;
String bubbleAnimation;double backgroundBlur;double avatarSize;
double avatarRadius;
bool showEmotionInBar;double fontSize;double myBubbleOpacity;
double myBubbleBlur;
double theirBubbleOpacity;
double theirBubbleBlur;List<Map<String, dynamic>> myBubblePresets;
List<Map<String, dynamic>> theirBubblePresets;
String replyLength;
bool replyLengthEnabled;int memoryCount;
String longTermMemory;
List<String> sensitiveWords;
String customBubbleCss;
  List<Map<String, String>> messages;

  bool showAvatar; bool showBubble; bool showTime; bool showName;
  String timePosition;
  String myBubbleStyle; String theirBubbleStyle;
  String fontColor; 
  double headerOpacity;  // 新增：标题栏透明度位置
  double footerOpacity;  // 新增：工具栏透明度位置
  List<String> chatBackgrounds;
String selectedBackground;
  String worldBook;
  List<String> stickers;



// 找到这一段，直接全部替换
  ChatRole({
    required this.id, 
    required this.name, 
    this.remark = "", 
    List<String>? openings,          // 修改点：去掉const
    this.selectedOpening = "",
    this.patPat = "",
    this.userRelation = "",
    this.callUser = "", 
    this.persona = "",
    this.avatar = "", 
    this.lastMessage = "", 
    required this.lastTime,
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
    this.offlineOutputMode = "分段式",
    this.bubbleRadius = "超圆角",
    this.bubbleBorder = "无",
    this.bubbleShadow = "无",
    this.inputStyle = "胶囊",
    this.bubbleAnimation = "无",
    this.backgroundBlur = 0,
    this.avatarSize = 40,
    this.avatarRadius = 50,
    this.showEmotionInBar = false,
    this.fontSize = 14,
    this.myBubbleOpacity = 0.15,
    this.myBubbleBlur = 12,
    this.theirBubbleOpacity = 0.15,
    this.theirBubbleBlur = 12,
    List<Map<String, dynamic>>? myBubblePresets,    // 修改点：去掉const
    List<Map<String, dynamic>>? theirBubblePresets, // 修改点：去掉const
    this.replyLength = "适中",
    this.replyLengthEnabled = false,
    this.memoryCount = 20,
    this.longTermMemory = "",
    List<String>? sensitiveWords,                    // 修改点：去掉const
    List<Map<String, String>>? msgs,
    this.customBubbleCss = "",
    this.showAvatar = true, 
    this.showBubble = true, 
    this.showTime = false,
    this.timePosition = "气泡下方", 
    this.showName = true,
    this.myBubbleStyle = "透明", 
    this.theirBubbleStyle = "黑",
    this.fontColor = "#FFFFFF", 
    this.headerOpacity = 0.7, 
    this.footerOpacity = 0.3, 
    List<String>? chatBackgrounds,                   // 修改点：去掉const
    this.selectedBackground = "", 
    this.worldBook = "无",
    List<String>? stickerList,
  }) : messages = msgs ?? [],
       openings = openings ?? [],                    // 确保列表是可变的
       myBubblePresets = myBubblePresets ?? [],      // 确保列表是可变的
       theirBubblePresets = theirBubblePresets ?? [], // 确保列表是可变的
       sensitiveWords = sensitiveWords ?? [],        // 确保列表是可变的
       chatBackgrounds = chatBackgrounds ?? [],      // 确保列表是可变的
       stickers = stickerList ?? [];
  Map<String, dynamic> toJson() => {
'id': id, 'name': name, 'remark': remark,'openings': openings,
'selectedOpening': selectedOpening,
'patPat': patPat,
'userRelation': userRelation,
'callUser': callUser, 'persona': persona, 'avatar': avatar,
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
'heartUpdateEvery': heartUpdateEvery,'isOfflineMode': isOfflineMode,'offlineOutputMode': offlineOutputMode,
'bubbleRadius': bubbleRadius,'bubbleBorder': bubbleBorder,'bubbleShadow': bubbleShadow,'inputStyle': inputStyle,'backgroundBlur': backgroundBlur,
'avatarSize': avatarSize,
'avatarRadius': avatarRadius,
'showEmotionInBar': showEmotionInBar,
'fontSize': fontSize,'myBubbleOpacity': myBubbleOpacity,
'myBubbleBlur': myBubbleBlur,
'theirBubbleOpacity': theirBubbleOpacity,
'theirBubbleBlur': theirBubbleBlur,'myBubblePresets': myBubblePresets,
'theirBubblePresets': theirBubblePresets,
'replyLength': replyLength,
'replyLengthEnabled': replyLengthEnabled,'memoryCount': memoryCount,
'longTermMemory': longTermMemory,
'sensitiveWords': sensitiveWords,'customBubbleCss': customBubbleCss,'showAvatar': showAvatar,
    'showBubble': showBubble, 'timePosition': timePosition, 'showName': showName,
    'myBubbleStyle': myBubbleStyle, 'theirBubbleStyle': theirBubbleStyle,
    'fontColor': fontColor, 
    'footerOpacity': footerOpacity, 'chatBackgrounds': chatBackgrounds,
'selectedBackground': selectedBackground,
    'worldBook': worldBook, 'stickers': stickers,
  };

// 定位于 ChatRole 类内部
factory ChatRole.fromJson(Map<String, dynamic> json) => ChatRole(
id: json['id'] ?? "", 
name: json['name'] ?? "", 
remark: json['remark'] ?? "",openings: List<String>.from(json['openings'] ?? []),
selectedOpening: json['selectedOpening'] ?? "",
patPat: json['patPat'] ?? "",
userRelation: json['userRelation'] ?? "",
callUser: json['callUser'] ?? "",
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
heartUpdateEvery: json['heartUpdateEvery'] ?? 3,isOfflineMode: json['isOfflineMode'] ?? false,offlineOutputMode: json['offlineOutputMode'] ?? "分段式",bubbleRadius: json['bubbleRadius'] ?? "超圆角",
bubbleBorder: json['bubbleBorder'] ?? "无",bubbleShadow: json['bubbleShadow'] ?? "无",inputStyle: json['inputStyle'] ?? "胶囊",backgroundBlur: (json['backgroundBlur'] ?? 0).toDouble(),

avatarSize: (json['avatarSize'] ?? 40).toDouble(),
avatarRadius: (json['avatarRadius'] ?? 50).toDouble(),
showEmotionInBar: json['showEmotionInBar'] ?? false,fontSize: (json['fontSize'] ?? 14).toDouble(),
myBubbleOpacity: (json['myBubbleOpacity'] ?? 0.15).toDouble(),
myBubbleBlur: (json['myBubbleBlur'] ?? 12).toDouble(),
theirBubbleOpacity: (json['theirBubbleOpacity'] ?? 0.15).toDouble(),
theirBubbleBlur: (json['theirBubbleBlur'] ?? 12).toDouble(),
myBubblePresets: List<Map<String, dynamic>>.from(json['myBubblePresets'] ?? []),
theirBubblePresets: List<Map<String, dynamic>>.from(json['theirBubblePresets'] ?? []),
replyLength: json['replyLength'] ?? "适中",
replyLengthEnabled: json['replyLengthEnabled'] ?? false,memoryCount: json['memoryCount'] ?? 20,
longTermMemory: json['longTermMemory'] ?? "",
sensitiveWords: List<String>.from(json['sensitiveWords'] ?? []),
    customBubbleCss: json['customBubbleCss'] ?? "",
    showAvatar: json['showAvatar'] ?? true, 
    showBubble: json['showBubble'] ?? true,
    showTime: json['showTime'] ?? true, 
    timePosition: json['timePosition'] ?? "气泡下方",
    showName: json['showName'] ?? true,
    myBubbleStyle: json['myBubbleStyle'] ?? "透明", 
    theirBubbleStyle: json['theirBubbleStyle'] ?? "黑",
    fontColor: json['fontColor'] ?? "#FFFFFF",

    // --- 核心修复：确保这里永远不会拿到 Null ---
    headerOpacity: (json['headerOpacity'] ?? 0.7).toDouble(),
    footerOpacity: (json['footerOpacity'] ?? 0.3).toDouble(),
    chatBackgrounds: List<String>.from(json['chatBackgrounds'] ?? []),
selectedBackground: json['selectedBackground'] ?? "", 
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
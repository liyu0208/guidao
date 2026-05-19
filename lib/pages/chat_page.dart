import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../models/chat_role.dart';
import '../models/star_bridge_api.dart';
import '../widgets/visual_elements.dart';
import 'app_shell.dart';
import '../models/world_book_data.dart';
import 'world_book_page.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:ui';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/services.dart';

// --- 辅助函数：统一头像渲染 ---
Widget _renderAvatar(String data) {
  if (data.isEmpty) {
    return const CircleAvatar(
      backgroundColor: Color(0x1A448AFF),
      child: Icon(Icons.person, color: Colors.white70),
    );
  }
  return CircleAvatar(backgroundImage: MemoryImage(base64Decode(data)));
}

// --- 辅助函数：统一胶囊按钮 ---
Widget _styledBtn(String t, Color c, VoidCallback o) => ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: c.withValues(alpha: 0.1),
    side: BorderSide(color: c.withValues(alpha: 0.3)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
  ),
  onPressed: o,
  child: Text(t, style: TextStyle(color: c)),
);

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  int _idx = 0;
  late PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});
  void _showAddChatDialog() {
    ChatData.roles
        .where(
          (r) =>
              !ChatData.roles.any(
                (other) => other.id == r.id && other.lastMessage.isNotEmpty,
              ),
        )
        .toList();

    showDialog(
      context: context,
      builder:
          (ctx) => StarThemedDialog(
            title: "添加聊天",
            content:
                ChatData.roles.isEmpty
                    ? const Text(
                      "还没有任何星友，请先在星友中添加",
                      style: TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center,
                    )
                    : SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: ChatData.roles.length,
                        itemBuilder: (c, i) {
                          final role = ChatData.roles[i];
                          return ListTile(
                            leading: const Icon(
                              Icons.person,
                              color: Colors.blueAccent,
                            ),
                            title: Text(
                              role.remark.isNotEmpty ? role.remark : role.name,
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (c) => ChatRoomPage(role: role),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "取消",
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) => MobileFrame(
    title: ["频段", "星友", "动态", "我"][_idx],
    appBarOpacity: 0.8,
    showBack: _idx < 2,
    actions:
        _idx == 0
            ? [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.blueAccent),
                onPressed: _showAddChatDialog,
              ),
            ]
            : _idx == 1
            ? [
              IconButton(
                icon: const Icon(
                  Icons.file_upload_outlined,
                  color: Colors.blueAccent,
                ),
                onPressed: _import,
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.blueAccent),
                onPressed: () => _editDlg(null),
              ),
            ]
            : null,
    child: Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: PageView(
        controller: _pageCtrl,
        onPageChanged: (i) => setState(() => _idx = i),
        children: [
          MsgTab(onRefresh: _refresh),
          FriendsTab(onRefresh: _refresh),
          const AppShellPage(title: "动态"),
          MeTab(onRefresh: _refresh),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 70,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: Colors.white10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 胶囊动画
                Stack(
                  children: List.generate(4, (i) {
                    return Align(
                      alignment: Alignment(-0.94 + (i * 0.63), 0),
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(i),
                        tween: Tween(begin: 0.0, end: _idx == i ? 1.0 : 0.0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutExpo,
                        builder: (ctx, v, _) {
                          // v从0到1：先变圆再变胶囊
                          final w =
                              v < 0.3
                                  ? v /
                                      0.3 *
                                      0.1 // 0~0.3: 从0扩展到圆形
                                  : 0.1 +
                                      (v - 0.3) / 0.7 * 0.12; // 0.3~1: 从圆扩展到胶囊
                          return FractionallySizedBox(
                            widthFactor: w.clamp(0.0, 0.22),
                            child: Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(
                                  90,
                                  123,
                                  178,
                                  255,
                                ).withOpacity(0.25 * v),
                                borderRadius: BorderRadius.circular(21),
                                boxShadow:
                                    v > 0.1
                                        ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF7B8FFF,
                                            ).withOpacity(0.3 * v),
                                            blurRadius: 12,
                                          ),
                                        ]
                                        : [],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ),

                // 图标行
                // 图标行
                Row(
                  children: List.generate(4, (i) {
                    final icons = [
                      Icons.chat_bubble_outline,
                      Icons.people_outline,
                      Icons.auto_awesome_mosaic,
                      Icons.person_outline,
                    ];
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() => _idx = i);
                          _pageCtrl.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Icon(
                          icons[i],
                          size: 24,
                          // 选中的图标变成亮蓝色，未选中的是暗灰色
                          color:
                              _idx == i
                                  ? const Color.fromARGB(255, 146, 181, 226)
                                  : Colors.white24,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  void _import() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'txt', 'png'],
      // 🌟 核心修复：强制要求将文件数据加载到内存中
      // 这样无论是在网页、Windows 还是手机上，f.bytes 都会有值，不再是 null
      withData: true,
    );
    if (r != null) {
      late final f = r.files.first;
      final bytes = f.bytes;
      if (bytes == null) {
        debugPrint("错误：未能读取到文件字节数据");
        return;
      }
      String n = f.name.split('.').first;
      String p = "";
      String a = "";
      if (f.extension == 'png') {
        a = base64Encode(bytes);
        String raw = latin1.decode(bytes);
        // ignore: deprecated_member_use
        RegExp exp = RegExp(r'\{"name":.*\}|\{"char_name":.*\}');
        var m = exp.firstMatch(raw);
        if (m != null) {
          try {
            var d = json.decode(utf8.decode(latin1.encode(m.group(0)!)));
            n = d['name'] ?? d['char_name'] ?? n;
            p = d['persona'] ?? d['description'] ?? "";
          } catch (e) {
            debugPrint("解析角色 PNG 元数据失败: $e");
          }
        }
      } else {
        p = utf8.decode(bytes, allowMalformed: true);
        try {
          final d = json.decode(p);
          n = d['name'] ?? d['char_name'] ?? n;
          p = d['persona'] ?? d['description'] ?? p;

          // 解析世界书（兼容 character_book 格式）
          final roleId = DateTime.now().toString();
          final cb = d['data']?['character_book'];
          final cbEntries = cb?['entries'];
          if (cbEntries is List) {
            for (int ei = 0; ei < cbEntries.length; ei++) {
              final val = cbEntries[ei];
              if (val is! Map) continue;
              final keys = val['keys'] ?? [];
              final comment = val['comment']?.toString() ?? '';
              final keyword =
                  (keys is List && keys.isNotEmpty)
                      ? keys.join('，')
                      : (comment.isNotEmpty ? comment : '条目$ei');
              final content = val['content'] ?? '';
              final enabled = val['enabled'] ?? true;
              if (content.toString().isNotEmpty) {
                WorldBookManager.entries.add(
                  WorldBookEntry(
                    id: '${roleId}_$ei',
                    keyword: keyword,
                    content: content.toString(),
                    isGlobal: false,
                    characterId: roleId,
                    enabled: enabled,
                  ),
                );
              }
            }
            WorldBookManager.saveAll();
          }

          n =
              n
                  // ignore: deprecated_member_use
                  .replaceAll(RegExp(r'(_v\d+.*|导入-|角色卡-|\.json|\.png)'), '')
                  .trim();
          // 读取开场白
          List<String> importedOpenings = [];
          // 优先用alternate_greetings作为开场白列表
          final altGreetings =
              d['data']?['alternate_greetings'] ?? d['alternate_greetings'];
          if (altGreetings is List && altGreetings.isNotEmpty) {
            for (final g in altGreetings) {
              if (g is String && g.isNotEmpty) importedOpenings.add(g);
            }
          } else {
            // 没有alternate_greetings才用first_mes
            final firstMes = d['data']?['first_mes'] ?? d['first_mes'];
            if (firstMes is String && firstMes.isNotEmpty) {
              importedOpenings.add(firstMes);
            }
          }

          setState(() {
            final newRole = ChatRole(
              id: roleId,
              name: n,
              persona: p,
              avatar: a,
              lastTime: DateTime.now(),
              msgs: [],
            );
            newRole.openings = importedOpenings;
            if (importedOpenings.isNotEmpty) {
              newRole.selectedOpening = importedOpenings.first;
            }
            ChatData.roles.add(newRole);
          });
          ChatData.saveAll();
          return; // 已经处理完，跳过下面的 add
        } catch (e) {
          debugPrint("解析角色文本/JSON失败: $e");
        }
      }
      // ignore: deprecated_member_use
      n = n.replaceAll(RegExp(r'(_v\d+.*|导入-|角色卡-|\.json|\.png)'), '').trim();
      setState(() {
        ChatData.roles.add(
          ChatRole(
            id: DateTime.now().toString(),
            name: n,
            persona: p,
            avatar: a,
            lastTime: DateTime.now(),
            msgs: [],
          ),
        );
      });
      ChatData.saveAll();
    }
  }

  void _editDlg(ChatRole? r) {
    final nC = TextEditingController(text: r?.name ?? ""),
        rC = TextEditingController(text: r?.remark ?? ""),
        pC = TextEditingController(text: r?.persona ?? "");
    showDialog(
      context: context,
      builder:
          (ctx) => StarThemedDialog(
            title: r == null ? "添加" : "编辑",
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [_f(nC, "名字"), _f(rC, "备注"), _f(pC, "人设", lines: 4)],
            ),
            actions: [
              if (r != null)
                TextButton(
                  onPressed: () {
                    setState(() => ChatData.roles.remove(r));
                    ChatData.saveAll();
                    Navigator.pop(ctx);
                  },
                  child: const Text("删除", style: TextStyle(color: Colors.red)),
                ),
              _styledBtn("取消", Colors.white30, () => Navigator.pop(ctx)),
              _styledBtn("保存", Colors.blueAccent, () {
                setState(() {
                  if (r == null) {
                    ChatData.roles.add(
                      ChatRole(
                        id: DateTime.now().toString(),
                        name: nC.text,
                        remark: rC.text,
                        persona: pC.text,
                        lastTime: DateTime.now(),
                        msgs: [],
                      ),
                    );
                  } else {
                    r.name = nC.text;
                    r.remark = rC.text;
                    r.persona = pC.text;
                  }
                });
                ChatData.saveAll();
                Navigator.pop(ctx);
              }),
            ],
          ),
    );
  }

  Widget _f(TextEditingController c, String l, {int lines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: l,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}

class MobileFrame extends StatelessWidget {
  final String title;
  final double appBarOpacity;
  final List<Widget>? actions;
  final Widget child;
  final String? avatar;
  final double avatarRadius;
  final bool showBack; // 🌟 新增这一行

  const MobileFrame({
    super.key,
    required this.title,
    required this.appBarOpacity,
    this.actions,
    required this.child,
    this.avatar,
    this.avatarRadius = 50,
    this.showBack = true, // 🌟 新增这一行，默认显示返回按钮
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: Stack(
      children: [
        const RepaintBoundary(child: DynamicStarBackground()),
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (showBack)
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: Colors.white70,
                      ),
                    ),
                  if (!showBack)
                    const SizedBox(width: 20), // 🌟 如果隐藏了，占个位或者保持间距
                  const Spacer(),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// --- Tab: 消息列表 ---
class MsgTab extends StatelessWidget {
  final VoidCallback onRefresh;
  const MsgTab({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) => AnimationLimiter(
    child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(0, 60, 0, 20),
      itemCount: ChatData.roles.length,
      // 关键：中间那根极细的冷光线
      separatorBuilder:
          (context, index) => Divider(
            color: Colors.white.withOpacity(0.05),
            indent: 75, // 线条从头像文字交界处开始，不贯穿，更高级
            height: 1,
          ),
      itemBuilder:
          (ctx, i) => AnimationConfiguration.staggeredList(
            position: i,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 30,
              child: FadeInAnimation(
                child: GestureDetector(
                  onTap: () {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (c) => ChatRoomPage(role: ChatData.roles[i]),
                          ),
                        );
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        ChatData.roles[i].avatar.isEmpty
                            ? PlanetAvatar(seed: ChatData.roles[i].name)
                            : ClipRRect(
                              borderRadius: BorderRadius.circular(
                                ChatData.roles[i].avatarRadius,
                              ),
                              child: Image.memory(
                                base64Decode(ChatData.roles[i].avatar),
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ChatData.roles[i].remark.isEmpty
                                    ? ChatData.roles[i].name
                                    : ChatData.roles[i].remark,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ChatData.roles[i].lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.3, end: 1.0),
                          duration: const Duration(milliseconds: 1200),
                          onEnd: () {},
                          builder:
                              (ctx, val, _) => Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.greenAccent.withOpacity(val),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.greenAccent.withOpacity(
                                        val * 0.5,
                                      ),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    ),
  );
}

// --- Tab: 星友列表 ---
// --- [开始替换]：星友列表科技化 ---
class FriendsTab extends StatelessWidget {
  final VoidCallback onRefresh;
  const FriendsTab({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 80, 0, 10),
        itemCount: ChatData.roles.length,
        itemBuilder:
            (ctx, i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  ChatData.roles[i].avatar.isEmpty
                      ? PlanetAvatar(seed: ChatData.roles[i].name)
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(
                          ChatData.roles[i].avatarRadius,
                        ),
                        child: Image.memory(
                          base64Decode(ChatData.roles[i].avatar),
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Future.delayed(const Duration(milliseconds: 150), () {
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (c) =>
                                        ChatRoomPage(role: ChatData.roles[i]),
                              ),
                            );
                          }
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ChatData.roles[i].remark.isEmpty
                                ? ChatData.roles[i].name
                                : ChatData.roles[i].remark,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "ID: 已加密",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.25),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder:
                            (ctx) => StarThemedDialog(
                              title: "删除星友",
                              content: Text(
                                "确定删除「${ChatData.roles[i].remark.isEmpty ? ChatData.roles[i].name : ChatData.roles[i].remark}」吗？\n聊天记录将一并删除。",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white54),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text(
                                    "取消",
                                    style: TextStyle(color: Colors.white38),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent
                                        .withOpacity(0.2),
                                  ),
                                  onPressed: () {
                                    ChatData.roles.removeAt(i);
                                    ChatData.saveAll();
                                    Navigator.pop(ctx);
                                    onRefresh();
                                  },
                                  child: const Text(
                                    "删除",
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            ),
                      );
                    },
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white24,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
      ),
      Positioned(
        top: 40,
        left: 0,
        right: 0,
        child: Text(
          "Stars",
          style: TextStyle(
            fontSize: 36,
            color: Colors.white30,
            fontWeight: FontWeight.w100,
            letterSpacing: 12,
            fontStyle: FontStyle.italic,
            fontFamily: 'serif',
          ),
        ),
      ),
    ],
  );
}

// --- Tab: 我 ---
// --- 这一段完整替换你现在的 MeTab ---
class MeTab extends StatelessWidget {
  final VoidCallback onRefresh;
  const MeTab({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 60),
      children: [
        // 顶部头像区
        Container(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
          child: Row(
            children: [
              GestureDetector(
                child:
                    ChatData.userAvatar.isEmpty
                        ? PlanetAvatar(
                          seed: ChatData.userName,
                          size: 60,
                          radius: 20,
                        )
                        : ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.memory(
                            base64Decode(ChatData.userAvatar),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ChatData.userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ChatData.userSign,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 心情状态
        if (ChatData.userMood.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.mood, size: 14, color: Colors.amberAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ChatData.userMood,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),

        // 统计卡片
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _statCard("星友", "${ChatData.roles.length}", Icons.people_outline),
              const SizedBox(width: 12),
              _statCard(
                "消息",
                "${ChatData.roles.fold(0, (s, r) => s + r.messages.length)}",
                Icons.chat_bubble_outline,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 功能列表
        _menuItem(Icons.palette_outlined, "美化", "自定义外观"),
        _menuItem(Icons.auto_awesome, "今日星历", "查看日记"),
        _menuItem(Icons.track_changes_rounded, "星轨打卡", "查看习惯"),
        _menuItem(Icons.dark_mode, "今日月相", "查看周期"),
        _menuItem(Icons.settings_outlined, "设置", "个性化"),
        const SizedBox(height: 30),
      ],
    );
  }

  // 统计卡片零件
  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white38),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white54),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.25),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, size: 16, color: Colors.white24),
        ],
      ),
    );
  }
}

// --- 聊天室 ---
class ChatRoomPage extends StatefulWidget {
  final ChatRole role;
  const ChatRoomPage({super.key, required this.role});
  @override
  State<ChatRoomPage> createState() => _CRPState();
}

class _CRPState extends State<ChatRoomPage> {
  final _ctrl = TextEditingController();
  final _scrollC = ScrollController(); // 🌟 新增这一行
  bool _isT = false;
  int _retryCount = 0;
  bool _showMorePanel = false;
  MemoryImage? _cachedBg;
  MemoryImage? _cachedRoleAvatar; // ← 加这行：角色头像缓存
  MemoryImage? _cachedUserAvatar;

  // 🌟 顺便在这里补上一个 dispose，防止内存泄露
  @override
  void dispose() {
    _scrollC.dispose(); // 🌟 确保有这一行
    _ctrl.dispose(); // 如果你有输入框控制器，也顺便加上
    super.dispose();
  }

  final RegExp _segmentSplit = RegExp(r'(?<=[。！？!?；;,.，\n])\s*');
  final List<Map<String, dynamic>> _stickerGroups = [
    {
      "id": "default",
      "name": "默认",
      "items": <Map<String, String>>[
        {"type": "image", "value": "", "label": "😀"},
        {"type": "image", "value": "", "label": "😂"},
        {"type": "image", "value": "", "label": "🥰"},
        {"type": "image", "value": "", "label": "😎"},
      ],
    },
    {
      "id": "funny",
      "name": "搞怪",
      "items": <Map<String, String>>[
        {"type": "image", "value": "", "label": "😭"},
        {"type": "image", "value": "", "label": "👍"},
        {"type": "image", "value": "", "label": "🎉"},
        {"type": "image", "value": "", "label": "❤️"},
      ],
    },
  ];
  int _activeStickerGroup = 0;
  void _confirmDelete(Map<String, dynamic> msg) {
    showDialog(
      context: context,
      builder:
          (ctx) => StarThemedDialog(
            title: "抹除记忆",
            content: const Text(
              "确定要从星轨记录中永久抹除这条消息吗？",
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("保留"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                ),
                onPressed: () {
                  setState(() {
                    widget.role.messages.remove(msg);
                  });
                  ChatData.saveAll();
                  Navigator.pop(ctx);
                },
                child: const Text(
                  "抹除",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.role.selectedBackground.isNotEmpty) {
      _cachedBg = MemoryImage(base64Decode(widget.role.selectedBackground));
    }
    // 头像缓存（新加的）↓
    if (widget.role.avatar.isNotEmpty) {
      _cachedRoleAvatar = MemoryImage(base64Decode(widget.role.avatar));
    }
    if (ChatData.userAvatar.isNotEmpty) {
      _cachedUserAvatar = MemoryImage(base64Decode(ChatData.userAvatar));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollC.hasClients) {
        _scrollC.jumpTo(_scrollC.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) => MobileFrame(
    title: "",
    appBarOpacity: widget.role.headerOpacity,
    avatar: null,
    actions: const [],
    showBack: false, // ← 加这行，隐藏 MobileFrame 自带的返回键
    child: Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (_showMorePanel) {
              FocusScope.of(context).unfocus();
              setState(() => _showMorePanel = false);
            }
          },
          child: Container(
            child: Stack(
              children: [
                if (_cachedBg != null)
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: widget.role.backgroundBlur,
                          sigmaY: widget.role.backgroundBlur,
                        ),
                        child: Image(
                          image: _cachedBg!, // ← 用缓存，不重新解码
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                Column(
                  children: [
                    const SizedBox(height: 70),
                    if (widget.role.showEmotionInBar &&
                        widget.role.heartEmotion.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.favorite,
                              size: 12,
                              color: Colors.pinkAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "情绪：${widget.role.heartEmotion}　心情：${widget.role.heartMood}　状态：${widget.role.heartStatus}",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollC,
                        padding: const EdgeInsets.all(15),
                        itemCount: widget.role.messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = widget.role.messages[i];
                          final showDivider =
                              widget.role.showTime &&
                              i > 0 &&
                              _shouldShowDivider(
                                widget.role.messages[i - 1]['time'],
                                msg['time'],
                              );
                          return Column(
                            children: [
                              if (showDivider) _buildTimeDivider(msg['time']),
                              _buildRow(msg),
                            ],
                          );
                        },
                      ),
                    ),
                    if (_isT)
                      const LinearProgressIndicator(
                        minHeight: 1,
                        color: Colors.cyanAccent,
                      ),
                    AnimatedSlide(
                      offset: _showMorePanel ? Offset.zero : const Offset(0, 1),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: _showMorePanel ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child:
                            _showMorePanel
                                ? _buildMorePanel()
                                : const SizedBox.shrink(),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _toggleMorePanel,
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Icon(
                                _showMorePanel
                                    ? Icons.close_rounded
                                    : Icons.add_rounded,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                widget.role.inputStyle == "方形"
                                    ? 8
                                    : widget.role.inputStyle == "极简"
                                    ? 0
                                    : 20,
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 12,
                                  sigmaY: 12,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(
                                      widget.role.footerOpacity,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      widget.role.inputStyle == "方形"
                                          ? 8
                                          : widget.role.inputStyle == "极简"
                                          ? 0
                                          : 20,
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.25),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _ctrl,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: "接入频段...",
                                      hintStyle: TextStyle(
                                        color: Colors.white24,
                                        fontSize: 13,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _send,
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _reply,
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Colors.amberAccent,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // 悬浮头像标题栏
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: Colors.black.withOpacity(0.15), //这个数字越小越透明，聊天室上方横条
                padding: const EdgeInsets.only(bottom: 4),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 10), // 箭头和头像的间距，越大间距越宽
                        widget.role.avatar.isEmpty
                            ? Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: Colors.white38,
                              ),
                            )
                            : ClipRRect(
                              borderRadius: BorderRadius.circular(
                                widget.role.avatarRadius,
                              ),
                              child: Image(
                                image: _cachedRoleAvatar!, // ← 用缓存
                                width: widget.role.avatarSize,
                                height: widget.role.avatarSize,
                                fit: BoxFit.cover,
                              ),
                            ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.role.remark.isEmpty
                                    ? widget.role.name
                                    : widget.role.remark,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              Text(
                                "接入中",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.greenAccent.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (c) =>
                                          ChatSettingsPage(role: widget.role),
                                ),
                              ).then((_) => setState(() {})),
                          child: const Icon(
                            Icons.more_horiz,
                            size: 22,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  void _toggleMorePanel() {
    FocusScope.of(context).unfocus();
    setState(() => _showMorePanel = !_showMorePanel);
  }

  void _send() {
    if (_ctrl.text.trim().isEmpty) return;
    _sendUserMessage(_ctrl.text.trim());
    setState(() {
      _ctrl.clear();
    });
  }

  void _sendUserMessage(
    String text, {
    String? imageBase64,
    String kind = "text",
    String? extra,
  }) {
    setState(() {
      final msg = <String, String>{
        "role": "user",
        "text": text,
        "kind": kind,
        "time": DateTime.now().toIso8601String(),
      };
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        msg["image"] = imageBase64;
      }
      if (extra != null && extra.isNotEmpty) msg["extra"] = extra;
      widget.role.messages.add(msg);
      widget.role.lastMessage = text;
      _showMorePanel = false;
    });
    ChatData.saveAll();
  }

  Future<void> _reply() async {
    setState(() => _isT = true);
    try {
      final api = StarBridgeData.apiList.firstWhere(
        (e) => e.isDefault,
        orElse:
            () =>
                StarBridgeData.apiList.isNotEmpty
                    ? StarBridgeData.apiList.first
                    : StarBridgeApi(id: "", name: "", url: "", key: ""),
      );

      if (api.key.isEmpty) {
        _showErr("请先配置 API Key。");
        setState(() => _isT = false);
        return;
      }

      // --- 核心修复 1：最精准的地址拼接逻辑 ---
      String baseUrl = api.url.trim();
      if (!baseUrl.endsWith('/')) baseUrl += '/';

      String finalUrl = "";
      if (baseUrl.contains("googleapis.com")) {
        // Google 官方 OpenAI 兼容模式必须包含 /v1/
        // 如果用户填的地址里没带 v1，我们帮他补上
        finalUrl =
            baseUrl.contains('/v1/')
                ? "${baseUrl}chat/completions"
                : "${baseUrl}v1/chat/completions";
      } else {
        finalUrl =
            baseUrl.contains('chat/completions')
                ? baseUrl
                : "${baseUrl}v1/chat/completions";
      }

      // --- 核心修复 2：清洗模型名称 ---
      String modelName = api.selectedModel.replaceAll('models/', '').trim();

      final res = await http
          .post(
            Uri.parse(finalUrl),
            headers: {
              "Authorization": "Bearer ${api.key}",
              "Content-Type": "application/json",
            },
            body: json.encode({
              "model": modelName,
              "temperature": api.temperature,
              "messages": [
                {
                  "role": "system",
                  "content": () {
                    final wb = WorldBookManager.buildInjection(
                      '',
                      characterId: widget.role.id,
                    );
                    final modePrompt =
                        !widget.role.isOfflineMode
                            ? "你正在与用户进行线上聊天（类似微信/QQ），只输出纯对话文字，不要任何动作描写、旁白或场景描述。"
                            : widget.role.offlineOutputMode == "一段式"
                            ? '你正在与用户进行线下真实互动。输出格式：动作描写、环境描写、心理活动直接输出不加任何符号；角色开口说话的内容必须用英文双引号"包裹，例如：他走上前，"你在干什么？"他问道。整体连贯自然，不要分段。'
                            : "你正在与用户进行线下真实互动。回复格式规则：动作描写、环境描写、心理活动、对{{user}}的观察全部用（）括号包裹；对话文字直接输出不加括号。括号内容和对话内容交替出现，不要混在同一段里。";
                    final lengthPrompt =
                        widget.role.replyLengthEnabled
                            ? (widget.role.replyLength == "短"
                                ? "\n回复要简短，控制在1-2句话以内。"
                                : widget.role.replyLength == "详细"
                                ? "\n回复要详细丰富，可以多几句话。"
                                : "\n回复长度适中，不要太长也不要太短。")
                            : "";
                    final wbPrompt =
                        wb.isNotEmpty
                            ? "\n\n以下是背景参考设定，仅供你理解世界观，不要直接输出这些内容：\n$wb"
                            : "";
                    return "扮演【${widget.role.name}】。${widget.role.longTermMemory.isNotEmpty ? '\n\n【长期记忆】\n${widget.role.longTermMemory}' : ''} $modePrompt$lengthPrompt\n\n人设：${widget.role.persona}。${widget.role.userRelation.isNotEmpty ? '\n与用户的关系：${widget.role.userRelation}。' : ''}${widget.role.callUser.isNotEmpty ? '\n称呼用户为：${widget.role.callUser}。' : ''}$wbPrompt${_shouldGenerateHeart() ? '\n\n【重要格式要求】每次回复必须严格按以下格式输出，不能省略任何部分：\n[对话]\n（你的回复内容）\n[心声]\n情绪:（一个词）\n想法:（一句话）\n感受:（对用户说话方式的感受）\n想说:（想说没说出口的话）\n状态:（当前在做什么）\n心情:（今天心情关键词）\n秘密:（有没有心事，没有就写无）\n场景:（当前所处环境）\n近事:（最近发生的事）' : ''}";
                  }(),
                },
                ...widget.role.messages.reversed
                    .take(widget.role.memoryCount)
                    .toList()
                    .reversed
                    .map(
                      (m) => {
                        "role": m['role'],
                        "content": _buildApiContent(m),
                      },
                    ),
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final data =
            json.decode(
              utf8.decode(res.bodyBytes),
            )['choices'][0]['message']['content'];
        await _appendAssistantMessagesGradually(data.toString());
        ChatData.saveAll();
      } else {
        String detail = "";
        try {
          var errJson = json.decode(res.body);
          detail = errJson['error']['message'] ?? res.body;
        } catch (_) {
          detail = res.body;
        }
        // 详细弹窗，能显示在哪里出错
        _showErr(
          "星桥响应异常: ${res.statusCode}\n\n原因: $detail\n\n请求模型: $modelName\n请求地址: $finalUrl",
        );
      }
    } catch (e) {
      if (_retryCount < 2) {
        _retryCount++;
        await Future.delayed(const Duration(seconds: 2));
        await _reply();
        return;
      }
      _retryCount = 0;
      _showErr("星桥链路故障\n\n详情: $e");
    }
    setState(() => _isT = false);
  }

  // _showErr 让它更美观（使用之前做好的弹窗风格）
  void _showErr(String m) => showDialog(
    context: context,
    builder:
        (c) => StarThemedDialog(
          title: "通讯中断",
          content: Text(
            m,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          actions: [_styledBtn("确认", Colors.redAccent, () => Navigator.pop(c))],
        ),
  );
  void _showPlaceholderTip(String name) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$name 功能开发中"),
          duration: const Duration(milliseconds: 1200),
        ),
      );
  String _buildApiContent(Map<String, dynamic> message) {
    final txt = (message["text"] ?? "").toString();
    final img = (message["image"] ?? "").toString();
    final kind = (message["kind"] ?? "text").toString();
    final extra = (message["extra"] ?? "").toString();
    if (kind == "voice") return "[语音消息] 内容：$txt";
    if (kind == "gift") return "[礼物消息] 物品：$extra";
    if (kind == "red_packet") return "[红包消息] 金额：$extra";
    if (kind == "sticker") return "[表情包消息] 备注：$txt";
    if (img.isEmpty) return txt;
    return "$txt\n[该消息附带一张图片/表情]";
  }

  Future<void> _pickFromAlbumAndSend() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    // 核心修改：明确标记 kind 为 image
    _sendUserMessage("【图片】", imageBase64: base64Encode(bytes), kind: "image");
  }

  Future<void> _captureAndSend() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    // 核心修改：明确标记 kind 为 image
    _sendUserMessage("【拍摄图片】", imageBase64: base64Encode(bytes), kind: "image");
  }

  Future<void> _showVoiceInputDialog() async {
    final c = TextEditingController();
    await showDialog(
      context: context,
      builder:
          (ctx) => StarThemedDialog(
            title: "发送语音",
            content: TextField(
              controller: c,
              maxLines: 4,
              decoration: const InputDecoration(hintText: "输入语音识别文字..."),
            ),
            actions: [
              _styledBtn("取消", Colors.white30, () => Navigator.pop(ctx)),
              _styledBtn("发送", Colors.blueAccent, () {
                final t = c.text.trim();
                if (t.isEmpty) return;
                Navigator.pop(ctx);
                _sendUserMessage(t, kind: "voice");
              }),
            ],
          ),
    );
  }

  Future<void> _regenerateReply() async {
    if (_isT) return;
    setState(() {
      while (widget.role.messages.isNotEmpty &&
          widget.role.messages.last["role"] == "assistant") {
        widget.role.messages.removeLast();
      }
      if (widget.role.messages.isNotEmpty) {
        widget.role.lastMessage =
            (widget.role.messages.last["text"] ?? "").toString();
      } else {
        widget.role.lastMessage = "";
      }
      _showMorePanel = false;
    });
    ChatData.saveAll();
    await _reply();
  }

  Future<void> _importStickerFromAlbum() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    final group = _stickerGroups[_activeStickerGroup];
    final items = (group["items"] as List).cast<Map<String, String>>();
    setState(() {
      items.add({
        "type": "image",
        "value": base64Encode(bytes),
        "label": "自定义${items.length + 1}",
      });
    });
  }

  Future<void> _importStickerFromUrl() async {
    final c = TextEditingController();
    await showDialog(
      context: context,
      builder:
          (ctx) => StarThemedDialog(
            title: "URL 导入表情",
            content: TextField(
              controller: c,
              decoration: const InputDecoration(
                hintText: "https://example.com/sticker.png",
              ),
            ),
            actions: [
              _styledBtn("取消", Colors.white30, () => Navigator.pop(ctx)),
              _styledBtn("导入", Colors.blueAccent, () async {
                final raw = c.text.trim();
                if (raw.isEmpty) return;
                try {
                  final uri = Uri.parse(raw);
                  final res = await http.get(uri);
                  if (res.statusCode != 200) {
                    if (mounted) _showErr("下载失败，状态码 ${res.statusCode}");
                    return;
                  }
                  final group = _stickerGroups[_activeStickerGroup];
                  final items =
                      (group["items"] as List).cast<Map<String, String>>();
                  if (mounted) {
                    setState(() {
                      items.add({
                        "type": "image",
                        "value": base64Encode(res.bodyBytes),
                        "label": "URL导入${items.length + 1}",
                      });
                    });
                  }
                  if (!mounted || !ctx.mounted) return;
                  Navigator.pop(ctx);
                } catch (_) {
                  if (mounted) _showErr("URL 无效或下载失败");
                }
              }),
            ],
          ),
    );
  }

  Future<void> _createStickerGroup() async {
    final c = TextEditingController();
    await showDialog(
      context: context,
      builder:
          (ctx) => StarThemedDialog(
            title: "新建分组",
            content: TextField(
              controller: c,
              decoration: const InputDecoration(hintText: "分组名"),
            ),
            actions: [
              _styledBtn("取消", Colors.white30, () => Navigator.pop(ctx)),
              _styledBtn("创建", Colors.blueAccent, () {
                final name = c.text.trim();
                if (name.isEmpty) return;
                setState(() {
                  _stickerGroups.add({
                    "id": DateTime.now().millisecondsSinceEpoch.toString(),
                    "name": name,
                    "items": <Map<String, String>>[],
                  });
                  _activeStickerGroup = _stickerGroups.length - 1;
                });
                Navigator.pop(ctx);
              }),
            ],
          ),
    );
  }

  Future<void> _renameStickerGroup() async {
    if (_stickerGroups.isEmpty) return;
    final group = _stickerGroups[_activeStickerGroup];
    final c = TextEditingController(text: (group["name"] ?? "").toString());
    await showDialog(
      context: context,
      builder:
          (ctx) => StarThemedDialog(
            title: "重命名分组",
            content: TextField(
              controller: c,
              decoration: const InputDecoration(hintText: "分组名"),
            ),
            actions: [
              _styledBtn("取消", Colors.white30, () => Navigator.pop(ctx)),
              _styledBtn("保存", Colors.blueAccent, () {
                final name = c.text.trim();
                if (name.isEmpty) return;
                setState(() {
                  group["name"] = name;
                });
                Navigator.pop(ctx);
              }),
            ],
          ),
    );
  }

  Future<void> _deleteStickerGroup() async {
    if (_stickerGroups.length <= 1) {
      _showErr("至少保留一个分组");
      return;
    }
    final name = (_stickerGroups[_activeStickerGroup]["name"] ?? "").toString();
    await showDialog(
      context: context,
      builder:
          (ctx) => StarThemedDialog(
            title: "删除分组",
            content: Text("确认删除分组：$name ？"),
            actions: [
              _styledBtn("取消", Colors.white30, () => Navigator.pop(ctx)),
              _styledBtn("删除", Colors.redAccent, () {
                setState(() {
                  _stickerGroups.removeAt(_activeStickerGroup);
                  _activeStickerGroup = _activeStickerGroup.clamp(
                    0,
                    _stickerGroups.length - 1,
                  );
                });
                Navigator.pop(ctx);
              }),
            ],
          ),
    );
  }

  Future<void> _openStickerPanel() async {
    _showMorePanel = false;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final itemW = (MediaQuery.of(ctx).size.width - 56) / 5;
        return StatefulBuilder(
          builder: (sheetCtx, sheetSetState) {
            final group = _stickerGroups[_activeStickerGroup];
            final items = (group["items"] as List).cast<Map<String, String>>();
            return Container(
              // 核心修改：强制高度为屏幕的 2/5 (0.4)
              height: MediaQuery.of(ctx).size.height * 0.4,
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: SafeArea(
                top: false,
                // 核心修改：去掉 mainAxisSize.min，让它撑满设定的高度
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "表情包",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _createStickerGroup();
                            sheetSetState(() {});
                          },
                          child: const Text("新建"),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _renameStickerGroup();
                            sheetSetState(() {});
                          },
                          child: const Text("重命名"),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _deleteStickerGroup();
                            sheetSetState(() {});
                          },
                          child: const Text("删除"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _stickerGroups.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder:
                            (_, i) => ChoiceChip(
                              selected: _activeStickerGroup == i,
                              label: Text(
                                (_stickerGroups[i]["name"] ?? "").toString(),
                              ),
                              onSelected:
                                  (_) => sheetSetState(
                                    () => _activeStickerGroup = i,
                                  ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _styledBtn(
                            "相册导入",
                            Colors.blueAccent,
                            () async {
                              await _importStickerFromAlbum();
                              sheetSetState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _styledBtn(
                            "URL导入",
                            Colors.purpleAccent,
                            () async {
                              await _importStickerFromUrl();
                              sheetSetState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 核心修改：使用 Expanded 和 SingleChildScrollView 让表情包可以往下滚动，防止越界
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          runSpacing: 10,
                          spacing: 8, // 加点水平间距
                          children:
                              items
                                  .map(
                                    (item) => SizedBox(
                                      width: itemW,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          if ((item["value"] ?? "").isEmpty) {
                                            _sendUserMessage(
                                              "【表情】${item["label"]}",
                                              kind: "sticker",
                                            );
                                          } else {
                                            // 发送表情包不再带上 label 文字
                                            _sendUserMessage(
                                              "",
                                              imageBase64: item["value"],
                                              kind: "sticker",
                                            );
                                          }
                                        },
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 46,
                                              height: 46,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child:
                                                  (item["value"] ?? "").isEmpty
                                                      ? Center(
                                                        child: Text(
                                                          item["label"] ?? "",
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 24,
                                                              ),
                                                        ),
                                                      )
                                                      : ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        child: Image.memory(
                                                          base64Decode(
                                                            item["value"] ?? "",
                                                          ),
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item["label"] ?? "",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showGiftDialog() async {
    final c = TextEditingController();
    await showDialog(
      context: context,
      builder:
          (ctx) => StarThemedDialog(
            title: "发礼物",
            content: TextField(
              controller: c,
              decoration: const InputDecoration(hintText: "输入礼物名，如：玫瑰花"),
            ),
            actions: [
              _styledBtn("取消", Colors.white30, () => Navigator.pop(ctx)),
              _styledBtn("发送", Colors.amber, () {
                final gift = c.text.trim();
                if (gift.isEmpty) return;
                Navigator.pop(ctx);
                _sendUserMessage("送出礼物：$gift", kind: "gift", extra: gift);
              }),
            ],
          ),
    );
  }

  Future<void> _showRedPacketDialog() async {
    final c = TextEditingController();
    await showDialog(
      context: context,
      builder:
          (ctx) => StarThemedDialog(
            title: "虚拟红包",
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    "恭喜发财，大吉大利",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: c,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: "输入红包数字"),
                ),
              ],
            ),
            actions: [
              _styledBtn("取消", Colors.white30, () => Navigator.pop(ctx)),
              _styledBtn("发送", Colors.redAccent, () {
                final amount = c.text.trim();
                final v = num.tryParse(amount);
                if (v == null || v <= 0) return;
                Navigator.pop(ctx);
                _sendUserMessage(
                  "发送了红包：$amount",
                  kind: "red_packet",
                  extra: amount,
                );
              }),
            ],
          ),
    );
  }

  Future<void> _onMoreActionTap(String label) async {
    switch (label) {
      case "相册":
        await _pickFromAlbumAndSend();
        return;
      case "拍摄":
        await _captureAndSend();
        return;
      case "发送语音":
        await _showVoiceInputDialog();
        return;
      case "重回":
        await _regenerateReply();
        return;
      case "表情包":
        await _openStickerPanel();
        return;
      case "发礼物":
        await _showGiftDialog();
        return;
      case "发红包":
        await _showRedPacketDialog();
        return;
      default:
        _showPlaceholderTip(label);
    }
  }

  Widget _buildMorePanel() {
    // 1. 去掉了 4 个 "待定"，只保留真实的 8 个功能
    final actions = <Map<String, dynamic>>[
      {"icon": Icons.photo_library_outlined, "label": "相册"},
      {"icon": Icons.photo_camera_outlined, "label": "拍摄"},
      {"icon": Icons.keyboard_voice_outlined, "label": "发送语音"},
      {"icon": Icons.insert_drive_file_outlined, "label": "发送文件"},
      {"icon": Icons.redeem_outlined, "label": "发红包"},
      {"icon": Icons.card_giftcard_outlined, "label": "发礼物"},
      {"icon": Icons.undo_outlined, "label": "重回"},
      {"icon": Icons.emoji_emotions_outlined, "label": "表情包"},
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      padding: const EdgeInsets.fromLTRB(10, 15, 10, 15),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      // 2. 核心修复：使用 GridView 代替 Wrap，彻底解决溢出和适配问题
      child: GridView.builder(
        shrinkWrap: true, // 必须加：防止溢出
        physics: const NeverScrollableScrollPhysics(), // 必须加：禁止内部滚动
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 严格规定一行 4 个
          mainAxisSpacing: 15, // 上下间距
          crossAxisSpacing: 0, // 左右间距由系统自动均分
          childAspectRatio: 0.85, // 调整图标和文字的比例
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final e = actions[index];
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _onMoreActionTap(e['label'] as String),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Icon(
                    e['icon'] as IconData,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  e['label'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _appendAssistantMessagesGradually(String rawText) async {
    // 解析心声
    String dialogText = rawText;
    if (rawText.contains('[心声]')) {
      final dialogMatch = RegExp(
        r'(?:\[对话\])?([\s\S]*?)\[心声\]',
      ).firstMatch(rawText);
      final heartMatch = RegExp(r'\[心声\]([\s\S]*)$').firstMatch(rawText);
      if (dialogMatch != null)
        dialogText = dialogMatch.group(1)?.trim() ?? rawText;
      if (heartMatch != null) {
        final heart = heartMatch.group(1) ?? '';
        setState(() {
          widget.role.heartEmotion = _parseHeart(heart, '情绪');
          widget.role.heartThought = _parseHeart(heart, '想法');
          widget.role.heartFeeling = _parseHeart(heart, '感受');
          widget.role.heartUnsaid = _parseHeart(heart, '想说');
          widget.role.heartStatus = _parseHeart(heart, '状态');
          widget.role.heartMood = _parseHeart(heart, '心情');
          widget.role.heartSecret = _parseHeart(heart, '秘密');
          widget.role.heartScene = _parseHeart(heart, '场景');
          widget.role.heartRecent = _parseHeart(heart, '近事');
        });
        ChatData.saveAll();
      }
    }

    // 敏感词过滤
    String filtered = dialogText;
    for (final word in widget.role.sensitiveWords) {
      if (word.isNotEmpty) {
        filtered = filtered.replaceAll(word, '*' * word.length);
      }
    }
    final segments = _splitReplySegments(filtered);
    for (final seg in segments) {
      if (!mounted) return;
      setState(() {
        widget.role.messages.add({
          "role": "assistant",
          "text": seg,
          "time": DateTime.now().toIso8601String(),
        });
        widget.role.lastMessage = seg;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollC.hasClients) {
          _scrollC.animateTo(
            _scrollC.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      await Future.delayed(
        Duration(milliseconds: 280 + (seg.length * 14).clamp(0, 520)),
      );
    }
  }

  String _parseHeart(String text, String key) {
    final match = RegExp('$key:(.*)').firstMatch(text);
    return match?.group(1)?.trim() ?? '';
  }

  List<String> _splitReplySegments(String text) {
    final normalized = text.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) return const [];

    // 线下模式：按括号和对话分割
    if (widget.role.isOfflineMode && widget.role.offlineOutputMode != "一段式") {
      final List<String> segments = [];
      final RegExp bracketExp = RegExp(r'（[^）]*）|([^（）]+)');
      for (final match in bracketExp.allMatches(normalized)) {
        final seg = match.group(0)?.trim() ?? '';
        if (seg.isNotEmpty) segments.add(seg);
      }
      return segments.isEmpty ? [normalized] : segments;
    }
    if (widget.role.isOfflineMode && widget.role.offlineOutputMode == "一段式") {
      return [normalized];
    }

    // 线上模式：原来的按标点切割
    final chunks =
        normalized
            .split(_segmentSplit)
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
    return chunks.isEmpty ? [normalized] : chunks;
  }

  Widget _buildRow(Map<String, dynamic> message) {
    final isM = message['role'] == 'user';
    final t = (message['text'] ?? '').toString();
    final img = (message['image'] ?? '').toString();
    final kind = (message['kind'] ?? 'text').toString();
    final extra = (message['extra'] ?? '').toString();
    final timeStr = _formatTime(message['time']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isM ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 对方头像：传入对方的名字作为随机种子
if (!isM && widget.role.showAvatar)
  Column(
    children: [
      GestureDetector(
        onTap: () => _showHeartDialog(),
        child:
            widget.role.avatar.isEmpty
                ? PlanetAvatar(
                  seed: widget.role.name,
                  size: widget.role.avatarSize,
                  radius: widget.role.avatarRadius,
                )
                : ClipRRect(
                  borderRadius: BorderRadius.circular(
                    widget.role.avatarRadius,
                  ),
                  child: Image(               // ← 改这里
                    image: _cachedRoleAvatar!,
                    width: widget.role.avatarSize,
                    height: widget.role.avatarSize,
                    fit: BoxFit.cover,
                  ),
                ),
      ),
  
                if (widget.role.showTime &&
                    widget.role.timePosition == "头像下方" &&
                    timeStr.isNotEmpty)
                  Text(
                    timeStr,
                    style: const TextStyle(fontSize: 9, color: Colors.white38),
                  ),
              ],
            ),

          if (!isM && widget.role.showAvatar) const SizedBox(width: 8),

          Flexible(
            child: Column(
              crossAxisAlignment:
                  isM ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: () => _confirmDelete(message),
                  child:
                      widget.role.showTime && widget.role.timePosition == "气泡末尾"
                          ? Stack(
                            children: [
                              _bubble(
                                t,
                                isM,
                                imageBase64: img,
                                kind: kind,
                                extra: extra,
                              ),
                              if (timeStr.isNotEmpty)
                                Positioned(
                                  bottom: 4,
                                  right: isM ? 4 : null,
                                  left: isM ? null : 4,
                                  child: Text(
                                    timeStr,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.white38,
                                    ),
                                  ),
                                ),
                            ],
                          )
                          : _bubble(
                            t,
                            isM,
                            imageBase64: img,
                            kind: kind,
                            extra: extra,
                          ),
                ),
                if (widget.role.showTime &&
                    widget.role.timePosition == "气泡下方" &&
                    timeStr.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white38,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (isM && widget.role.showAvatar) const SizedBox(width: 8),
          // 2. 我方头像：也统一换成小星球（或者你可以保留你原本的头像）
          // 我方头像：传入我的名字作为随机种子
          if (isM && widget.role.showAvatar)
            Column(
              children: [
                ChatData.userAvatar.isEmpty
                    ? PlanetAvatar(
                      seed: ChatData.userName,
                      size: widget.role.avatarSize,
                      radius: widget.role.avatarRadius,
                    )
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(
                        widget.role.avatarRadius,
                      ),
                      child: Image(
                        image: _cachedUserAvatar!, // ← 用缓存
                        width: widget.role.avatarSize,
                        height: widget.role.avatarSize,
                        fit: BoxFit.cover,
                      ),
                    ),
                if (widget.role.showTime &&
                    widget.role.timePosition == "头像下方" &&
                    timeStr.isNotEmpty)
                  Text(
                    timeStr,
                    style: const TextStyle(fontSize: 9, color: Colors.white38),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _bubble(
    String t,
    bool isM, {
    String imageBase64 = "",
    String kind = "text",
    String extra = "",
  }) {
    final hasImg = imageBase64.isNotEmpty;
    bool hideText = kind == "image" || kind == "sticker" || kind == "voice";

    // 1. 构建消息的内容（图片、语音、礼物、红包或纯文字）
    Widget contentWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasImg)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              base64Decode(imageBase64),
              width: 180,
              fit: BoxFit.cover,
            ),
          ),
        if (kind == "voice")
          VoiceBubble(text: t, isMe: isM, fontColor: Colors.cyanAccent),
        if (kind == "gift")
          Text(
            "🎁 礼物: $extra",
            style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
          ),
        if (kind == "red_packet")
          Text(
            "🧧 红包: $extra",
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        if (!hideText && t.isNotEmpty) _buildRichText(t),
      ],
    );

    // 2. 判断是否需要带背景气泡（表情包、纯图片、纯语音不需要气泡框）
    bool standalone =
        (hasImg && t.isEmpty) || kind == "voice" || kind == "sticker";

    if (standalone || !widget.role.showBubble) {
      return contentWidget;
    }

    final style =
        isM ? widget.role.myBubbleStyle : widget.role.theirBubbleStyle;
    final op =
        isM ? widget.role.myBubbleOpacity : widget.role.theirBubbleOpacity;
    Color bubbleColor;
    if (style.startsWith('#')) {
      try {
        bubbleColor = Color(
          int.parse(style.replaceFirst('#', '0xFF')),
        ).withOpacity(op);
      } catch (_) {
        bubbleColor = Colors.white.withOpacity(op * 0.2);
      }
    } else if (style.startsWith('preset_')) {
      // 从预设列表里找到对应的savedColor
      final presetList =
          isM ? widget.role.myBubblePresets : widget.role.theirBubblePresets;
      final preset = presetList.firstWhere(
        (p) => p["color"] == style,
        orElse: () => {},
      );
      final savedColor = preset["savedColor"] as String? ?? "";
      if (savedColor.startsWith('#')) {
        try {
          bubbleColor = Color(
            int.parse(savedColor.replaceFirst('#', '0xFF')),
          ).withOpacity(op);
        } catch (_) {
          bubbleColor = Colors.white.withOpacity(op * 0.2);
        }
      } else {
        bubbleColor =
            {
              "透明": Colors.white.withOpacity(op * 0.2),
              "白": Colors.white.withOpacity(op),
              "蓝": Colors.blueAccent.withOpacity(op),
              "粉": Colors.pinkAccent.withOpacity(op),
              "绿": Colors.greenAccent.withOpacity(op),
              "紫": Colors.purpleAccent.withOpacity(op),
            }[savedColor] ??
            Colors.white.withOpacity(op * 0.2);
      }
    } else {
      bubbleColor =
          {
            "透明": Colors.white.withOpacity(op * 0.2),
            "白": Colors.white.withOpacity(op),
            "蓝": Colors.blueAccent.withOpacity(op),
            "粉": Colors.pinkAccent.withOpacity(op),
            "绿": Colors.greenAccent.withOpacity(op),
            "紫": Colors.purpleAccent.withOpacity(op),
          }[style] ??
          Colors.white.withOpacity(op * 0.2);
    }
    final radius =
        widget.role.bubbleRadius == "方形"
            ? 6.0
            : widget.role.bubbleRadius == "微圆"
            ? 12.0
            : 18.0;
    final shadow = <BoxShadow>[
      ...({
            "轻柔": [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            "深邃": [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            "霓虹": [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.3),
                blurRadius: 12,
              ),
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.15),
                blurRadius: 24,
              ),
            ],
          }[widget.role.bubbleShadow] ??
          []),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isM ? widget.role.myBubbleBlur : widget.role.theirBubbleBlur,
          sigmaY: isM ? widget.role.myBubbleBlur : widget.role.theirBubbleBlur,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color:
                  widget.role.bubbleBorder == "无"
                      ? Colors.transparent
                      : Colors.white.withOpacity(
                        widget.role.bubbleBorder == "细边框" ? 0.15 : 0.4,
                      ),
              width: widget.role.bubbleBorder == "粗边框" ? 1.5 : 0.5,
            ),
            boxShadow: shadow,
          ),
          child: contentWidget,
        ),
      ),
    );
  }

  void _showHeartDialog() {
    final role = widget.role;
    if ([
      role.heartEmotion,
      role.heartThought,
      role.heartUnsaid,
      role.heartStatus,
      role.heartSecret,
    ].every((e) => e.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("还没有心声数据，先让TA回复一次吧")));
      return;
    }
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder:
          (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          role.avatar.isEmpty
                              ? PlanetAvatar(seed: role.name)
                              : ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  role.avatarRadius,
                                ),
                                child: Image.memory(
                                  base64Decode(role.avatar),
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                role.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (role.heartEmotion.isNotEmpty)
                                Text(
                                  "情绪：${role.heartEmotion}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.cyanAccent,
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),

                      _heartItem("💭 内心想法", role.heartThought),
                      _heartItem("🤐 没说出口", role.heartUnsaid),
                      _heartItem("✨ 当前状态", role.heartStatus),
                      _heartItem("🌙 心情", role.heartMood),
                      _heartItem("🌑 坏心思", role.heartSecret),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _heartItem(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white38),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  bool _shouldGenerateHeart() {
    final mode = widget.role.heartUpdateMode;
    if (mode == "每次") return true;
    final count = widget.role.messages.where((m) => m['role'] == 'user').length;
    if (mode == "每3条") return count % 3 == 0;
    if (mode == "每5条") return count % 5 == 0;
    return true;
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null || isoTime.isEmpty) return '';
    try {
      final t = DateTime.parse(isoTime);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final tDate = DateTime(t.year, t.month, t.day);
      final hm =
          "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
      if (tDate == today) return hm;
      if (tDate == yesterday) return "昨天 $hm";
      return "${t.month}/${t.day} $hm";
    } catch (_) {
      return '';
    }
  }

  Widget _buildTimeDivider(String? isoTime) {
    if (isoTime == null || isoTime.isEmpty) return const SizedBox.shrink();
    final label = _formatTime(isoTime);
    if (label.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.white12)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white38),
            ),
          ),
          const Expanded(child: Divider(color: Colors.white12)),
        ],
      ),
    );
  }

  bool _shouldShowDivider(String? prevTime, String? currTime) {
    if (prevTime == null || currTime == null) return false;
    try {
      final prev = DateTime.parse(prevTime);
      final curr = DateTime.parse(currTime);
      return curr.difference(prev).inMinutes >= 5;
    } catch (_) {
      return false;
    }
  }

  Widget _buildRichText(String text) {
    // 只有线下一段式才用富文本
    if (!widget.role.isOfflineMode || widget.role.offlineOutputMode != "一段式") {
      return Text(
        text,
        style: TextStyle(
          fontSize: widget.role.fontSize,
          color: (() {
            try {
              return (() {
                try {
                  return Color(
                    int.parse(widget.role.fontColor.replaceFirst('#', '0xFF')),
                  );
                } catch (_) {
                  return Colors.white;
                }
              }());
            } catch (_) {
              return Colors.white;
            }
          }()),
        ),
      );
    }

    // 一段式：括号内描写用白色半透明，括号外对话用字体颜色
    final spans = <TextSpan>[];
    Color dialogColor;
    try {
      dialogColor = (() {
        try {
          return Color(
            int.parse(widget.role.fontColor.replaceFirst('#', '0xFF')),
          );
        } catch (_) {
          return Colors.white;
        }
      }());
    } catch (_) {
      dialogColor = Colors.white;
    }
    final descColor = Colors.white.withOpacity(0.45);
    final style = TextStyle(fontSize: widget.role.fontSize);

    final RegExp exp = RegExp(r'["\u201c][^\u201d"]*["\u201d]');
    int last = 0;
    for (final match in exp.allMatches(text)) {
      if (match.start > last) {
        spans.add(
          TextSpan(
            text: text.substring(last, match.start),
            style: style.copyWith(color: descColor),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: style.copyWith(color: dialogColor),
        ),
      );
      last = match.end;
    }
    if (last < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(last),
          style: style.copyWith(color: descColor),
        ),
      );
    }

    return RichText(
      textScaleFactor: MediaQuery.of(context).textScaleFactor,
      text: TextSpan(
        style: TextStyle(fontSize: widget.role.fontSize),
        children: spans,
      ),
    );
  }
}

// --- 频率调节页 (独立于大类，消除嵌套) ---
class ChatSettingsPage extends StatefulWidget {
  final ChatRole role;
  const ChatSettingsPage({super.key, required this.role});
  @override
  State<ChatSettingsPage> createState() => _CSPState();
}

class _CSPState extends State<ChatSettingsPage> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: Stack(
      children: [
        const DynamicStarBackground(),
        Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Colors.white70,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        ChatData.saveAll();
                        Navigator.maybePop(context);
                      },
                      child: const Text(
                        "保存",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickAv,
                    child:
                        widget.role.avatar.isEmpty
                            ? PlanetAvatar(
                              seed: widget.role.name,
                              size: widget.role.avatarSize,
                              radius: widget.role.avatarRadius,
                            )
                            : ClipRRect(
                              borderRadius: BorderRadius.circular(
                                widget.role.avatarRadius,
                              ),
                              child: Image.memory(
                                base64Decode(widget.role.avatar),
                                width: widget.role.avatarSize,
                                height: widget.role.avatarSize,
                                fit: BoxFit.cover,
                              ),
                            ),
                  ),
                  const SizedBox(width: 15),
                  GestureDetector(
                    onTap: _editB,
                    child: Text(
                      widget.role.remark.isEmpty
                          ? widget.role.name
                          : widget.role.remark,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [_t(0, "档案"), _t(1, "美化"), _t(2, "交互")],
            ),
            const Divider(color: Colors.white10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children:
                    _tab == 0
                        ? _pTab()
                        : _tab == 1
                        ? _bTab()
                        : [_oTab()],
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _t(int i, String t) => GestureDetector(
    onTap: () => setState(() => _tab = i),
    child: Text(
      t,
      style: TextStyle(
        color: _tab == i ? Colors.blueAccent : Colors.white30,
        fontWeight: _tab == i ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  );
  List<Widget> _pTab() => [
    // 角色备注
    _fld("角色备注", widget.role.remark, (v) => widget.role.remark = v),
    const SizedBox(height: 12),

    // 角色世界书
    _tile(
      Icons.auto_stories,
      "角色世界书",
      WorldBookManager.entries
              .where((e) => e.characterId == widget.role.id)
              .isEmpty
          ? "暂无绑定条目"
          : "${WorldBookManager.entries.where((e) => e.characterId == widget.role.id).length} 条法则已绑定",
      () => Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (c) => CharacterRulesPage(
                charName: widget.role.name,
                characterId: widget.role.id,
                onRefresh: () => setState(() {}),
              ),
        ),
      ),
    ),

    // 挂载表情包
    _tile(Icons.emoji_emotions, "挂载表情包", "管理", _stickers),
    const SizedBox(height: 12),

    // 人设设定
    const Text("人设设定", style: TextStyle(fontSize: 13, color: Colors.white54)),
    const SizedBox(height: 6),
    TextField(
      maxLines: 5,
      controller: TextEditingController(text: widget.role.persona),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        hintText: "描述角色的性格、背景、说话方式...",
        hintStyle: const TextStyle(fontSize: 12, color: Colors.white24),
      ),
      onChanged: (v) => widget.role.persona = v,
    ),
    const SizedBox(height: 12),

    // 开场白
    Row(
      children: [
        const Text(
          "开场白",
          style: TextStyle(fontSize: 13, color: Colors.white54),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => _showOpeningPicker(),
          child: const Text(
            "选择",
            style: TextStyle(color: Colors.blueAccent, fontSize: 12),
          ),
        ),
        TextButton(
          onPressed: () {
            final c = TextEditingController();
            showDialog(
              context: context,
              builder:
                  (ctx) => StarThemedDialog(
                    title: "添加开场白",
                    content: TextField(
                      controller: c,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "输入自定义开场白...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          "取消",
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final text = c.text.trim();
                          if (text.isNotEmpty) {
                            setState(() {
                              widget.role.openings = List.from(
                                widget.role.openings,
                              )..add(text);
                            });
                            ChatData.saveAll();
                          }
                          Navigator.pop(ctx);
                        },
                        child: const Text("添加"),
                      ),
                    ],
                  ),
            );
          },
          child: const Text(
            "+ 添加",
            style: TextStyle(color: Colors.blueAccent, fontSize: 12),
          ),
        ),
      ],
    ),
    const SizedBox(height: 6),
    TextField(
      maxLines: 5,
      controller: TextEditingController(text: widget.role.selectedOpening),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        hintText: "选择或添加开场白...",
        hintStyle: const TextStyle(fontSize: 12, color: Colors.white24),
      ),
      onChanged: (v) => widget.role.selectedOpening = v,
    ),
    const SizedBox(height: 8),
    const SizedBox(height: 12),

    // 拍一拍
    _tile(
      Icons.touch_app_outlined,
      "拍一拍",
      widget.role.patPat.isEmpty ? "未设置" : widget.role.patPat,
      () {
        final c = TextEditingController(text: widget.role.patPat);
        showDialog(
          context: context,
          builder:
              (ctx) => StarThemedDialog(
                title: "拍一拍回应",
                content: TextField(
                  controller: c,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "被拍一拍时AI会说的话...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      "取消",
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => widget.role.patPat = c.text.trim());
                      Navigator.pop(ctx);
                    },
                    child: const Text("保存"),
                  ),
                ],
              ),
        );
      },
    ),

    // 角色头像
    _tile(Icons.face_outlined, "角色头像", "点击更换", _pickAv),
    const SizedBox(height: 12),

    // 与user的关系
    const Text(
      "与user的关系",
      style: TextStyle(fontSize: 13, color: Colors.white54),
    ),
    const SizedBox(height: 6),
    TextField(
      controller: TextEditingController(text: widget.role.userRelation),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        hintText: "例如：青梅竹马、上司、陌生人...",
        hintStyle: const TextStyle(fontSize: 12, color: Colors.white24),
      ),
      onChanged: (v) => widget.role.userRelation = v,
    ),
    const SizedBox(height: 12),

    // 称user为
    const Text("称user为", style: TextStyle(fontSize: 13, color: Colors.white54)),
    const SizedBox(height: 6),
    TextField(
      controller: TextEditingController(text: widget.role.callUser),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        hintText: "例如：你、主人、小姐姐...",
        hintStyle: const TextStyle(fontSize: 12, color: Colors.white24),
      ),
      onChanged: (v) => widget.role.callUser = v,
    ),
    const SizedBox(height: 20),
  ];
  List<Widget> _bTab() => [
    // ═══ 头像区块 ═══
    _expandSection("头像", Icons.face_outlined, [
      _sw(
        "显示头像",
        widget.role.showAvatar,
        (v) => setState(() => widget.role.showAvatar = v),
      ),
      _sw(
        "显示时间",
        widget.role.showTime,
        (v) => setState(() => widget.role.showTime = v),
      ),
      if (widget.role.showTime) ...[
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children:
              ["气泡下方", "气泡末尾", "头像下方"].map((opt) {
                final selected = widget.role.timePosition == opt;
                return GestureDetector(
                  onTap: () => setState(() => widget.role.timePosition = opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          selected
                              ? Colors.blueAccent.withOpacity(0.2)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? Colors.blueAccent : Colors.white24,
                      ),
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(
                        color: selected ? Colors.blueAccent : Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 8),
      ],
      // 头像大小（占位）
      _sliderRow(
        "头像大小",
        widget.role.avatarSize,
        20,
        80,
        (v) => setState(() => widget.role.avatarSize = v),
      ),
      // 头像圆角（占位）
      _sliderRow(
        "头像圆角",
        widget.role.avatarRadius,
        0,
        50,
        (v) => setState(() => widget.role.avatarRadius = v),
      ),
      const SizedBox(height: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "字体大小: ${widget.role.fontSize.toStringAsFixed(0)}",
            style: const TextStyle(fontSize: 13, color: Colors.white54),
          ),
          Slider(
            value: widget.role.fontSize,
            min: 10,
            max: 22,
            divisions: 12,
            activeColor: Colors.blueAccent,
            onChanged: (v) => setState(() => widget.role.fontSize = v),
          ),
        ],
      ),
      const SizedBox(height: 8),

      // 颜色预设圆圈和自定义输入框保持不变
    ]),
    const SizedBox(height: 8),

    // ═══ 气泡区块 ═══
    _expandSection("气泡", Icons.chat_bubble_outline, [
      const SizedBox(height: 16),
      const Text("预览", style: TextStyle(fontSize: 13, color: Colors.white54)),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TA的气泡预览
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PlanetAvatar(seed: widget.role.name),
                const SizedBox(width: 8),
                _previewBubble("你好呀～", false),
              ],
            ),
            const SizedBox(height: 12),
            // 我的气泡预览
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _previewBubble("嗨！最近怎么样？", true),
                const SizedBox(width: 8),
                PlanetAvatar(seed: ChatData.userName),
              ],
            ),
          ],
        ),
      ),
      _sw(
        "显示气泡",
        widget.role.showBubble,
        (v) => setState(() => widget.role.showBubble = v),
      ),
      const SizedBox(height: 8),
      // 气泡颜色（已有功能保留）
      _bubbleColorPicker(
        "我的气泡",
        widget.role.myBubbleStyle,
        widget.role.myBubblePresets,
        true,
        (v) => setState(() => widget.role.myBubbleStyle = v),
      ),
      _bubbleColorPicker(
        "TA的气泡",
        widget.role.theirBubbleStyle,
        widget.role.theirBubblePresets,
        false,
        (v) => setState(() => widget.role.theirBubbleStyle = v),
      ),
      const SizedBox(height: 12),
      // 气泡圆角（占位）
      const Text("气泡圆角", style: TextStyle(fontSize: 13, color: Colors.white54)),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            ["方形", "微圆", "超圆角"].map((opt) {
              final selected = widget.role.bubbleRadius == opt;
              return GestureDetector(
                onTap: () => setState(() => widget.role.bubbleRadius = opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        selected
                            ? Colors.blueAccent.withOpacity(0.15)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? Colors.blueAccent : Colors.white24,
                    ),
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.blueAccent : Colors.white38,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
      const SizedBox(height: 12),
      // 气泡边框（占位）
      const Text("气泡边框", style: TextStyle(fontSize: 13, color: Colors.white54)),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            ["无", "细边框", "粗边框"].map((opt) {
              final selected = widget.role.bubbleBorder == opt;
              return GestureDetector(
                onTap: () => setState(() => widget.role.bubbleBorder = opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        selected
                            ? Colors.blueAccent.withOpacity(0.15)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? Colors.blueAccent : Colors.white24,
                    ),
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.blueAccent : Colors.white38,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
      const SizedBox(height: 12),
      // 气泡阴影（占位）
      const Text("气泡阴影", style: TextStyle(fontSize: 13, color: Colors.white54)),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            ["无", "轻柔", "深邃", "霓虹"].map((opt) {
              final selected = widget.role.bubbleShadow == opt;
              return GestureDetector(
                onTap: () => setState(() => widget.role.bubbleShadow = opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        selected
                            ? Colors.blueAccent.withOpacity(0.15)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? Colors.blueAccent : Colors.white24,
                    ),
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.blueAccent : Colors.white38,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
      const SizedBox(height: 12),
      // 气泡动画（占位）
      const Text("气泡动画", style: TextStyle(fontSize: 13, color: Colors.white54)),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            ["无", "上浮", "缩放", "浮入"].map((opt) {
              final selected = widget.role.bubbleAnimation == opt;
              return GestureDetector(
                onTap: () => setState(() => widget.role.bubbleAnimation = opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        selected
                            ? Colors.blueAccent.withOpacity(0.15)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? Colors.blueAccent : Colors.white24,
                    ),
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.blueAccent : Colors.white38,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    ]),
    const SizedBox(height: 8),

    // ═══ 背景与界面区块 ═══
    _expandSection("背景与界面", Icons.wallpaper_outlined, [
      // 聊天背景（已有功能保留）
      _tile(Icons.image, "聊天背景", "更换", _bg),
      // 背景模糊度（占位）
      _sliderRow(
        "背景模糊度",
        widget.role.backgroundBlur,
        0,
        20,
        (v) => setState(() => widget.role.backgroundBlur = v),
      ),
      const SizedBox(height: 12),
      // 输入框样式（占位）
      const Text(
        "输入框样式",
        style: TextStyle(fontSize: 13, color: Colors.white54),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            ["胶囊", "方形", "极简"].map((opt) {
              final selected = widget.role.inputStyle == opt;
              return GestureDetector(
                onTap: () => setState(() => widget.role.inputStyle = opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        selected
                            ? Colors.blueAccent.withOpacity(0.2)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? Colors.blueAccent : Colors.white24,
                    ),
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.blueAccent : Colors.white38,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
      const SizedBox(height: 12),
      // 顶栏透明度（占位）
      _sliderRow(
        "顶栏透明度",
        widget.role.headerOpacity,
        0,
        1,
        (v) => setState(() => widget.role.headerOpacity = v),
      ),
      // 工具栏透明度（已有功能保留）
      _sld(
        "工具栏透明度",
        widget.role.footerOpacity,
        (v) => setState(() => widget.role.footerOpacity = v),
      ),
      // 气泡CSS
      _tile(Icons.css, "气泡CSS", "自定义样式", _editCss),
    ]),

    const SizedBox(height: 20),
  ];

  Widget _oTab() => Column(
    children: [
      // 心声区块
      _expandSection("心声", Icons.favorite_outline, [
        _sw(
          "顶部显示情绪",
          widget.role.showEmotionInBar,
          (v) => setState(() => widget.role.showEmotionInBar = v),
        ),
        const SizedBox(height: 12),
        const Text(
          "心声生成频率",
          style: TextStyle(fontSize: 13, color: Colors.white54),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Stack(
            children: [
              // 滑动背景块
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment(
                  widget.role.heartUpdateMode == "每次"
                      ? -1
                      : widget.role.heartUpdateMode == "每3条"
                      ? 0
                      : 1,
                  0,
                ),
                child: FractionallySizedBox(
                  widthFactor: 1 / 3,
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 选项文字
              Row(
                children:
                    ["每次", "每3条", "每5条"].map((opt) {
                      final selected = widget.role.heartUpdateMode == opt;
                      return Expanded(
                        child: GestureDetector(
                          onTap:
                              () => setState(
                                () => widget.role.heartUpdateMode = opt,
                              ),
                          child: Center(
                            child: Text(
                              opt,
                              style: TextStyle(
                                fontSize: 13,
                                color: selected ? Colors.white : Colors.white38,
                                fontWeight:
                                    selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "每N条时只在该条对话才生成心声，节省API额度",
          style: TextStyle(fontSize: 11, color: Colors.white38),
        ),
      ]),
      const SizedBox(height: 8),

      // 对话区块
      _expandSection("对话", Icons.chat_outlined, [
        _sw(
          "线下模式",
          widget.role.isOfflineMode,
          (v) => setState(() => widget.role.isOfflineMode = v),
        ),
        const Text(
          "开启后AI会加入动作描写和场景叙述",
          style: TextStyle(fontSize: 11, color: Colors.white38),
        ),
        if (widget.role.isOfflineMode) ...[
          const SizedBox(height: 12),
          const Text(
            "输出方式",
            style: TextStyle(fontSize: 13, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                [
                  {
                    "opt": "一段式",
                    "icon": Icons.density_large_rounded,
                    "desc": "混合输出",
                  },
                  {
                    "opt": "分段式",
                    "icon": Icons.view_stream_rounded,
                    "desc": "气泡交替",
                  },
                ].map((item) {
                  final opt = item["opt"] as String;
                  final icon = item["icon"] as IconData;
                  final desc = item["desc"] as String;
                  final selected = widget.role.offlineOutputMode == opt;
                  return GestureDetector(
                    onTap:
                        () =>
                            setState(() => widget.role.offlineOutputMode = opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 130,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            selected
                                ? Colors.blueAccent.withOpacity(0.12)
                                : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              selected
                                  ? Colors.blueAccent.withOpacity(0.6)
                                  : Colors.white12,
                          width: selected ? 1.5 : 1,
                        ),
                        boxShadow:
                            selected
                                ? [
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.2),
                                    blurRadius: 16,
                                    spreadRadius: 1,
                                  ),
                                ]
                                : [],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 24,
                            color:
                                selected ? Colors.blueAccent : Colors.white38,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            opt,
                            style: TextStyle(
                              fontSize: 13,
                              color: selected ? Colors.white : Colors.white38,
                              fontWeight:
                                  selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            desc,
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  selected
                                      ? Colors.blueAccent.withOpacity(0.7)
                                      : Colors.white24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 4),
          Text(
            widget.role.offlineOutputMode == "一段式"
                ? "动作、环境、对话混合在一段话里输出"
                : "动作一个气泡，对话一个气泡，交替出现",
            style: const TextStyle(fontSize: 11, color: Colors.white38),
          ),
        ],
        const SizedBox(height: 12),
        _sw(
          "回复长度偏好",
          widget.role.replyLengthEnabled,
          (v) => setState(() => widget.role.replyLengthEnabled = v),
        ),
        if (widget.role.replyLengthEnabled) ...[
          const SizedBox(height: 8),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:
                    ["短", "适中", "详细"].map((opt) {
                      final selected = widget.role.replyLength == opt;
                      return GestureDetector(
                        onTap:
                            () => setState(() => widget.role.replyLength = opt),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              opt,
                              style: TextStyle(
                                fontSize: 13,
                                color: selected ? Colors.white : Colors.white38,
                                fontWeight:
                                    selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 2,
                              width: 30,
                              decoration: BoxDecoration(
                                color:
                                    selected
                                        ? Colors.blueAccent
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(1),
                                boxShadow:
                                    selected
                                        ? [
                                          BoxShadow(
                                            color: Colors.blueAccent
                                                .withOpacity(0.6),
                                            blurRadius: 6,
                                          ),
                                        ]
                                        : [],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ],
      ]),
      const SizedBox(height: 8),

      // 记忆区块
      _expandSection("记忆", Icons.memory_outlined, [
        Row(
          children: [
            const Text(
              "短期记忆条数",
              style: TextStyle(fontSize: 13, color: Colors.white54),
            ),
            const Spacer(),
            SizedBox(
              width: 70,
              child: TextField(
                keyboardType: TextInputType.number,
                controller: TextEditingController(
                  text: widget.role.memoryCount.toString(),
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixText: "条",
                ),
                onChanged:
                    (v) => widget.role.memoryCount = int.tryParse(v) ?? 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "AI只读取最近N条消息，数字越大越慢",
          style: TextStyle(fontSize: 11, color: Colors.white38),
        ),
        const SizedBox(height: 16),
        const Text(
          "长期记忆",
          style: TextStyle(fontSize: 13, color: Colors.white54),
        ),
        const SizedBox(height: 4),
        const Text(
          "写入后AI每次都会读取，适合存重要设定",
          style: TextStyle(fontSize: 11, color: Colors.white38),
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: 5,
          controller: TextEditingController(text: widget.role.longTermMemory),
          decoration: InputDecoration(
            hintText: "例如：我们是很好的朋友...",
            hintStyle: const TextStyle(fontSize: 12, color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (v) => widget.role.longTermMemory = v,
        ),
      ]),
      const SizedBox(height: 8),

      // 其他区块
      _expandSection("其他", Icons.tune_outlined, [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "敏感词过滤",
              style: TextStyle(fontSize: 13, color: Colors.white54),
            ),
            TextButton(
              onPressed: _editSensitiveWords,
              child: Text(
                widget.role.sensitiveWords.isEmpty
                    ? "未设置"
                    : "${widget.role.sensitiveWords.length} 个词",
                style: const TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.15),
              side: const BorderSide(color: Colors.redAccent, width: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _del,
            child: const Text(
              "删除角色",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 20),
    ],
  );
  // 行内展开区块
  Widget _expandSection(String title, IconData icon, List<Widget> children) {
    return _ExpandSection(title: title, icon: icon, children: children);
  }

  // 滑条行（占位用）
  Widget _sliderRow(
    String label,
    double value,
    double min,
    double max,
    Function(double)? onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.white54),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: Colors.blueAccent,
          onChanged: onChanged ?? (_) {},
        ),
      ],
    );
  }

  Widget _sw(String t, bool v, Function(bool) o) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [Text(t), Switch(value: v, onChanged: o)],
  );
  Widget _dr(String t, String v, List<String> i, Function(String?) o) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(t),
      DropdownButton<String>(
        value: i.contains(v) ? v : null,
        items:
            i.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: o,
      ),
    ],
  );
  Widget _fld(String l, String v, Function(String) o) => TextField(
    controller: TextEditingController(text: v),
    decoration: InputDecoration(labelText: l),
    onChanged: o,
  );
  Widget _sld(String t, double v, Function(double) o) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(t),
      Slider(value: v, activeColor: Colors.blueAccent, onChanged: o),
    ],
  );
  Widget _tile(IconData i, String t, String s, VoidCallback o) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(i),
    title: Text(t),
    subtitle: Text(s),
    trailing: const Icon(Icons.chevron_right),
    onTap: o,
  );
  void _editB() {
    final n = TextEditingController(text: widget.role.name),
        r = TextEditingController(text: widget.role.remark);
    showDialog(
      context: context,
      builder:
          (c) => StarThemedDialog(
            title: "改名",
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [TextField(controller: n), TextField(controller: r)],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    widget.role.name = n.text;
                    widget.role.remark = r.text;
                  });
                  Navigator.pop(c);
                },
                child: const Text("确认"),
              ),
            ],
          ),
    );
  }

  void _pickAv() async {
    final r = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (r != null) {
      final b = await r.readAsBytes();
      setState(() => widget.role.avatar = base64Encode(b));
    }
  }

  void _bg() {
    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setS) => StarThemedDialog(
                  title: "聊天背景",
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 背景选项列表
                      Row(
                        children: [
                          // 默认背景
                          GestureDetector(
                            onTap: () {
                              setS(() => widget.role.selectedBackground = "");
                              setState(() {});
                              ChatData.saveAll();
                            },
                            child: Container(
                              width: 80,
                              height: 120,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      widget.role.selectedBackground.isEmpty
                                          ? Colors.blueAccent
                                          : Colors.white24,
                                  width:
                                      widget.role.selectedBackground.isEmpty
                                          ? 2
                                          : 1,
                                ),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF00040A),
                                    Color(0xFF0D1B2A),
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  "默认",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 已上传的背景
                          ...widget.role.chatBackgrounds.asMap().entries.map((
                            entry,
                          ) {
                            final i = entry.key;
                            final bg = entry.value;
                            final isSelected =
                                widget.role.selectedBackground == bg;
                            return Stack(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setS(
                                      () => widget.role.selectedBackground = bg,
                                    );
                                    setState(() {});
                                    ChatData.saveAll();
                                  },
                                  child: Container(
                                    width: 80,
                                    height: 120,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? Colors.blueAccent
                                                : Colors.white24,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      image: DecorationImage(
                                        image: MemoryImage(base64Decode(bg)),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                // 删除按钮
                                Positioned(
                                  top: 4,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () {
                                      setS(() {
                                        widget.role.chatBackgrounds.removeAt(i);
                                        if (widget.role.selectedBackground ==
                                            bg) {
                                          widget.role.selectedBackground = "";
                                        }
                                      });
                                      setState(() {});
                                      ChatData.saveAll();
                                    },
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                          // 上传按钮（最多2张）
                          if (widget.role.chatBackgrounds.length < 2)
                            GestureDetector(
                              onTap: () async {
                                final r = await ImagePicker().pickImage(
                                  source: ImageSource.gallery,
                                );
                                if (r != null) {
                                  final b = await r.readAsBytes();
                                  final encoded = base64Encode(b);
                                  setS(() {
                                    widget.role.chatBackgrounds.add(encoded);
                                    widget.role.selectedBackground = encoded;
                                  });
                                  setState(() {});
                                  ChatData.saveAll();
                                }
                              },
                              child: Container(
                                width: 80,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white24),
                                  color: Colors.white.withOpacity(0.05),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: Colors.white38,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        "完成",
                        style: TextStyle(color: Colors.blueAccent),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  void _editCss() {
    final c = TextEditingController(text: widget.role.customBubbleCss);
    showDialog(
      context: context,
      builder:
          (ctx) => StarThemedDialog(
            title: "气泡 CSS",
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "支持标准 CSS，作用于 .bubble 类",
                  style: TextStyle(fontSize: 11, color: Colors.white38),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: c,
                  maxLines: 8,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText:
                        ".bubble {\n  background: rgba(0,255,255,0.1);\n  border-radius: 16px;\n}",
                    hintStyle: const TextStyle(
                      fontSize: 11,
                      color: Colors.white24,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "取消",
                  style: TextStyle(color: Colors.white38),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => widget.role.customBubbleCss = c.text.trim());
                  ChatData.saveAll();
                  Navigator.pop(ctx);
                },
                child: const Text("保存"),
              ),
            ],
          ),
    );
  }

  void _stickers() => showDialog(
    context: context,
    builder:
        (c) => StarThemedDialog(
          title: "表情",
          content: Row(
            children:
                [
                  1,
                  2,
                  3,
                ].map((e) => const Expanded(child: Icon(Icons.add))).toList(),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(c),
              child: const Text("完成"),
            ),
          ],
        ),
  );
  void _editSensitiveWords() {
    final c = TextEditingController(
      text: widget.role.sensitiveWords.join('\n'),
    );
    showDialog(
      context: context,
      builder:
          (ctx) => StarThemedDialog(
            title: "敏感词过滤",
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "每行一个词，AI回复中包含这些词时会自动替换为***",
                  style: TextStyle(fontSize: 11, color: Colors.white38),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: c,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: "输入敏感词\n每行一个",
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "取消",
                  style: TextStyle(color: Colors.white38),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    widget.role.sensitiveWords =
                        c.text
                            .split('\n')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();
                  });
                  ChatData.saveAll();
                  Navigator.pop(ctx);
                },
                child: const Text("保存"),
              ),
            ],
          ),
    );
  }

  void _del() {
    ChatData.roles.removeWhere((e) => e.id == widget.role.id);
    ChatData.saveAll();
    Navigator.pop(context);
    Navigator.pop(context);
  }

  Widget _bubbleColorPicker(
    String label,
    String current,
    List<Map<String, dynamic>> presets,
    bool isMe,
    Function(String) onChange,
  ) {
    final options = [
      {"name": "透明", "color": Colors.white.withOpacity(0.05)},
      {"name": "白", "color": Colors.white.withOpacity(0.15)},
      {"name": "蓝", "color": Colors.blueAccent.withOpacity(0.15)},
      {"name": "粉", "color": Colors.pinkAccent.withOpacity(0.15)},
      {"name": "绿", "color": Colors.greenAccent.withOpacity(0.15)},
      {"name": "紫", "color": Colors.purpleAccent.withOpacity(0.15)},
    ];

    // 固定功能圆：彩虹、透明度、磨砂
    final fixedCircles = [
      // 色相选择圆圈
      GestureDetector(
        onTap: () {
          double hue = 0;
          double sat = 1.0;
          double light = 0.5;
          final ctrl = TextEditingController();

          // 初始化：如果当前是十六进制颜色，解析出HSL
          try {
            if (current.startsWith('#') && current.length == 7) {
              final c = Color(int.parse(current.replaceFirst('#', '0xFF')));
              final hsl = HSLColor.fromColor(c);
              hue = hsl.hue;
              sat = hsl.saturation;
              light = hsl.lightness;
            }
          } catch (_) {}

          String toHex(double h, double s, double l) {
            final c = HSLColor.fromAHSL(1.0, h, s, l).toColor();
            return '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
          }

          ctrl.text = toHex(hue, sat, light);

          showDialog(
            context: context,
            builder:
                (ctx) => StatefulBuilder(
                  builder: (ctx, setS) {
                    return StarThemedDialog(
                      title: "选择颜色",
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 预览色块
                          Container(
                            width: double.infinity,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  HSLColor.fromAHSL(
                                    1.0,
                                    hue,
                                    sat,
                                    light,
                                  ).toColor(),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 色相条
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "色相",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          LayoutBuilder(
                            builder: (ctx, constraints) {
                              final w = constraints.maxWidth;
                              return GestureDetector(
                                onTapDown: (d) {
                                  setS(() {
                                    hue = (d.localPosition.dx / w * 360).clamp(
                                      0,
                                      360,
                                    );
                                    ctrl.text = toHex(hue, sat, light);
                                  });
                                },
                                onHorizontalDragUpdate: (d) {
                                  setS(() {
                                    hue = (d.localPosition.dx / w * 360).clamp(
                                      0,
                                      360,
                                    );
                                    ctrl.text = toHex(hue, sat, light);
                                  });
                                },
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 28,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFF0000),
                                            Color(0xFFFFFF00),
                                            Color(0xFF00FF00),
                                            Color(0xFF00FFFF),
                                            Color(0xFF0000FF),
                                            Color(0xFFFF00FF),
                                            Color(0xFFFF0000),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: (hue / 360 * w - 14).clamp(
                                        0,
                                        w - 28,
                                      ),
                                      top: 0,
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              HSLColor.fromAHSL(
                                                1.0,
                                                hue,
                                                1.0,
                                                0.5,
                                              ).toColor(),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          const SizedBox(height: 8),

                          // 饱和度条
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "饱和度",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ),
                          ),
                          Slider(
                            value: sat,
                            min: 0,
                            max: 1,
                            activeColor:
                                HSLColor.fromAHSL(1.0, hue, 1.0, 0.5).toColor(),
                            onChanged: (v) {
                              setS(() {
                                sat = v;
                                ctrl.text = toHex(hue, sat, light);
                              });
                            },
                          ),
                          const SizedBox(height: 4),

                          // 亮度条
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "亮度",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ),
                          ),
                          Slider(
                            value: light,
                            min: 0,
                            max: 1,
                            activeColor: Colors.white70,
                            onChanged: (v) {
                              setS(() {
                                light = v;
                                ctrl.text = toHex(hue, sat, light);
                              });
                            },
                          ),
                          const SizedBox(height: 8),

                          // 手动输入颜色代码
                          TextField(
                            controller: ctrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: "#FFFFFF",
                              labelText: "颜色代码",
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (v) {
                              try {
                                if (v.startsWith('#') && v.length == 7) {
                                  final c = Color(
                                    int.parse(v.replaceFirst('#', '0xFF')),
                                  );
                                  final hsl = HSLColor.fromColor(c);
                                  setS(() {
                                    hue = hsl.hue;
                                    sat = hsl.saturation;
                                    light = hsl.lightness;
                                  });
                                }
                              } catch (_) {}
                            },
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            "取消",
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final hex = toHex(hue, sat, light);
                            onChange(hex);
                            Navigator.pop(ctx);
                          },
                          child: const Text("确认"),
                        ),
                      ],
                    );
                  },
                ),
          );
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white38),
            gradient: const SweepGradient(
              colors: [
                Colors.red,
                Colors.yellow,
                Colors.green,
                Colors.blue,
                Colors.purple,
                Colors.red,
              ],
            ),
          ),
          child: const Icon(Icons.add, size: 16, color: Colors.white),
        ),
      ),
      // 透明度
      GestureDetector(
        onTap: () {
          double tempOpacity =
              isMe
                  ? widget.role.myBubbleOpacity
                  : widget.role.theirBubbleOpacity;
          showDialog(
            context: context,
            builder:
                (ctx) => StatefulBuilder(
                  builder:
                      (ctx, setS) => StarThemedDialog(
                        title: "气泡透明度",
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${(tempOpacity * 100).toStringAsFixed(0)}%",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Slider(
                              value: tempOpacity,
                              min: 0.0,
                              max: 1.0,
                              activeColor: Colors.blueAccent,
                              onChanged: (v) => setS(() => tempOpacity = v),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              "取消",
                              style: TextStyle(color: Colors.white38),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                if (isMe)
                                  widget.role.myBubbleOpacity = tempOpacity;
                                else
                                  widget.role.theirBubbleOpacity = tempOpacity;
                              });
                              ChatData.saveAll();
                              Navigator.pop(ctx);
                            },
                            child: const Text("确认"),
                          ),
                        ],
                      ),
                ),
          );
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white38),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.8),
              ],
            ),
          ),
          child: const Center(
            child: Text(
              "α",
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
        ),
      ),
      // 磨砂
      GestureDetector(
        onTap: () {
          double tempBlur =
              isMe ? widget.role.myBubbleBlur : widget.role.theirBubbleBlur;
          showDialog(
            context: context,
            builder:
                (ctx) => StatefulBuilder(
                  builder:
                      (ctx, setS) => StarThemedDialog(
                        title: "磨砂强度",
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${tempBlur.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Slider(
                              value: tempBlur,
                              min: 0.0,
                              max: 30.0,
                              activeColor: Colors.blueAccent,
                              onChanged: (v) => setS(() => tempBlur = v),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              "取消",
                              style: TextStyle(color: Colors.white38),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                if (isMe)
                                  widget.role.myBubbleBlur = tempBlur;
                                else
                                  widget.role.theirBubbleBlur = tempBlur;
                              });
                              ChatData.saveAll();
                              Navigator.pop(ctx);
                            },
                            child: const Text("确认"),
                          ),
                        ],
                      ),
                ),
          );
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white38),
            color: Colors.white.withOpacity(0.1),
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: const Center(
                child: Text(
                  "blur",
                  style: TextStyle(fontSize: 9, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 14)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder:
                        (ctx) => StarThemedDialog(
                          title: "保存预设",
                          content: const Text(
                            "将当前颜色、透明度、磨砂强度保存为预设？",
                            style: TextStyle(color: Colors.white54),
                            textAlign: TextAlign.center,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text(
                                "取消",
                                style: TextStyle(color: Colors.white38),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (presets.length >= 11) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("预设已满，请先删除一个"),
                                    ),
                                  );
                                  return;
                                }
                                setState(() {
                                  final newPreset = {
                                    "color":
                                        "preset_${DateTime.now().millisecondsSinceEpoch}",
                                    "savedColor": current,
                                    "opacity":
                                        isMe
                                            ? widget.role.myBubbleOpacity
                                            : widget.role.theirBubbleOpacity,
                                    "blur":
                                        isMe
                                            ? widget.role.myBubbleBlur
                                            : widget.role.theirBubbleBlur,
                                  };
                                  if (isMe) {
                                    widget.role.myBubblePresets = List.from(
                                      widget.role.myBubblePresets,
                                    )..add(newPreset);
                                  } else {
                                    widget.role.theirBubblePresets = List.from(
                                      widget.role.theirBubblePresets,
                                    )..add(newPreset);
                                  }
                                });
                                ChatData.saveAll();
                                Navigator.pop(ctx);
                              },
                              child: const Text("保存"),
                            ),
                          ],
                        ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    "+ 保存预设",
                    style: TextStyle(fontSize: 11, color: Colors.blueAccent),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // 默认6个颜色
              ...options.map((opt) {
                final isSelected = current == opt["name"];
                return GestureDetector(
                  onTap: () => onChange(opt["name"] as String),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: opt["color"] as Color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.blueAccent : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child:
                        isSelected
                            ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.blueAccent,
                            )
                            : null,
                  ),
                );
              }),
              // 用户预设
              ...presets.asMap().entries.map((entry) {
                final i = entry.key;
                final preset = entry.value;
                final presetId = preset["color"] as String;
                final savedColor =
                    preset.containsKey("savedColor")
                        ? preset["savedColor"] as String
                        : presetId;
                final isSelected = current == presetId;
                Color displayColor = Colors.white.withOpacity(0.15);
                try {
                  if (savedColor.startsWith('#')) {
                    displayColor = Color(
                      int.parse(savedColor.replaceFirst('#', '0xFF')),
                    );
                  } else {
                    displayColor =
                        {
                          "透明": Colors.white.withOpacity(0.05),
                          "白": Colors.white.withOpacity(0.15),
                          "蓝": Colors.blueAccent.withOpacity(0.15),
                          "粉": Colors.pinkAccent.withOpacity(0.15),
                          "绿": Colors.greenAccent.withOpacity(0.15),
                          "紫": Colors.purpleAccent.withOpacity(0.15),
                        }[savedColor] ??
                        Colors.white.withOpacity(0.15);
                  }
                } catch (_) {}
                return GestureDetector(
                  onTap: () {
                    onChange(presetId);
                    setState(() {
                      if (isMe) {
                        widget.role.myBubbleOpacity =
                            (preset["opacity"] as double);
                        widget.role.myBubbleBlur = (preset["blur"] as double);
                      } else {
                        widget.role.theirBubbleOpacity =
                            (preset["opacity"] as double);
                        widget.role.theirBubbleBlur =
                            (preset["blur"] as double);
                      }
                    });
                    ChatData.saveAll();
                  },
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder:
                          (ctx) => StarThemedDialog(
                            title: "删除预设",
                            content: const Text(
                              "确定删除这个预设吗？",
                              textAlign: TextAlign.center,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text(
                                  "取消",
                                  style: TextStyle(color: Colors.white38),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() => presets.removeAt(i));
                                  ChatData.saveAll();
                                  Navigator.pop(ctx);
                                },
                                child: const Text(
                                  "删除",
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: displayColor.withOpacity(
                        preset["opacity"] as double,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.blueAccent : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child:
                        isSelected
                            ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                            : null,
                  ),
                );
              }),
              // 固定功能圆
              ...fixedCircles,
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewBubble(String text, bool isMe) {
    final style =
        isMe ? widget.role.myBubbleStyle : widget.role.theirBubbleStyle;
    final op =
        isMe ? widget.role.myBubbleOpacity : widget.role.theirBubbleOpacity;
    Color bubbleColor;
    if (style.startsWith('#')) {
      try {
        bubbleColor = Color(
          int.parse(style.replaceFirst('#', '0xFF')),
        ).withOpacity(op);
      } catch (_) {
        bubbleColor = Colors.white.withOpacity(op * 0.2);
      }
    } else if (style.startsWith('preset_')) {
      final presetList =
          isMe ? widget.role.myBubblePresets : widget.role.theirBubblePresets;
      final preset = presetList.firstWhere(
        (p) => p["color"] == style,
        orElse: () => {},
      );
      final savedColor = preset["savedColor"] as String? ?? "";
      if (savedColor.startsWith('#')) {
        try {
          bubbleColor = Color(
            int.parse(savedColor.replaceFirst('#', '0xFF')),
          ).withOpacity(op);
        } catch (_) {
          bubbleColor = Colors.white.withOpacity(op * 0.2);
        }
      } else {
        bubbleColor =
            {
              "透明": Colors.white.withOpacity(op * 0.2),
              "白": Colors.white.withOpacity(op),
              "蓝": Colors.blueAccent.withOpacity(op),
              "粉": Colors.pinkAccent.withOpacity(op),
              "绿": Colors.greenAccent.withOpacity(op),
              "紫": Colors.purpleAccent.withOpacity(op),
            }[savedColor] ??
            Colors.white.withOpacity(op * 0.2);
      }
    } else {
      bubbleColor =
          {
            "透明": Colors.white.withOpacity(op * 0.2),
            "白": Colors.white.withOpacity(op),
            "蓝": Colors.blueAccent.withOpacity(op),
            "粉": Colors.pinkAccent.withOpacity(op),
            "绿": Colors.greenAccent.withOpacity(op),
            "紫": Colors.purpleAccent.withOpacity(op),
          }[style] ??
          Colors.white.withOpacity(op * 0.2);
    }

    final radius =
        widget.role.bubbleRadius == "方形"
            ? 6.0
            : widget.role.bubbleRadius == "微圆"
            ? 12.0
            : 18.0;

    final shadow = <BoxShadow>[
      ...({
            "轻柔": [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            "深邃": [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            "霓虹": [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.3),
                blurRadius: 12,
              ),
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.15),
                blurRadius: 24,
              ),
            ],
          }[widget.role.bubbleShadow] ??
          []),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isMe ? widget.role.myBubbleBlur : widget.role.theirBubbleBlur,
          sigmaY: isMe ? widget.role.myBubbleBlur : widget.role.theirBubbleBlur,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          constraints: const BoxConstraints(maxWidth: 200),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color:
                  widget.role.bubbleBorder == "无"
                      ? Colors.transparent
                      : Colors.white.withOpacity(
                        widget.role.bubbleBorder == "细边框" ? 0.15 : 0.4,
                      ),
              width: widget.role.bubbleBorder == "粗边框" ? 1.5 : 0.5,
            ),
            boxShadow: shadow,
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: widget.role.fontSize,
              color: (() {
                try {
                  return Color(
                    int.parse(widget.role.fontColor.replaceFirst('#', '0xFF')),
                  );
                } catch (_) {
                  return Colors.white;
                }
              }()),
            ),
          ),
        ),
      ),
    );
  }

  void _showOpeningPicker() {
    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setS) => StarThemedDialog(
                  title: "选择开场白",
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        // 不使用开场白选项
                        GestureDetector(
                          onTap: () {
                            setState(() => widget.role.selectedOpening = "");
                            ChatData.saveAll();
                            Navigator.pop(ctx);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  widget.role.selectedOpening.isEmpty
                                      ? Colors.blueAccent.withOpacity(0.1)
                                      : Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    widget.role.selectedOpening.isEmpty
                                        ? Colors.blueAccent.withOpacity(0.4)
                                        : Colors.white10,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    "不使用开场白",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                                if (widget.role.selectedOpening.isEmpty)
                                  const Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.blueAccent,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // 开场白列表
                        ...widget.role.openings.asMap().entries.map((entry) {
                          final i = entry.key;
                          final text = entry.value;
                          final isSelected =
                              widget.role.selectedOpening == text;
                          return GestureDetector(
                            onTap: () {
                              setState(
                                () => widget.role.selectedOpening = text,
                              );
                              ChatData.saveAll();
                              Navigator.pop(ctx);
                            },
                            onLongPress: () {
                              showDialog(
                                context: context,
                                builder:
                                    (ctx2) => StarThemedDialog(
                                      title: "删除开场白",
                                      content: const Text(
                                        "确定删除这条开场白吗？",
                                        textAlign: TextAlign.center,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx2),
                                          child: const Text(
                                            "取消",
                                            style: TextStyle(
                                              color: Colors.white38,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              widget.role.openings = List.from(
                                                widget.role.openings,
                                              )..removeAt(i);
                                              if (widget.role.selectedOpening ==
                                                  text) {
                                                widget.role.selectedOpening =
                                                    "";
                                              }
                                            });
                                            ChatData.saveAll();
                                            Navigator.pop(ctx2);
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text(
                                            "删除",
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Colors.blueAccent.withOpacity(0.1)
                                        : Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? Colors.blueAccent.withOpacity(0.4)
                                          : Colors.white10,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      text.split('\n').take(2).join(' '),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.white54,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.blueAccent,
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        "关闭",
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }
}

class _ExpandSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _ExpandSection({
    required this.title,
    required this.icon,
    required this.children,
  });
  @override
  State<_ExpandSection> createState() => _ExpandSectionState();
}

class _ExpandSectionState extends State<_ExpandSection> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 18, color: Colors.white54),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.children,
            ),
          ),
      ],
    );
  }
}
// --- 全新拟真语音气泡组件 ---
// --- 全新拟真语音气泡组件 (手势分离版) ---
// --- 全新拟真语音气泡组件 (QQ动态音波跳动版) ---
// 注意这里加了 with SingleTickerProviderStateMixin，这是动画的心脏
// ==================== 请粘贴在文件的最末尾（没有任何 {} 包裹的地方） ====================

class VoiceBubble extends StatefulWidget {
  final String text;
  final bool isMe;
  final Color fontColor;
  const VoiceBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.fontColor,
  });

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  bool _showText = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showText = !_showText),
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text("3\"", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
        if (_showText && widget.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              widget.text,
              style: TextStyle(fontSize: 13, color: widget.fontColor),
            ),
          ),
      ],
    );
  }
}

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
      body: IndexedStack(
        index: _idx,
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
                // --- 核心修复：调整了对齐公式和气泡宽度 ---
                AnimatedAlign(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  // 公式从 -0.75 调整为 -0.94，步长从 0.5 调整为 0.63
                  alignment: Alignment(-0.94 + (_idx * 0.63), 0),
                  child: FractionallySizedBox(
                    widthFactor: 0.22, // 稍微缩窄一点气泡，显得更精致
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(21),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
                        onTap: () => setState(() => _idx = i),
                        child: Icon(
                          icons[i],
                          size: 24,
                          // 选中的图标变成亮蓝色，未选中的是暗灰色
                          color: _idx == i ? Colors.blueAccent : Colors.white24,
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
          setState(() {
            ChatData.roles.add(
              ChatRole(
                id: roleId,
                name: n,
                persona: p,
                avatar: a,
                lastTime: DateTime.now(),
                msgs: [],
              ),
            );
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

  const MobileFrame({
    super.key,
    required this.title,
    required this.appBarOpacity,
    this.actions,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(
      title: Text(title),
      backgroundColor: Colors.black.withOpacity(appBarOpacity),
      elevation: 0,
      actions: actions,
    ),
    body: Stack(children: [const DynamicStarBackground(), child]),
  );
}

// --- Tab: 消息列表 ---
// --- [开始替换]：消息列表科技化 ---
class MsgTab extends StatelessWidget {
  final VoidCallback onRefresh;
  const MsgTab({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.symmetric(vertical: 20),
    itemCount: ChatData.roles.length,
    // 关键：中间那根极细的冷光线
    separatorBuilder:
        (context, index) => Divider(
          color: Colors.white.withOpacity(0.05),
          indent: 75, // 线条从头像文字交界处开始，不贯穿，更高级
          height: 1,
        ),
    itemBuilder:
        (ctx, i) => ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 5,
          ),
          leading: PlanetAvatar(seed: ChatData.roles[i].name),
          title: Text(
            ChatData.roles[i].remark.isEmpty
                ? ChatData.roles[i].name
                : ChatData.roles[i].remark,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              ChatData.roles[i].lastMessage,
              maxLines: 1,
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 12,
              ),
            ),
          ),
          // 这里的 trailing 换成一个小光点或时间
          trailing: Text(
            "接入中",
            style: TextStyle(
              color: Colors.cyanAccent.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => ChatRoomPage(role: ChatData.roles[i]),
                  ),
                );
              }
            });
          },
        ),
  );
}

// --- Tab: 星友列表 ---
// --- [开始替换]：星友列表科技化 ---
class FriendsTab extends StatelessWidget {
  final VoidCallback onRefresh;
  const FriendsTab({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.symmetric(vertical: 10),
    itemCount: ChatData.roles.length,
    itemBuilder:
        (ctx, i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Colors.cyanAccent.withOpacity(0.3),
                width: 2,
              ),
            ), // 侧边扫描线
          ),
          child: CyberGlassContainer(
            isMe: false,
            child: ListTile(
              leading: PlanetAvatar(seed: ChatData.roles[i].name),
              title: Text(
                ChatData.roles[i].remark.isEmpty
                    ? ChatData.roles[i].name
                    : ChatData.roles[i].remark,
                style: const TextStyle(color: Colors.white, letterSpacing: 1.2),
              ),
              subtitle: const Text(
                "ID: 已加密",
                style: TextStyle(color: Colors.white24, fontSize: 10),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.white12,
                size: 16,
              ),
              onTap: () {
                Future.delayed(const Duration(milliseconds: 150), () {
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => ChatRoomPage(role: ChatData.roles[i]),
                      ),
                    );
                  }
                });
              },
            ),
          ),
        ),
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
      padding: EdgeInsets.zero,
      children: [
        // 1. 顶部科技感背景
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.cyanAccent.withOpacity(0.15), Colors.transparent],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 20,
                left: 20,
                child: Row(
                  children: [
                    ChatData.userAvatar.isEmpty
                        ? PlanetAvatar(
                          seed: ChatData.userName,
                        ) // 这里传我的名字 如果没头像，显示星星
                        : CircleAvatar(
                          radius: 35,
                          backgroundImage: MemoryImage(
                            base64Decode(ChatData.userAvatar),
                          ),
                        ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ChatData.userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ChatData.userSign,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. 心情状态 (修正了你刚才重复粘贴的地方)
        if (ChatData.userMood.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(15, 15, 15, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.mood, size: 16, color: Colors.amberAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ChatData.userMood,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // 3. 科技面板统计卡片
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
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
        const SizedBox(height: 30),
      ],
    );
  }

  // 统计卡片零件
  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: CyberGlassContainer(
        isMe: false,
        child: Column(
          children: [
            Icon(icon, color: Colors.cyanAccent, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white38),
            ),
          ],
        ),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollC.hasClients) {
        _scrollC.jumpTo(_scrollC.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) => MobileFrame(
    title: widget.role.name,

    appBarOpacity: widget.role.headerOpacity,
    actions: [
      IconButton(
        icon: const Icon(Icons.add_rounded),
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => ChatSettingsPage(role: widget.role),
              ),
            ).then((_) => setState(() {})),
      ),
    ],
    // --- 这里的代码完全替换掉你原来的整个 GestureDetector 部分 ---
    child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (_showMorePanel) {
          FocusScope.of(context).unfocus();
          setState(() => _showMorePanel = false);
        }
      },
      child: Container(
        // 这里负责聊天室的背景图
        decoration:
            widget.role.chatBackground.isEmpty
                ? null
                : BoxDecoration(
                  image: DecorationImage(
                    image: MemoryImage(
                      base64Decode(widget.role.chatBackground),
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
        child: Column(
          children: [
            // 1. 消息列表（放在最上面，占满屏幕）
            Expanded(
              child: ListView.builder(
                controller: _scrollC,
                padding: const EdgeInsets.all(15),
                itemCount: widget.role.messages.length,
                itemBuilder: (ctx, i) => _buildRow(widget.role.messages[i]),
              ),
            ),

            // 2. 如果正在加载回复，显示进度条
            if (_isT)
              const LinearProgressIndicator(
                minHeight: 1,
                color: Colors.cyanAccent,
              ),

            // 3. 更多功能面板（图片、表情包等）
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child:
                  _showMorePanel ? _buildMorePanel() : const SizedBox.shrink(),
            ),

            // 4. 高透玻璃输入框（放在最底部）
            // --- 优化：极窄悬浮胶囊输入框 ---
            Container(
              padding: const EdgeInsets.fromLTRB(
                15,
                0,
                15,
                15,
              ), // 减小顶部距离，保持底部悬浮
              child: CyberGlassContainer(
                isMe: false,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 45), // 强制限制最大高度
                  child: Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact, // 紧凑模式
                        icon: Icon(
                          _showMorePanel
                              ? Icons.close_rounded
                              : Icons.add_circle_outline,
                          color: Colors.cyanAccent,
                          size: 20,
                        ),
                        onPressed: _toggleMorePanel,
                      ),
                      Expanded(
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
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10,
                            ), // 修正内部偏移
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.cyanAccent,
                          size: 20,
                        ),
                        onPressed: _send,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.auto_awesome,
                          color: Colors.amberAccent,
                          size: 20,
                        ),
                        onPressed: _reply,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
      final msg = <String, String>{"role": "user", "text": text, "kind": kind};
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
                        widget.role.isOfflineMode
                            ? "你正在与用户进行线下真实互动。回复格式规则：动作描写、环境描写、心理活动、对{{user}}的观察全部用（）括号包裹；对话文字直接输出不加括号。括号内容和对话内容交替出现，不要混在同一段里。"
                            : "你正在与用户进行线上聊天（类似微信/QQ），只输出纯对话文字，不要任何动作描写、旁白或场景描述。";
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
                    return "扮演【${widget.role.name}】。${widget.role.longTermMemory.isNotEmpty ? '\n\n【长期记忆】\n${widget.role.longTermMemory}' : ''} $modePrompt$lengthPrompt\n\n人设：${widget.role.persona}。$wbPrompt\n\n【重要格式要求】每次回复必须严格按以下格式输出，不能省略任何部分：\n[对话]\n（你的回复内容）\n[心声]\n情绪:（一个词）\n想法:（一句话）\n感受:（对用户说话方式的感受）\n想说:（想说没说出口的话）\n状态:（当前在做什么）\n心情:（今天心情关键词）\n秘密:（有没有心事，没有就写无）\n场景:（当前所处环境）\n近事:（最近发生的事）";
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
        widget.role.messages.add({"role": "assistant", "text": seg});
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
    if (widget.role.isOfflineMode) {
      final List<String> segments = [];
      final RegExp bracketExp = RegExp(r'（[^）]*）|([^（）]+)');
      for (final match in bracketExp.allMatches(normalized)) {
        final seg = match.group(0)?.trim() ?? '';
        if (seg.isNotEmpty) segments.add(seg);
      }
      return segments.isEmpty ? [normalized] : segments;
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

  // --- [开始替换]：从这里开始选中，直到最后面的 } ---
  Widget _buildRow(Map<String, dynamic> message) {
    final isM = message['role'] == 'user';
    final t = (message['text'] ?? '').toString();
    final img = (message['image'] ?? '').toString();
    final kind = (message['kind'] ?? 'text').toString();
    final extra = (message['extra'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isM ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. 对方头像：换成了你喜欢的“线条+色块”土星小星球
          // 对方头像：传入对方的名字作为随机种子
          if (!isM && widget.role.showAvatar)
            GestureDetector(
              onTap: () => _showHeartDialog(),
              child: PlanetAvatar(seed: widget.role.name),
            ),
          if (!isM && widget.role.showAvatar) const SizedBox(width: 8),

          Flexible(
            child: GestureDetector(
              onLongPress: () => _confirmDelete(message),
              child: _bubble(
                t,
                isM,
                imageBase64: img,
                kind: kind,
                extra: extra,
              ),
            ),
          ),

          if (isM && widget.role.showAvatar) const SizedBox(width: 8),
          // 2. 我方头像：也统一换成小星球（或者你可以保留你原本的头像）
          // 我方头像：传入我的名字作为随机种子
          if (isM && widget.role.showAvatar)
            PlanetAvatar(seed: ChatData.userName),
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
        if (!hideText && t.isNotEmpty)
          Text(
            t,
            style: TextStyle(
              fontSize: widget.role.fontSize,
              color: Color(
                int.parse(widget.role.fontColor.replaceFirst('#', '0xFF')),
              ),
            ),
          ),
      ],
    );

    // 2. 判断是否需要带背景气泡（表情包、纯图片、纯语音不需要气泡框）
    bool standalone =
        (hasImg && t.isEmpty) || kind == "voice" || kind == "sticker";

    if (standalone) {
      return contentWidget;
    }

    return CyberGlassContainer(isMe: isM, child: contentWidget);
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
                          PlanetAvatar(seed: role.name),
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
  Widget build(BuildContext context) => MobileFrame(
    title: "频率调节",
    appBarOpacity: 0.8,
    actions: [
      TextButton(
        onPressed: () {
          ChatData.saveAll();
          Navigator.pop(context);
        },
        child: const Text("保存", style: TextStyle(color: Colors.blueAccent)),
      ),
    ],
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              GestureDetector(
                onTap: _pickAv,
                child: _renderAvatar(widget.role.avatar),
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
    _fld("备注", widget.role.remark, (v) => widget.role.remark = v),
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
    _tile(Icons.emoji_emotions, "挂载表情包", "管理", _stickers),
    const Text("人设设定"),
    TextField(
      maxLines: 5,
      controller: TextEditingController(text: widget.role.persona),
      decoration: const InputDecoration(filled: true),
      onChanged: (v) => widget.role.persona = v,
    ),
  ];
  List<Widget> _bTab() => [
    _sw(
      "头像",
      widget.role.showAvatar,
      (v) => setState(() => widget.role.showAvatar = v),
    ),
    _sw(
      "气泡",
      widget.role.showBubble,
      (v) => setState(() => widget.role.showBubble = v),
    ),

    _bubbleColorPicker(
      "我的气泡",
      widget.role.myBubbleStyle,
      (v) => setState(() => widget.role.myBubbleStyle = v),
    ),
    _bubbleColorPicker(
      "TA的气泡",
      widget.role.theirBubbleStyle,
      (v) => setState(() => widget.role.theirBubbleStyle = v),
    ),
    const SizedBox(height: 8),
    Row(
      children: [
        const Text("字体颜色", style: TextStyle(fontSize: 14)),
        const Spacer(),
        SizedBox(
          width: 120,
          child: TextField(
            controller: TextEditingController(text: widget.role.fontColor),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: "#FFFFFF",
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (v) => widget.role.fontColor = v,
          ),
        ),
      ],
    ),
    _sld(
      "工具栏透明度",
      widget.role.footerOpacity,
      (v) => setState(() => widget.role.footerOpacity = v),
    ),
    // 字体大小
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "聊天字体大小: ${widget.role.fontSize.toStringAsFixed(0)}",
          style: const TextStyle(fontSize: 13),
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
    const Divider(color: Colors.white10),
    const SizedBox(height: 8),

    _tile(Icons.image, "聊天背景", "更换", _bg),
    _tile(Icons.css, "气泡CSS", "自定义样式", _editCss),
  ];
  Widget _oTab() => Column(
    children: [
      _sw(
        "顶部显示情绪",
        widget.role.showEmotionInBar,
        (v) => setState(() => widget.role.showEmotionInBar = v),
      ),
      _sw(
        "线下模式",
        widget.role.isOfflineMode,
        (v) => setState(() => widget.role.isOfflineMode = v),
      ),
      const Padding(
        padding: EdgeInsets.only(left: 4, bottom: 16),
        child: Text(
          "开启后 AI 会加入动作描写和场景叙述，关闭则只输出纯对话",
          style: TextStyle(fontSize: 11, color: Colors.white38),
        ),
      ),
      const Divider(color: Colors.white10),
      const SizedBox(height: 8),

      // 回复长度
      _sw(
        "回复长度偏好",
        widget.role.replyLengthEnabled,
        (v) => setState(() => widget.role.replyLengthEnabled = v),
      ),
      if (widget.role.replyLengthEnabled) ...[
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children:
              ["短", "适中", "详细"].map((opt) {
                final selected = widget.role.replyLength == opt;
                return GestureDetector(
                  onTap: () => setState(() => widget.role.replyLength = opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          selected
                              ? Colors.blueAccent.withValues(alpha: 0.2)
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
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
      const Divider(color: Colors.white10),
      const SizedBox(height: 8),

      // 短期记忆
      Row(
        children: [
          const Text("短期记忆条数", style: TextStyle(fontSize: 14)),
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
              onChanged: (v) => widget.role.memoryCount = int.tryParse(v) ?? 20,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      const Text(
        "AI只读取最近N条消息，数字越大越慢",
        style: TextStyle(fontSize: 11, color: Colors.white38),
      ),
      const SizedBox(height: 16),

      // 长期记忆
      const Text("长期记忆", style: TextStyle(fontSize: 14)),
      const SizedBox(height: 6),
      const Text(
        "写入后AI每次都会读取，适合存重要设定",
        style: TextStyle(fontSize: 11, color: Colors.white38),
      ),
      const SizedBox(height: 8),
      TextField(
        maxLines: 5,
        controller: TextEditingController(text: widget.role.longTermMemory),
        decoration: InputDecoration(
          hintText: "例如：她叫小星，我们在咖啡馆认识...",
          hintStyle: const TextStyle(fontSize: 12, color: Colors.white24),
          filled: true,
          fillColor: Colors.white.withOpacity(0.03),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (v) => widget.role.longTermMemory = v,
      ),
      const Divider(color: Colors.white10),
      const SizedBox(height: 8),

      // 敏感词过滤
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("敏感词过滤"),
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
      ElevatedButton(onPressed: _del, child: const Text("删除角色")),
    ],
  );
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

  void _bg() async {
    final r = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (r != null) {
      final b = await r.readAsBytes();
      setState(() => widget.role.chatBackground = base64Encode(b));
    }
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                options.map((opt) {
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
                          color:
                              isSelected ? Colors.blueAccent : Colors.white24,
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
                }).toList(),
          ),
        ],
      ),
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

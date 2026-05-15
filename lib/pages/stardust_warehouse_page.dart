import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_role.dart';
import '../models/star_bridge_api.dart';
import '../models/world_book_data.dart';
import '../widgets/visual_elements.dart';

class StardustWarehousePage extends StatefulWidget {
  const StardustWarehousePage({super.key});
  @override
  State<StardustWarehousePage> createState() => _StardustWarehousePageState();
}

class _StardustWarehousePageState extends State<StardustWarehousePage> {
  bool _loading = true;
  Map<String, int> _sizeMap = {};
  int _totalBytes = 0;

  @override
  void initState() {
    super.initState();
    _calcSizes();
  }

  void _showCleanDialog() {
    final selected = <String>{};
    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setS) => StarThemedDialog(
                  title: "清理数据",
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "选择要删除的内容：",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      _cleanItem(setS, selected, '聊天记录', '删除所有对话消息（保留角色卡）'),
                      _cleanItem(setS, selected, '图片缓存', '删除聊天图片和背景图（保留头像）'),
                      _cleanItem(setS, selected, '世界书', '删除所有世界书条目'),
                      _cleanItem(setS, selected, 'API 配置', '删除所有 API 配置'),
                      const SizedBox(height: 10),
                      const Text(
                        "⚠️ 删除后无法恢复，建议先导出备份",
                        style: TextStyle(color: Colors.redAccent, fontSize: 11),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed:
                          selected.isEmpty
                              ? null
                              : () {
                                Navigator.pop(ctx);
                                _doClean(selected);
                              },
                      child: const Text("确认清理"),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _cleanItem(
    StateSetter setS,
    Set<String> selected,
    String label,
    String desc,
  ) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 13)),
      subtitle: Text(
        desc,
        style: const TextStyle(fontSize: 11, color: Colors.white38),
      ),
      value: selected.contains(label),
      activeColor: Colors.redAccent,
      onChanged:
          (v) => setS(() {
            if (v == true) {
              selected.add(label);
            } else {
              selected.remove(label);
            }
          }),
    );
  }

  Future<void> _doClean(Set<String> selected) async {
    if (selected.contains('聊天记录')) {
      for (final role in ChatData.roles) {
        role.messages.clear();
        role.lastMessage = '';
      }
      await ChatData.saveAll();
    }
    if (selected.contains('图片缓存')) {
      for (final role in ChatData.roles) {
        role.chatBackground = '';
        for (final msg in role.messages) {
          msg.remove('image');
        }
      }
      await ChatData.saveAll();
    }
    if (selected.contains('世界书')) {
      WorldBookManager.entries.clear();
      await WorldBookManager.saveAll();
    }
    if (selected.contains('API 配置')) {
      StarBridgeData.apiList.clear();
      await StarBridgeData.saveAll();
    }
    await _calcSizes();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("清理完成")));
    }
  }

  Future<void> _calcSizes() async {
    setState(() => _loading = true);

    // 计算各部分大小（字节）
    final chatBytes =
        utf8
            .encode(json.encode(ChatData.roles.map((e) => e.toJson()).toList()))
            .length;

    final apiBytes =
        utf8
            .encode(
              json.encode(
                StarBridgeData.apiList.map((e) => e.toJson()).toList(),
              ),
            )
            .length;

    final wbBytes =
        utf8
            .encode(
              json.encode(
                WorldBookManager.entries.map((e) => e.toJson()).toList(),
              ),
            )
            .length;

    // 图片缓存（头像）
    int imgBytes = 0;
    for (final role in ChatData.roles) {
      if (role.avatar.isNotEmpty) imgBytes += role.avatar.length * 3 ~/ 4;
      if (role.chatBackground.isNotEmpty)
        imgBytes += role.chatBackground.length * 3 ~/ 4;
    }
    if (ChatData.userAvatar.isNotEmpty)
      imgBytes += ChatData.userAvatar.length * 3 ~/ 4;

    // 聊天记录里的图片
    int msgImgBytes = 0;
    for (final role in ChatData.roles) {
      for (final msg in role.messages) {
        if ((msg['image'] ?? '').isNotEmpty) {
          msgImgBytes += (msg['image'] as String).length * 3 ~/ 4;
        }
      }
    }

    setState(() {
      _sizeMap = {
        '聊天记录': chatBytes + msgImgBytes,
        '图片缓存': imgBytes,
        '世界书': wbBytes,
        'API 配置': apiBytes,
      };
      _totalBytes = _sizeMap.values.fold(0, (a, b) => a + b);
      _loading = false;
    });
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }

  // ── 导出数据 ──
  Future<void> _export(List<String> selected) async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        await Permission.manageExternalStorage.request();
      }

      final Map<String, dynamic> exportData = {};

      if (selected.contains('聊天记录')) {
        exportData['chat_roles'] =
            ChatData.roles.map((e) => e.toJson()).toList();
      }
      if (selected.contains('世界书')) {
        exportData['world_book'] =
            WorldBookManager.entries.map((e) => e.toJson()).toList();
      }
      if (selected.contains('API 配置')) {
        exportData['api_list'] =
            StarBridgeData.apiList.map((e) => e.toJson()).toList();
      }
      if (selected.contains('用户信息')) {
        exportData['user'] = {
          'name': ChatData.userName,
          'sign': ChatData.userSign,
          'mood': ChatData.userMood,
          'avatar': ChatData.userAvatar,
        };
      }

      exportData['export_time'] = DateTime.now().toIso8601String();
      exportData['version'] = '1.0';

      final jsonStr = json.encode(exportData);
      final dir =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final fileName =
          'starorbit_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonStr);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("已导出到：${file.path}")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("导出失败：$e")));
      }
    }
  }

  // ── 导入数据 ──
  Future<void> _import() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (r == null) return;

    try {
      final bytes = r.files.first.bytes!;
      final str = utf8.decode(bytes, allowMalformed: true);
      final d = json.decode(str) as Map<String, dynamic>;

      // 确认弹窗
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => StarThemedDialog(
              title: "确认导入",
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "检测到以下数据：",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  if (d.containsKey('chat_roles'))
                    _importItem(
                      "聊天记录",
                      "${(d['chat_roles'] as List).length} 个角色",
                    ),
                  if (d.containsKey('world_book'))
                    _importItem(
                      "世界书",
                      "${(d['world_book'] as List).length} 条条目",
                    ),
                  if (d.containsKey('api_list'))
                    _importItem(
                      "API 配置",
                      "${(d['api_list'] as List).length} 个配置",
                    ),
                  if (d.containsKey('user')) _importItem("用户信息", "头像、名字、签名"),
                  const SizedBox(height: 10),
                  const Text(
                    "导入会覆盖现有数据，确定继续吗？",
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    "取消",
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("确认导入"),
                ),
              ],
            ),
      );

      if (confirm != true) return;

      if (d.containsKey('chat_roles')) {
        ChatData.roles =
            (d['chat_roles'] as List).map((e) => ChatRole.fromJson(e)).toList();
        await ChatData.saveAll();
      }
      if (d.containsKey('world_book')) {
        WorldBookManager.entries =
            (d['world_book'] as List)
                .map((e) => WorldBookEntry.fromJson(e))
                .toList();
        await WorldBookManager.saveAll();
      }
      if (d.containsKey('api_list')) {
        StarBridgeData.apiList =
            (d['api_list'] as List)
                .map((e) => StarBridgeApi.fromJson(e))
                .toList();
        await StarBridgeData.saveAll();
      }
      if (d.containsKey('user')) {
        final u = d['user'] as Map<String, dynamic>;
        ChatData.userName = u['name'] ?? ChatData.userName;
        ChatData.userSign = u['sign'] ?? ChatData.userSign;
        ChatData.userMood = u['mood'] ?? ChatData.userMood;
        ChatData.userAvatar = u['avatar'] ?? ChatData.userAvatar;
        await ChatData.saveUser();
      }

      await _calcSizes();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("导入成功！")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("导入失败：$e")));
      }
    }
  }

  Widget _importItem(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 14,
          color: Colors.greenAccent,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    ),
  );

  void _showExportDialog() {
    final selected = <String>{'聊天记录', '世界书', 'API 配置', '用户信息'};
    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setS) => StarThemedDialog(
                  title: "选择导出内容",
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        ['聊天记录', '世界书', 'API 配置', '用户信息'].map((item) {
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item,
                              style: const TextStyle(fontSize: 14),
                            ),
                            value: selected.contains(item),
                            activeColor: Colors.blueAccent,
                            onChanged:
                                (v) => setS(() {
                                  if (v == true)
                                    selected.add(item);
                                  else
                                    selected.remove(item);
                                }),
                          );
                        }).toList(),
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
                        backgroundColor: Colors.blueAccent,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _export(selected.toList());
                      },
                      child: const Text("导出"),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedItems =
        _sizeMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // 限制显示最大值（假设上限 50MB）
    const maxBytes = 50 * 1024 * 1024;
    final usedRatio = (_totalBytes / maxBytes).clamp(0.0, 1.0);

    return FloatingHudFrame(
      title: "星尘仓库",
      child:
          _loading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              )
              : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── 空间概览 ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: usedRatio,
                                strokeWidth: 8,
                                backgroundColor: Colors.white10,
                                color: Colors.blueAccent,
                              ),
                              Text(
                                "${(usedRatio * 100).toStringAsFixed(0)}%",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "已用 ${_fmtSize(_totalBytes)}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "估算上限 ${_fmtSize(maxBytes)}",
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${ChatData.roles.length} 个角色 · ${ChatData.roles.fold(0, (s, r) => s + r.messages.length)} 条消息",
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 占用排行 ──
                  const Text(
                    "占用排行",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  ...sortedItems.map((entry) {
                    final ratio =
                        _totalBytes > 0 ? entry.value / _totalBytes : 0.0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                _fmtSize(entry.value),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 4,
                              backgroundColor: Colors.white10,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // ── 操作按钮 ──
                  const Text(
                    "数据管理",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 10),

                  _actionTile(
                    Icons.upload_rounded,
                    "导出数据",
                    "备份角色卡、世界书、API 配置等",
                    Colors.blueAccent,
                    _showExportDialog,
                  ),
                  const SizedBox(height: 10),
                  _actionTile(
                    Icons.download_rounded,
                    "导入数据",
                    "从备份文件恢复数据",
                    Colors.greenAccent,
                    _import,
                  ),
                  const SizedBox(height: 10),
                  _actionTile(
                    Icons.refresh_rounded,
                    "刷新统计",
                    "重新计算各模块占用大小",
                    Colors.white38,
                    _calcSizes,
                  ),
                  const SizedBox(height: 10),
                  _actionTile(
                    Icons.cleaning_services_rounded,
                    "清理数据",
                    "自定义选择删除哪部分数据",
                    Colors.redAccent,
                    _showCleanDialog,
                  ),
                ],
              ),
    );
  }

  Widget _actionTile(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color.withValues(alpha: 0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/world_book_data.dart';
import '../models/chat_role.dart';
import '../widgets/visual_elements.dart';

// ══════════════════════════════════════════════
//  主页面
// ══════════════════════════════════════════════
class WorldBookPage extends StatefulWidget {
  const WorldBookPage({super.key});
  @override
  State<WorldBookPage> createState() => _WorldBookPageState();
}

class _WorldBookPageState extends State<WorldBookPage>
    with SingleTickerProviderStateMixin {
  late TabController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return FloatingHudFrame(
      title: "世界书",
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => WorldBookEditPage(onSaved: _refresh),
                ),
              ),
        ),
      ],
      child: Column(
        children: [
          TabBar(
            controller: _tc,
            indicatorColor: Colors.blueAccent,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.white54,
            tabs: const [Tab(text: "全局共享"), Tab(text: "专属法则")],
          ),
          Expanded(
            child: TabBarView(
              controller: _tc,
              children: [_buildGlobalList(), _buildCharacterList()],
            ),
          ),
        ],
      ),
    );
  }

  // ── 全局共享列表 ──
  Widget _buildGlobalList() {
    final list = WorldBookManager.entries.where((e) => e.isGlobal).toList();
    if (list.isEmpty) {
      return const Center(
        child: Text(
          "寂静无声，宇宙尚未记录此处的法则...",
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: list.length,
      itemBuilder: (c, i) {
        final entry = list[i];
        return Opacity(
          opacity: entry.enabled ? 1.0 : 0.4,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: entry.enabled ? 0.04 : 0.02,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white10),
            ),
            child: ListTile(
              onTap: () => _showEntryDialog(entry),
              title: Text(
                entry.keyword,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: entry.enabled ? Colors.blueAccent : Colors.white38,
                ),
              ),
              subtitle: Text(
                entry.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              trailing: _toggleCircle(entry, Colors.blueAccent),
            ),
          ),
        );
      },
    );
  }

  // ── 专属法则：按角色分组 ──
  Widget _buildCharacterList() {
    final entries = WorldBookManager.entries.where((e) => !e.isGlobal).toList();
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          "尚无角色专属法则，导入角色卡后自动归档...",
          style: TextStyle(color: Colors.white38, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
    }
    final Map<String, List<WorldBookEntry>> grouped = {};
    for (final e in entries) {
      grouped.putIfAbsent(e.characterId, () => []).add(e);
    }
    String getCharName(String charId) {
      try {
        return ChatData.roles.firstWhere((r) => r.id == charId).name;
      } catch (_) {
        return charId.isEmpty ? "未知角色" : charId;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(15),
      children:
          grouped.entries.map((group) {
            return _CharacterGroupTile(
              charName: getCharName(group.key),
              characterId: group.key,
              entries: group.value,
              onRefresh: _refresh,
              onShowEntryDialog: _showEntryDialog,
            );
          }).toList(),
    );
  }

  Widget _toggleCircle(WorldBookEntry entry, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() => entry.enabled = !entry.enabled);
        WorldBookManager.saveAll();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: entry.enabled ? color : Colors.white30,
            width: 2,
          ),
          color:
              entry.enabled ? color.withValues(alpha: 0.2) : Colors.transparent,
        ),
        child: entry.enabled ? Icon(Icons.check, size: 14, color: color) : null,
      ),
    );
  }

  void _showEntryDialog(WorldBookEntry entry) {
    showDialog(
      context: context,
      builder:
          (ctx) => _EntryEditDialog(
            entry: entry,
            onSaved: _refresh,
            onDeleted: _refresh,
          ),
    );
  }
}

// ══════════════════════════════════════════════
//  角色分组折叠卡片
// ══════════════════════════════════════════════
class _CharacterGroupTile extends StatefulWidget {
  final String charName;
  final String characterId;
  final List<WorldBookEntry> entries;
  final VoidCallback onRefresh;
  final Function(WorldBookEntry) onShowEntryDialog;

  const _CharacterGroupTile({
    required this.charName,
    required this.characterId,
    required this.entries,
    required this.onRefresh,
    required this.onShowEntryDialog,
  });

  @override
  State<_CharacterGroupTile> createState() => _CharacterGroupTileState();
}

class _CharacterGroupTileState extends State<_CharacterGroupTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (c) => CharacterRulesPage(
                          charName: widget.charName,
                          characterId: widget.characterId,
                          onRefresh: widget.onRefresh,
                        ),
                  ),
                ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.purpleAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.charName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purpleAccent,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    "${widget.entries.length} 条法则",
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            ...widget.entries.map(
              (entry) => Column(
                children: [
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    onTap: () => widget.onShowEntryDialog(entry),
                    title: Text(
                      entry.keyword,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    subtitle: Text(
                      entry.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                    trailing: GestureDetector(
                      onTap: () {
                        setState(() => entry.enabled = !entry.enabled);
                        WorldBookManager.saveAll();
                        widget.onRefresh();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                entry.enabled
                                    ? Colors.purpleAccent
                                    : Colors.white30,
                            width: 2,
                          ),
                          color:
                              entry.enabled
                                  ? Colors.purpleAccent.withValues(alpha: 0.2)
                                  : Colors.transparent,
                        ),
                        child:
                            entry.enabled
                                ? const Icon(
                                  Icons.check,
                                  size: 13,
                                  color: Colors.purpleAccent,
                                )
                                : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
//  角色法则页
// ══════════════════════════════════════════════
class CharacterRulesPage extends StatefulWidget {
  final String charName;
  final String characterId;
  final VoidCallback onRefresh;

  const CharacterRulesPage({
    super.key,
    required this.charName,
    required this.characterId,
    required this.onRefresh,
  });

  @override
  State<CharacterRulesPage> createState() => _CharacterRulesPageState();
}

class _CharacterRulesPageState extends State<CharacterRulesPage> {
  List<WorldBookEntry> get _entries =>
      WorldBookManager.entries
          .where((e) => e.characterId == widget.characterId)
          .toList();

  void _refresh() {
    setState(() {});
    widget.onRefresh();
  }

  void _showEntryDialog(WorldBookEntry entry) {
    showDialog(
      context: context,
      builder:
          (ctx) => _EntryEditDialog(
            entry: entry,
            onSaved: _refresh,
            onDeleted: _refresh,
          ),
    );
  }

  void _showBatchManager() {
    showDialog(
      context: context,
      builder:
          (ctx) => StarThemedDialog(
            title: "批量管理",
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _batchBtn(
                  ctx,
                  Icons.upload_file,
                  "导入世界书",
                  Colors.blueAccent,
                  _importEntries,
                ),
                const SizedBox(height: 12),
                _batchBtn(
                  ctx,
                  Icons.add_circle_outline,
                  "新增条目",
                  Colors.greenAccent,
                  () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (c) => WorldBookEditPage(
                              onSaved: _refresh,
                              presetCharacterId: widget.characterId,
                              presetCharacterName: widget.charName,
                            ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _batchBtn(
                  ctx,
                  Icons.delete_sweep_outlined,
                  "批量删除全部",
                  Colors.redAccent,
                  () => _confirmDeleteAll(ctx),
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
            ],
          ),
    );
  }

  Widget _batchBtn(
    BuildContext ctx,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: color, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Future<void> _importEntries() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (r == null) return;
    final bytes = r.files.first.bytes!;
    final str = utf8.decode(bytes, allowMalformed: true);
    try {
      final d = json.decode(str);
      final cb = d['data']?['character_book'] ?? d;
      final cbEntries = cb['entries'];
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
          if (content.toString().isNotEmpty) {
            WorldBookManager.entries.add(
              WorldBookEntry(
                id: '${DateTime.now().millisecondsSinceEpoch}_$ei',
                keyword: keyword,
                content: content.toString(),
                isGlobal: false,
                characterId: widget.characterId,
                enabled: val['enabled'] ?? true,
              ),
            );
          }
        }
        WorldBookManager.saveAll();
        _refresh();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("导入成功")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("导入失败，请检查文件格式")));
      }
    }
  }

  void _confirmDeleteAll(BuildContext dialogCtx) {
    Navigator.pop(dialogCtx);
    showDialog(
      context: context,
      builder:
          (ctx) => StarThemedDialog(
            title: "批量删除",
            content: Text(
              "确定删除「${widget.charName}」的全部 ${_entries.length} 条法则吗？",
              style: const TextStyle(color: Colors.white70),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () {
                  WorldBookManager.entries.removeWhere(
                    (e) => e.characterId == widget.characterId,
                  );
                  WorldBookManager.saveAll();
                  _refresh();
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text("删除"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _entries;
    return FloatingHudFrame(
      title: "${widget.charName} 法则",
      actions: [
        TextButton(
          onPressed: _showBatchManager,
          child: const Text(
            "批量管理",
            style: TextStyle(color: Colors.purpleAccent, fontSize: 13),
          ),
        ),
      ],
      child:
          list.isEmpty
              ? const Center(
                child: Text(
                  "此角色尚无专属法则...",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: list.length,
                itemBuilder: (c, i) {
                  final entry = list[i];
                  return Opacity(
                    opacity: entry.enabled ? 1.0 : 0.4,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.purpleAccent.withValues(alpha: 0.15),
                        ),
                      ),
                      child: ListTile(
                        onTap: () => _showEntryDialog(entry),
                        title: Text(
                          entry.keyword,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                entry.enabled
                                    ? Colors.purpleAccent
                                    : Colors.white38,
                          ),
                        ),
                        subtitle: Text(
                          entry.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() => entry.enabled = !entry.enabled);
                                WorldBookManager.saveAll();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        entry.enabled
                                            ? Colors.purpleAccent
                                            : Colors.white30,
                                    width: 2,
                                  ),
                                  color:
                                      entry.enabled
                                          ? Colors.purpleAccent.withValues(
                                            alpha: 0.2,
                                          )
                                          : Colors.transparent,
                                ),
                                child:
                                    entry.enabled
                                        ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.purpleAccent,
                                        )
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: Colors.white24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

// ══════════════════════════════════════════════
//  条目弹窗编辑
// ══════════════════════════════════════════════
class _EntryEditDialog extends StatefulWidget {
  final WorldBookEntry entry;
  final VoidCallback onSaved;
  final VoidCallback onDeleted;

  const _EntryEditDialog({
    required this.entry,
    required this.onSaved,
    required this.onDeleted,
  });

  @override
  State<_EntryEditDialog> createState() => _EntryEditDialogState();
}

class _EntryEditDialogState extends State<_EntryEditDialog> {
  late TextEditingController _kwC;
  late TextEditingController _ctC;

  @override
  void initState() {
    super.initState();
    _kwC = TextEditingController(text: widget.entry.keyword);
    _ctC = TextEditingController(text: widget.entry.content);
  }

  @override
  void dispose() {
    _kwC.dispose();
    _ctC.dispose();
    super.dispose();
  }

  void _save() {
    if (_kwC.text.trim().isEmpty || _ctC.text.trim().isEmpty) return;
    widget.entry.keyword = _kwC.text.trim();
    widget.entry.content = _ctC.text.trim();
    WorldBookManager.saveAll();
    widget.onSaved();
    Navigator.pop(context);
  }

  void _delete() {
    WorldBookManager.entries.remove(widget.entry);
    WorldBookManager.saveAll();
    widget.onDeleted();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF000B18),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
        side: const BorderSide(color: Colors.white10),
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "编辑法则",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(
                      () => widget.entry.enabled = !widget.entry.enabled,
                    );
                    WorldBookManager.saveAll();
                    widget.onSaved();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            widget.entry.enabled
                                ? Colors.blueAccent
                                : Colors.white30,
                        width: 2,
                      ),
                      color:
                          widget.entry.enabled
                              ? Colors.blueAccent.withValues(alpha: 0.2)
                              : Colors.transparent,
                    ),
                    child:
                        widget.entry.enabled
                            ? const Icon(
                              Icons.check,
                              size: 15,
                              color: Colors.blueAccent,
                            )
                            : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _kwC,
              decoration: InputDecoration(
                labelText: "触发关键词",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctC,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: "设定内容",
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.02),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 16,
                  ),
                  label: const Text(
                    "删除",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "取消",
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                    side: const BorderSide(color: Colors.blueAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _save,
                  child: const Text("保存"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
//  添加 / 编辑 页面
// ══════════════════════════════════════════════
class WorldBookEditPage extends StatefulWidget {
  final WorldBookEntry? entry;
  final VoidCallback onSaved;
  final String? presetCharacterId;
  final String? presetCharacterName;

  const WorldBookEditPage({
    super.key,
    this.entry,
    required this.onSaved,
    this.presetCharacterId,
    this.presetCharacterName,
  });

  @override
  State<WorldBookEditPage> createState() => _WBEPState();
}

class _WBEPState extends State<WorldBookEditPage> {
  bool _isGlobal = true;
  String _characterId = '';
  String _characterName = '';
  final _kwC = TextEditingController();
  final _ctC = TextEditingController();
  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _isGlobal = widget.entry!.isGlobal;
      _kwC.text = widget.entry!.keyword;
      _ctC.text = widget.entry!.content;
      _characterId = widget.entry!.characterId;
      try {
        _characterName =
            ChatData.roles.firstWhere((r) => r.id == _characterId).name;
      } catch (_) {}
    } else if (widget.presetCharacterId != null) {
      _isGlobal = false;
      _characterId = widget.presetCharacterId!;
      _characterName = widget.presetCharacterName ?? '';
    }
  }

  @override
  void dispose() {
    _kwC.dispose();
    _ctC.dispose();
    super.dispose();
  }

  void _save() {
    if (_kwC.text.trim().isEmpty || _ctC.text.trim().isEmpty) return;
    if (!_isEditing) {
      WorldBookManager.entries.add(
        WorldBookEntry(
          id: DateTime.now().toString(),
          keyword: _kwC.text.trim(),
          content: _ctC.text.trim(),
          isGlobal: _isGlobal,
          characterId: _characterId,
        ),
      );
    } else {
      widget.entry!.keyword = _kwC.text.trim();
      widget.entry!.content = _ctC.text.trim();
      widget.entry!.isGlobal = _isGlobal;
      widget.entry!.characterId = _characterId;
    }
    WorldBookManager.saveAll();
    widget.onSaved();
    Navigator.pop(context);
  }

  void _delete() {
    showDialog(
      context: context,
      builder:
          (ctx) => StarThemedDialog(
            title: "删除法则",
            content: Text(
              "确定要删除「${widget.entry!.keyword}」吗？",
              style: const TextStyle(color: Colors.white70),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () {
                  WorldBookManager.entries.remove(widget.entry);
                  WorldBookManager.saveAll();
                  widget.onSaved();
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text("删除"),
              ),
            ],
          ),
    );
  }

  Future<void> _import() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'json'],
    );
    if (r != null) {
      final bytes = r.files.first.bytes!;
      final str = utf8.decode(bytes, allowMalformed: true);
      setState(() => _ctC.text = str);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("导入成功")));
      }
    }
  }

  Future<void> _pickCharacter() async {
    if (ChatData.roles.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("还没有导入任何角色")));
      return;
    }
    final selected = await showDialog<ChatRole>(
      context: context,
      builder:
          (ctx) => StarThemedDialog(
            title: "关联角色",
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: ChatData.roles.length + 1,
                itemBuilder: (c, i) {
                  if (i == 0) {
                    return ListTile(
                      leading: const Icon(
                        Icons.public,
                        color: Colors.blueAccent,
                      ),
                      title: const Text("不绑定（全局）"),
                      onTap: () => Navigator.pop(ctx, null),
                    );
                  }
                  final role = ChatData.roles[i - 1];
                  return ListTile(
                    leading: const Icon(
                      Icons.person,
                      color: Colors.purpleAccent,
                    ),
                    title: Text(role.name),
                    subtitle: role.remark.isNotEmpty ? Text(role.remark) : null,
                    onTap: () => Navigator.pop(ctx, role),
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
    if (!mounted) return;
    setState(() {
      if (selected == null) {
        _characterId = '';
        _characterName = '';
        _isGlobal = true;
      } else {
        _characterId = selected.id;
        _characterName = selected.name;
        _isGlobal = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FloatingHudFrame(
      title: _isEditing ? "修改法则" : "缔造世界法则",
      actions: [
        if (_isEditing)
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 20,
            ),
            onPressed: _delete,
          ),
        TextButton(
          onPressed: _save,
          child: const Text(
            "保存",
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_isEditing) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_note,
                    size: 16,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "编辑模式",
                    style: TextStyle(color: Colors.blueAccent, fontSize: 12),
                  ),
                  if (!_isGlobal && _characterName.isNotEmpty) ...[
                    const Spacer(),
                    const Icon(Icons.link, size: 13, color: Colors.white38),
                    const SizedBox(width: 4),
                    Text(
                      _characterName,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // 属性归属
          Row(
            children: [
              const Expanded(
                child: Text("属性归属", style: TextStyle(color: Colors.white70)),
              ),
              ChoiceChip(
                label: const Text("全局共享"),
                selected: _isGlobal,
                selectedColor: Colors.blueAccent.withValues(alpha: 0.3),
                onSelected:
                    (v) => setState(() {
                      _isGlobal = true;
                      _characterId = '';
                      _characterName = '';
                    }),
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text("专属设定"),
                selected: !_isGlobal,
                selectedColor: Colors.purpleAccent.withValues(alpha: 0.3),
                onSelected: (v) => setState(() => _isGlobal = false),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 关联角色
          Opacity(
            opacity: _isGlobal ? 0.35 : 1.0,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _isGlobal ? null : _pickCharacter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        _characterId.isEmpty
                            ? Colors.white24
                            : Colors.purpleAccent.withValues(alpha: 0.5),
                  ),
                  color:
                      _characterId.isEmpty
                          ? Colors.transparent
                          : Colors.purpleAccent.withValues(alpha: 0.06),
                ),
                child: Row(
                  children: [
                    Icon(
                      _characterId.isEmpty ? Icons.link_off : Icons.link,
                      size: 18,
                      color:
                          _characterId.isEmpty
                              ? Colors.white38
                              : Colors.purpleAccent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isGlobal
                            ? "全局共享无需关联角色"
                            : (_characterId.isEmpty
                                ? "点击关联角色（可选）"
                                : "已关联：$_characterName"),
                        style: TextStyle(
                          color:
                              _isGlobal
                                  ? Colors.white24
                                  : (_characterId.isEmpty
                                      ? Colors.white38
                                      : Colors.purpleAccent),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (!_isGlobal)
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Colors.white24,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 关键词
          TextField(
            controller: _kwC,
            decoration: InputDecoration(
              labelText: "法则关键词（名字）",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // 设定内容
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("设定内容", style: TextStyle(color: Colors.white70)),
              TextButton.icon(
                onPressed: _import,
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text("本地导入"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctC,
            maxLines: 12,
            decoration: InputDecoration(
              hintText: "在此输入世界设定...",
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.02),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          if (_isEditing) ...[
            const SizedBox(height: 30),
            const Divider(color: Colors.white10),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _delete,
                icon: const Icon(
                  Icons.delete_forever,
                  color: Colors.redAccent,
                  size: 18,
                ),
                label: const Text(
                  "删除此法则",
                  style: TextStyle(color: Colors.redAccent),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../models/star_bridge_api.dart';
import '../widgets/visual_elements.dart';

class StarBridgePage extends StatelessWidget {
  const StarBridgePage({super.key});
  @override
  Widget build(BuildContext context) => FloatingHudFrame(
    title: "星桥",
    child: ListView(
      padding: const EdgeInsets.all(25),
      children: [
        _menu(context, "我的配置", "手动录入 API 与预设管理", const MyConfigsPage()),
        const SizedBox(height: 15),
        _menu(context, "提供商", "官方源快捷连接 (维护中)", const ApiProvidersPage()),
      ],
    ),
  );

  Widget _menu(BuildContext ctx, String t, String s, Widget? p) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.02),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
    ),
    child: ListTile(
      title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        s,
        style: const TextStyle(fontSize: 10, color: Colors.white38),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
      onTap: () {
        if (p != null)
          Navigator.push(ctx, MaterialPageRoute(builder: (c) => p));
      },
    ),
  );
}

// --- 提供商页面 (仅占位) ---
class ApiProvidersPage extends StatelessWidget {
  const ApiProvidersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingHudFrame(
      title: "官方提供商",
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_bottom_rounded,
              size: 64,
              color: Colors.blueAccent.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            const Text(
              "维度链路同步中",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "官方直连通道正在进行协议升级，请暂时前往【我的配置】手动录入您的 API 密钥。",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 我的配置页面 (核心功能区) ---
class MyConfigsPage extends StatefulWidget {
  const MyConfigsPage({super.key});
  @override
  State<MyConfigsPage> createState() => _MCPState();
}

class _MCPState extends State<MyConfigsPage> {
  StarBridgeApi get _curDefault =>
      StarBridgeData.apiList.isNotEmpty
          ? StarBridgeData.apiList.firstWhere(
            (e) => e.isDefault,
            orElse: () => StarBridgeData.apiList.first,
          )
          : StarBridgeApi(id: "new", name: "", url: "https://", key: "");
  late StarBridgeApi _cur;
  final _uC = TextEditingController();
  final _kC = TextEditingController();
  final _mC = TextEditingController();
  final _mgC = TextEditingController();
  final _mkC = TextEditingController();
  final _navKeyC = TextEditingController();
  final _navModelC = TextEditingController();
  final _nC = TextEditingController();
  bool _isP = false;
  List<String> _fetchedModels = [];

  @override
  void initState() {
    super.initState();
    _cur = _curDefault;
    _sync();
  }

  void _sync() {
    _uC.text = _cur.url;
    _kC.text = _cur.key;
    _mC.text = _cur.selectedModel;
    _navKeyC.text = _cur.novelAiKey;
    _navModelC.text = _cur.novelAiModel;
    _nC.text = _cur.name;
  }

  @override
  Widget build(BuildContext context) {
    return FloatingHudFrame(
      title: "API 高级设置",
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  " 预设方案管理",
                  style: TextStyle(fontSize: 14, color: Colors.white54),
                ),
                const SizedBox(height: 10),
                _dropdown(),
                const SizedBox(height: 25),

                _sectionHead(" 云端大脑 (LLM API)"),
                MoeCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _in(
                        _uC,
                        "反代地址 (Proxy)",
                        "https://api.openai.com",
                        (v) => _cur.url = v,
                      ),
                      _in(
                        _kC,
                        "密钥 (API Key)",
                        "sk-...",
                        (v) => _cur.key = v,
                        isK: true,
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "当前模型",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white30,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _mC,
                                onChanged: (v) => _cur.selectedModel = v,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: "手动输入或拉取列表",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  suffixIcon:
                                      _fetchedModels.isNotEmpty
                                          ? PopupMenuButton<String>(
                                            constraints: BoxConstraints(
                                              minWidth: constraints.maxWidth,
                                            ),
                                            icon: const Icon(
                                              Icons
                                                  .arrow_drop_down_circle_outlined,
                                              color: Colors.blueAccent,
                                            ),
                                            offset: const Offset(0, 50),
                                            color: const Color(0xFF0D1B2A),
                                            onSelected: (val) {
                                              setState(() {
                                                _mC.text = val;
                                                _cur.selectedModel = val;
                                              });
                                            },
                                            itemBuilder:
                                                (ctx) =>
                                                    _fetchedModels
                                                        .map(
                                                          (m) => PopupMenuItem(
                                                            value: m,
                                                            child: Text(
                                                              m,
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    Colors
                                                                        .white70,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                          )
                                          : null,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child:
                                    _isP
                                        ? const Padding(
                                          padding: EdgeInsets.all(10),
                                          child: CupertinoActivityIndicator(
                                            radius: 7,
                                          ),
                                        )
                                        : TextButton.icon(
                                          onPressed: _pull,
                                          icon: const Icon(
                                            Icons.satellite_alt_outlined,
                                            size: 14,
                                          ),
                                          label: Text(
                                            _fetchedModels.isEmpty
                                                ? "拉取模型"
                                                : "刷新列表",
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                              ),
                            ],
                          );
                        },
                      ),
                      _sw(
                        "设为当前默认连接",
                        _cur.isDefault,
                        (v) => setState(() => _cur.isDefault = v),
                      ),
                      const Divider(color: Colors.white10, height: 30),
                      Text(
                        "温度 (随机性): ${_cur.temperature.toStringAsFixed(1)}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blueAccent,
                        ),
                      ),
                      Slider(
                        value: _cur.temperature,
                        min: 0,
                        max: 2,
                        activeColor: Colors.blueAccent,
                        onChanged: (v) => setState(() => _cur.temperature = v),
                      ),
                    ],
                  ),
                ),

                _sectionHead("Minimax 语音 (占位)"),
                MoeCard(
                  child: Column(
                    children: [
                      _in(
                        _mgC,
                        "Group ID",
                        "ID",
                        (v) => _cur.minimaxGroupId = v,
                      ),
                      _in(
                        _mkC,
                        "API Key",
                        "Key",
                        (v) => _cur.minimaxKey = v,
                        isK: true,
                      ),
                    ],
                  ),
                ),
                _sectionHead("图片生成 (占位)"),
                MoeCard(
                  child: Column(
                    children: [
                      _in(
                        _navKeyC,
                        "API Key",
                        "Key",
                        (v) => _cur.novelAiKey = v,
                        isK: true,
                      ),
                      _in(
                        _navModelC,
                        "模型",
                        "nai-diffusion-3",
                        (v) => _cur.novelAiModel = v,
                      ),
                    ],
                  ),
                ),
                _sectionHead("数据导出"),
                MoeCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _btn("导出 JSON", Colors.greenAccent, _export),
                      _btn("全部重置", Colors.redAccent, () {
                        StarBridgeData.apiList.clear();
                        StarBridgeData.saveAll();
                        setState(() {});
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            right: 30,
            child: FloatingActionButton.extended(
              backgroundColor: Colors.blueAccent,
              onPressed: _save,
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: const Text(
                "保存全部设置",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHead(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 10),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Colors.white70,
      ),
    ),
  );

  Widget _dropdown() => Row(
    children: [
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value:
                  StarBridgeData.apiList.any((e) => e.id == _cur.id)
                      ? _cur.id
                      : null,
              isExpanded: true,
              hint: const Text(
                "▼ 选择已有配置",
                style: TextStyle(fontSize: 13, color: Colors.white54),
              ),
              items: [
                const DropdownMenuItem(
                  value: "new",
                  child: Text(
                    "+ 新增预设方案",
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                ),
                ...StarBridgeData.apiList.map(
                  (e) => DropdownMenuItem(
                    value: e.id,
                    child: Text(e.name, style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
              onChanged:
                  (id) => setState(() {
                    if (id == "new") {
                      _cur = StarBridgeApi(
                        id: "new",
                        name: "新预设",
                        url: "https://",
                        key: "",
                      );
                    } else {
                      _cur = StarBridgeData.apiList.firstWhere(
                        (e) => e.id == id,
                      );
                    }
                    _sync();
                  }),
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: _showManageDialog,
        child: const Text(
          "管理",
          style: TextStyle(fontSize: 12, color: Colors.blueAccent),
        ),
      ),
    ],
  );

  void _showManageDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => StarThemedDialog(
            title: "管理预设",
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: StarBridgeData.apiList.length,
                itemBuilder:
                    (c, i) => ListTile(
                      title: Text(StarBridgeData.apiList[i].name),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          setState(() => StarBridgeData.apiList.removeAt(i));
                          StarBridgeData.saveAll();
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("关闭"),
              ),
            ],
          ),
    );
  }

  Widget _in(
    TextEditingController c,
    String l,
    String h,
    Function(String) o, {
    bool isK = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: TextField(
      controller: c,
      obscureText: isK,
      onChanged: o,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: l,
        hintText: h,
        labelStyle: const TextStyle(color: Colors.white30, fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
  Widget _sw(String t, bool v, Function(bool) o) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(t, style: const TextStyle(fontSize: 14)),
      Switch(value: v, activeColor: Colors.blueAccent, onChanged: o),
    ],
  );
  Widget _btn(String t, Color c, VoidCallback o) => TextButton(
    style: TextButton.styleFrom(
      backgroundColor: c.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 20),
    ),
    onPressed: o,
    child: Text(t, style: TextStyle(color: c, fontSize: 12)),
  );

  Future<void> _pull() async {
    final baseUrl = _uC.text.trim();
    final apiKey = _kC.text.trim();
    if (baseUrl.isEmpty || apiKey.isEmpty) return;
    setState(() => _isP = true);
    try {
      String finalUrl = baseUrl;
      if (!finalUrl.endsWith('/')) finalUrl += '/';
      if (!finalUrl.contains('v1/models')) finalUrl += "v1/models";
      final res = await http
          .get(
            Uri.parse(finalUrl),
            headers: {"Authorization": "Bearer $apiKey"},
          )
          .timeout(const Duration(seconds: 25));
      if (res.statusCode == 200) {
        final List list = json.decode(res.body)['data'] ?? [];
        if (list.isNotEmpty)
          setState(() {
            _fetchedModels = list.map((e) => e['id'].toString()).toList();
          });
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isP = false);
    }
  }

  void _save() {
    if (_cur.id == "new")
      _cur.id = DateTime.now().millisecondsSinceEpoch.toString();
    _cur.name = "配置-${DateTime.now().minute}:${DateTime.now().second}";
    int idx = StarBridgeData.apiList.indexWhere((e) => e.id == _cur.id);
    if (idx != -1)
      StarBridgeData.apiList[idx] = _cur;
    else
      StarBridgeData.apiList.add(_cur);
    if (_cur.isDefault) {
      for (var e in StarBridgeData.apiList) {
        if (e.id != _cur.id) e.isDefault = false;
      }
    }
    StarBridgeData.saveAll();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("✨ 预设已成功同步至星尘")));
  }

  void _export() {
    final data = json.encode(
      StarBridgeData.apiList.map((e) => e.toJson()).toList(),
    );
    showDialog(
      context: context,
      builder:
          (c) => StarThemedDialog(
            title: "导出成功",
            content: SelectableText(data),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(c),
                child: const Text("返回"),
              ),
            ],
          ),
    );
  }
}

class MoeCard extends StatelessWidget {
  final Widget child;
  const MoeCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.02),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white10),
    ),
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 15),
    child: child,
  );
}

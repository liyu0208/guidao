import 'package:flutter/material.dart';
import '../widgets/visual_elements.dart'; // 修正：补上引用
import 'star_bridge_page.dart';
import 'stardust_warehouse_page.dart';

class CoreCabinPage extends StatelessWidget {
  const CoreCabinPage({super.key});
  @override
  Widget build(BuildContext context) => FloatingHudFrame(
    title: "核心舱控制中心",
    child: ListView(
      padding: const EdgeInsets.all(20),
children: [
  _item(context, Icons.lan_rounded, "星桥", "API 与模型管理", const StarBridgePage()),
  _item(context, Icons.storage_rounded, "星尘仓库", "存储与数据管理", const StardustWarehousePage()),
  _item(context, Icons.tune_rounded, "其他设置", "通用偏好与系统配置", null),
],
    ),
  );
  Widget _item(BuildContext ctx, IconData i, String t, String s, Widget? p) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: ListTile(
          leading: Icon(i, color: Colors.blueAccent),
          title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            s,
            style: const TextStyle(fontSize: 11, color: Colors.white38),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
          onTap: () {
            if (p != null) {
              Navigator.push(ctx, MaterialPageRoute(builder: (c) => p));
            }
          },
        ),
      );
}

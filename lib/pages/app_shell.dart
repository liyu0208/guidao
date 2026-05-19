import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ══════════════════════════════════════════════
// 占位数据
// ══════════════════════════════════════════════
class _Post {
  final String id;
  final String userName;
  final String avatarSeed;
  final String content;
  final String timeLabel;
  final String tag;
  final Color tagColor;
  int likes;
  bool liked;
  List<_Comment> comments;
  bool showComments;

  _Post({
    required this.id,
    required this.userName,
    required this.avatarSeed,
    required this.content,
    required this.timeLabel,
    required this.tag,
    required this.tagColor,
    this.likes = 0,
    this.liked = false,
    List<_Comment>? comments,
    this.showComments = false,
  }) : comments = comments ?? [];
}

class _Comment {
  final String userName;
  final String content;
  _Comment({required this.userName, required this.content});
}

final List<_Post> _mockPosts = [
  _Post(
    id: '1',
    userName: '星轨观测者',
    avatarSeed: 'observer',
    content: '今晚的月相很美，坐在窗边发了很久的呆。有时候觉得星星比人更值得信任。',
    timeLabel: '刚刚',
    tag: '月相',
    tagColor: const Color(0xFF9BBBFF),
    likes: 12,
    comments: [
      _Comment(userName: '流星碎片', content: '深夜的星空总是最诚实的。'),
      _Comment(userName: '暗物质', content: '我也是，今晚一直看着北极星。'),
    ],
  ),
  _Post(
    id: '2',
    userName: '暗物质',
    avatarSeed: 'dark',
    content: '写了一首很短的诗：\n\n频段打开\n却不知道对谁说话\n信号在宇宙里漂着\n也许明天有人接收',
    timeLabel: '3分钟前',
    tag: '星历',
    tagColor: const Color(0xFF7DC4FF),
    likes: 28,
    liked: true,
  ),
  _Post(
    id: '3',
    userName: '流星碎片',
    avatarSeed: 'meteor',
    content: '今天的习惯打卡完成了，连续第17天。感觉自己慢慢变成了一颗稳定运行的卫星。',
    timeLabel: '14分钟前',
    tag: '星轨',
    tagColor: const Color(0xFF4D9FFF),
    likes: 6,
    comments: [
      _Comment(userName: '星轨观测者', content: '卫星加油！'),
    ],
  ),
  _Post(
    id: '4',
    userName: '白矮星残骸',
    avatarSeed: 'dwarf',
    content: '有没有人也觉得深夜说话比白天容易很多？频段里的声音总是更真实。',
    timeLabel: '32分钟前',
    tag: '动态',
    tagColor: const Color(0xFFA8C4E0),
    likes: 41,
  ),
  _Post(
    id: '5',
    userName: '引力透镜',
    avatarSeed: 'lens',
    content: '今天月相是娥眉月，查了一下说是新开始的象征。那就从今天起认真记录每一天吧。',
    timeLabel: '1小时前',
    tag: '月相',
    tagColor: const Color(0xFF9BBBFF),
    likes: 19,
  ),
];

// ══════════════════════════════════════════════
// AppShellPage 主体
// ══════════════════════════════════════════════
class AppShellPage extends StatefulWidget {
  final String title;
  const AppShellPage({super.key, required this.title});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage>
    with SingleTickerProviderStateMixin {
  final List<_Post> _posts = List.from(_mockPosts);
  final _scrollCtrl = ScrollController();
  late AnimationController _flowCtrl;
  bool _showCompose = false;
  final _composeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _flowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _flowCtrl.dispose();
    _scrollCtrl.dispose();
    _composeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── 主列表 ──────────────────────────────────────────
        CustomScrollView(
          controller: _scrollCtrl,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 顶部标题区
            SliverToBoxAdapter(child: _buildHeader()),

            // 卡片列表
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _PostCard(
                    post: _posts[i],
                    flowCtrl: _flowCtrl,
                    onLike: () => setState(() {
                      final p = _posts[i];
                      p.liked = !p.liked;
                      p.likes += p.liked ? 1 : -1;
                      HapticFeedback.lightImpact();
                    }),
                    onToggleComments: () => setState(() {
                      _posts[i].showComments = !_posts[i].showComments;
                    }),
                    onAddComment: (text) => setState(() {
                      _posts[i].comments.add(
                        _Comment(userName: '我', content: text),
                      );
                    }),
                  ),
                  childCount: _posts.length,
                ),
              ),
            ),
          ],
        ),

        // ── 发布按钮 ────────────────────────────────────────
        Positioned(
          right: 24, bottom: 24,
          child: _ComposeButton(
            onTap: () => setState(() => _showCompose = true),
            flowCtrl: _flowCtrl,
          ),
        ),

        // ── 发布面板 ────────────────────────────────────────
        if (_showCompose)
          _ComposePanel(
            controller: _composeCtrl,
            onClose: () {
              setState(() => _showCompose = false);
              _composeCtrl.clear();
            },
            onPost: () {
              if (_composeCtrl.text.trim().isEmpty) return;
              setState(() {
                _posts.insert(0, _Post(
                  id: DateTime.now().toString(),
                  userName: '我',
                  avatarSeed: 'me',
                  content: _composeCtrl.text.trim(),
                  timeLabel: '刚刚',
                  tag: '动态',
                  tagColor: const Color(0xFFA8C4E0),
                ));
                _showCompose = false;
                _composeCtrl.clear();
              });
              _scrollCtrl.animateTo(0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut);
            },
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分节标签
          Row(children: [
            Container(width: 28, height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xFF4D9FFF)],
                ),
              )),
            const SizedBox(width: 10),
            const Text("STELLAR FEED",
              style: TextStyle(
                fontSize: 9, letterSpacing: 5,
                color: Color(0xFF4D9FFF), fontWeight: FontWeight.w300,
              )),
          ]),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("动态",
                style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w200,
                  color: Colors.white, letterSpacing: 6,
                )),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text("${_posts.length} 条频段",
                  style: const TextStyle(
                    fontSize: 11, color: Color(0xFF4A6688), letterSpacing: 2,
                  )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                const Color(0xFF4D9FFF).withOpacity(0.4),
                Colors.transparent,
              ]),
            )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 单张动态卡片
// ══════════════════════════════════════════════
class _PostCard extends StatefulWidget {
  final _Post post;
  final AnimationController flowCtrl;
  final VoidCallback onLike;
  final VoidCallback onToggleComments;
  final void Function(String) onAddComment;

  const _PostCard({
    required this.post,
    required this.flowCtrl,
    required this.onLike,
    required this.onToggleComments,
    required this.onAddComment,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverCtrl;
  late Animation<double> _hoverAnim;
  final _commentCtrl = TextEditingController();
  bool _showInput = false;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350));
    _hoverAnim = CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return GestureDetector(
      onTapDown: (_) => _hoverCtrl.forward(),
      onTapUp: (_) => _hoverCtrl.reverse(),
      onTapCancel: () => _hoverCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _hoverAnim,
        builder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02 + _hoverAnim.value * 0.02),
            border: Border(
              top: BorderSide(
                color: const Color(0xFF4D9FFF)
                    .withOpacity(_hoverAnim.value * 0.6),
                width: 1,
              ),
              left: BorderSide(color: Colors.white.withOpacity(0.04)),
              right: BorderSide(color: Colors.white.withOpacity(0.04)),
              bottom: BorderSide(color: Colors.white.withOpacity(0.04)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 顶部用户行 ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(children: [
                  // 头像
                  _SeedAvatar(seed: post.avatarSeed, size: 36),
                  const SizedBox(width: 10),
                  // 名字 + 时间
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.userName,
                          style: const TextStyle(
                            fontSize: 13, color: Color(0xFFC8E0FF),
                            fontWeight: FontWeight.w300, letterSpacing: 0.5,
                          )),
                        const SizedBox(height: 2),
                        Text(post.timeLabel,
                          style: const TextStyle(
                            fontSize: 9, color: Color(0xFF4A6688),
                            letterSpacing: 0.5,
                          )),
                      ],
                    ),
                  ),
                  // 标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: post.tagColor.withOpacity(0.3), width: 0.8),
                      color: post.tagColor.withOpacity(0.06),
                    ),
                    child: Text(post.tag,
                      style: TextStyle(
                        fontSize: 8, letterSpacing: 2,
                        color: post.tagColor.withOpacity(0.8),
                        fontWeight: FontWeight.w300,
                      )),
                  ),
                ]),
              ),

              // ── 内容 ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Text(post.content,
                  style: const TextStyle(
                    fontSize: 13, color: Color(0xFFA8C4E0),
                    height: 1.7, fontWeight: FontWeight.w300,
                    letterSpacing: 0.3,
                  )),
              ),

              // ── 底部操作行 ──────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withOpacity(0.04)),
                  ),
                ),
                child: Row(children: [
                  // 点赞
                  _ActionBtn(
                    icon: post.liked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    label: "${post.likes}",
                    color: post.liked
                        ? const Color(0xFFFF6B9D)
                        : const Color(0xFF4A6688),
                    onTap: widget.onLike,
                  ),
                  const SizedBox(width: 20),
                  // 评论
                  _ActionBtn(
                    icon: Icons.chat_bubble_outline,
                    label: "${post.comments.length}",
                    color: post.showComments
                        ? const Color(0xFF4D9FFF)
                        : const Color(0xFF4A6688),
                    onTap: widget.onToggleComments,
                  ),
                  const Spacer(),
                  // 时间戳装饰
                  Text("· · ·",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.1),
                      letterSpacing: 4,
                    )),
                ]),
              ),

              // ── 评论区（展开）──────────────────────────
              if (post.showComments) ...[
                // 评论列表
                if (post.comments.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.04)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: post.comments.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${c.userName}",
                              style: const TextStyle(
                                fontSize: 11, color: Color(0xFF4D9FFF),
                                fontWeight: FontWeight.w300,
                              )),
                            const Text("  ",
                              style: TextStyle(fontSize: 11)),
                            Expanded(
                              child: Text(c.content,
                                style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF4A6688),
                                  height: 1.5,
                                )),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),

                // 输入框
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Row(children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          border: Border.all(
                            color: const Color(0xFF4D9FFF).withOpacity(0.15),
                            width: 0.8,
                          ),
                        ),
                        child: TextField(
                          controller: _commentCtrl,
                          style: const TextStyle(
                            fontSize: 12, color: Color(0xFFC8E0FF)),
                          decoration: const InputDecoration(
                            hintText: "发送频段回应...",
                            hintStyle: TextStyle(
                              fontSize: 11, color: Color(0xFF4A6688)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final t = _commentCtrl.text.trim();
                        if (t.isEmpty) return;
                        widget.onAddComment(t);
                        _commentCtrl.clear();
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4D9FFF).withOpacity(0.1),
                          border: Border.all(
                            color: const Color(0xFF4D9FFF).withOpacity(0.3),
                            width: 0.8,
                          ),
                        ),
                        child: const Icon(Icons.arrow_upward_rounded,
                          size: 14, color: Color(0xFF7DC4FF)),
                      ),
                    ),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 操作按钮
// ══════════════════════════════════════════════
class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _ctrl.forward().then((_) => _ctrl.reverse());
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, __) => Transform.scale(
          scale: _scaleAnim.value,
          child: Row(children: [
            Icon(widget.icon, size: 14, color: widget.color),
            const SizedBox(width: 5),
            Text(widget.label,
              style: TextStyle(
                fontSize: 11, color: widget.color,
                fontWeight: FontWeight.w300,
              )),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 发布按钮（右下角浮动）
// ══════════════════════════════════════════════
class _ComposeButton extends StatelessWidget {
  final VoidCallback onTap;
  final AnimationController flowCtrl;

  const _ComposeButton({required this.onTap, required this.flowCtrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: flowCtrl,
        builder: (_, __) => Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF040D1A).withOpacity(0.9),
            border: Border.all(
              color: const Color(0xFF4D9FFF)
                  .withOpacity(0.3 + flowCtrl.value * 0.2),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4D9FFF)
                    .withOpacity(0.12 + flowCtrl.value * 0.08),
                blurRadius: 16,
              ),
            ],
          ),
          child: const Icon(Icons.add,
            size: 20, color: Color(0xFF7DC4FF)),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 发布面板
// ══════════════════════════════════════════════
class _ComposePanel extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClose;
  final VoidCallback onPost;

  const _ComposePanel({
    required this.controller,
    required this.onClose,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: GestureDetector(
          onTap: () {}, // 阻止穿透
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    20, 20, 20,
                    MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF040D1A).withOpacity(0.95),
                    border: const Border(
                      top: BorderSide(
                        color: Color(0xFF4D9FFF), width: 0.8),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 顶部行
                      Row(children: [
                        const Text("发送频段",
                          style: TextStyle(
                            fontSize: 12, letterSpacing: 3,
                            color: Color(0xFF4D9FFF),
                            fontWeight: FontWeight.w300,
                          )),
                        const Spacer(),
                        GestureDetector(
                          onTap: onClose,
                          child: const Icon(Icons.close,
                            size: 16, color: Color(0xFF4A6688)),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // 输入框
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          border: Border.all(
                            color: const Color(0xFF4D9FFF).withOpacity(0.15),
                            width: 0.8,
                          ),
                        ),
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          maxLines: 4,
                          minLines: 2,
                          style: const TextStyle(
                            fontSize: 13, color: Color(0xFFC8E0FF),
                            height: 1.7, fontWeight: FontWeight.w300,
                          ),
                          decoration: const InputDecoration(
                            hintText: "此刻的星轨留下什么...",
                            hintStyle: TextStyle(
                              fontSize: 12, color: Color(0xFF4A6688)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 发送按钮
                      GestureDetector(
                        onTap: onPost,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4D9FFF).withOpacity(0.1),
                            border: Border.all(
                              color: const Color(0xFF4D9FFF).withOpacity(0.4),
                              width: 0.8,
                            ),
                          ),
                          child: const Center(
                            child: Text("发 送",
                              style: TextStyle(
                                fontSize: 12, letterSpacing: 6,
                                color: Color(0xFF7DC4FF),
                                fontWeight: FontWeight.w300,
                              )),
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
}

// ══════════════════════════════════════════════
// 种子头像（根据字符串生成固定颜色）
// ══════════════════════════════════════════════
class _SeedAvatar extends StatelessWidget {
  final String seed;
  final double size;

  const _SeedAvatar({required this.seed, required this.size});

  Color _seedColor() {
    final colors = [
      const Color(0xFF4D9FFF),
      const Color(0xFF7DC4FF),
      const Color(0xFF9BBBFF),
      const Color(0xFFA8C4E0),
      const Color(0xFF2A6FD4),
    ];
    final idx = seed.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[idx];
  }

  String _initials() {
    if (seed.isEmpty) return '?';
    return seed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _seedColor();
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Center(
        child: Text(_initials(),
          style: TextStyle(
            fontSize: size * 0.38,
            color: color,
            fontWeight: FontWeight.w300,
          )),
      ),
    );
  }
}
/// 大纲面板：意图树的可视化（方案 §6.1）。
///
/// 这棵树同时是**语义树**——`children` 顺序即读屏顺序与 Tab 焦点顺序
/// （方案 §5.1）。所以这里不允许提供「仅视觉排序」的拖拽，拖拽改的就是
/// `children` 数组本身。
///
/// 骨架阶段渲染一棵固定的示例树，用来验证面板布局与选中态；接内核后
/// 数据来自 `FideProject.readIntent`。
library;

import '../app/ui.dart';

import '../app/tokens.dart';

/// 大纲面板。
class OutlinePanel extends StatelessWidget {
  const OutlinePanel({
    super.key,
    required this.selectedNodeId,
    required this.onSelect,
  });

  /// 当前选中的节点 id。
  final String? selectedNodeId;

  /// 点选回调。传 `null` 表示取消选中。
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _PanelHeader(title: '大纲', hint: 'children 顺序 = 读屏顺序'),
        const Divider(height: 1, color: FideColors.lineSoft),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: FideGap.x2),
            children: [
              // TODO(skeleton): 换成 FidePage.walk() 的真实数据。
              // 这里刻意用接近真实形状的示例而不是「节点 1/2/3」：
              // 假数据若长得像真数据，布局问题在读第一眼时就能看出来。
              for (final row in _demoRows)
                _OutlineRow(
                  nodeId: row.$1,
                  label: row.$2,
                  depth: row.$3,
                  kind: row.$4,
                  selected: selectedNodeId == row.$1,
                  onTap: () => onSelect(row.$1),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: FideColors.lineSoft),
        // 树底部固定一条说明：这个面板的规矩要写在它旁边，不然没人会去翻文档。
        Padding(
          padding: const EdgeInsets.all(FideGap.x3),
          child: Text(
            '顺序即语义。改位置会让读屏与 Tab 顺序一起变。',
            style: fideText(11, color: FideColors.inkTertiary, height: 16 / 11),
          ),
        ),
      ],
    );
  }
}

/// 示例行：`(id, 标签, 缩进层级, 是否叶子)`。
const List<(String, String, int, bool)> _demoRows = [
  ('hero', 'hero · container', 0, false),
  ('hero.title', 'title · Text', 1, true),
  ('hero.meta', 'meta · MetaLabel', 1, true),
  ('features', 'features · container', 0, false),
  ('features.list', 'list · Column', 1, false),
  ('features.list.item', 'item · Card', 2, true),
];

/// 一行节点。
class _OutlineRow extends StatelessWidget {
  const _OutlineRow({
    required this.nodeId,
    required this.label,
    required this.depth,
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  final String nodeId;
  final String label;
  final int depth;
  final bool kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? FideColors.inset : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: FideColors.lineSoft,
        child: Container(
          height: 30,
          // 缩进 = 基础内距 + 层级 × 16。容器与叶子用不同图标区分，
          // 但不用不同颜色——颜色留给「选中」与「错误」两件事。
          padding: EdgeInsets.only(left: FideGap.x3 + depth * FideGap.x4),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(
                kind ? Icons.crop_square_outlined : Icons.article_outlined,
                size: 14,
                color: FideColors.inkTertiary,
              ),
              const SizedBox(width: FideGap.x2),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: fideText(
                    13,
                    weight: selected ? 500 : 330,
                    color: FideColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 面板统一表头。高度固定 40，五个面板共用，避免各写一份高度不一致。
class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: FideGap.x3),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(title, style: fideText(13, weight: 500, color: FideColors.ink)),
          if (hint != null) ...[
            const SizedBox(width: FideGap.x2),
            Flexible(
              child: Text(
                hint!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: fideText(11, color: FideColors.inkTertiary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

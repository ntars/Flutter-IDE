/// 冲突仲裁面板（方案 §8.2）。
///
/// **三条规则决定了这个面板长什么样：**
///
/// 1. `delta` 命中的属性，生成器永不许静默覆盖 → 冲突必须由人来解；
/// 2. 未命中的属性自动接受新基线，不打扰用户 → 这里只列冲突，不列正常项；
/// 3. 冲突必须同时展示 base 与 delta，不许让用户盲选 → 两个值并排，且
///    都标出来源。
///
/// 用户看到的是「上游重算变成了 28，你调的是 24」。选哪个都行，
/// 但必须先看到两个数。
library;

import '../app/ui.dart';

import '../app/tokens.dart';

/// 冲突仲裁面板。
class ConflictPanel extends StatelessWidget {
  const ConflictPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: FideGap.x3),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Text(
                '冲突',
                style: fideText(13, weight: 500, color: FideColors.ink),
              ),
              const SizedBox(width: FideGap.x2),
              // 计数用胶囊，不用红点：红点是「有错误」，冲突只是「需要决定」。
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: FideColors.inset,
                  borderRadius: BorderRadius.circular(FideRadii.pill),
                ),
                child: Text(
                  '1',
                  style: fideText(
                    10,
                    weight: 500,
                    color: FideColors.inkSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: FideColors.lineSoft),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(FideGap.x3),
            // TODO(skeleton): 数据来自 FideResolvedValue.hasConflict 为真的项。
            children: const [
              _ConflictCard(
                nodeId: 'hero.title',
                breakpoint: 'compact',
                path: 'props.style.fontSize',
                base: '28',
                delta: '24',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 一张冲突卡：节点 + 断点 + 属性，两个值并排。
class _ConflictCard extends StatelessWidget {
  const _ConflictCard({
    required this.nodeId,
    required this.breakpoint,
    required this.path,
    required this.base,
    required this.delta,
  });

  final String nodeId;
  final String breakpoint;
  final String path;

  /// 上游重算后的新值。
  final String base;

  /// 用户的微调值。
  final String delta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FideGap.x3),
      decoration: BoxDecoration(
        color: FideColors.surface,
        borderRadius: BorderRadius.circular(FideRadii.md),
        border: Border.all(color: FideColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nodeId, style: fideText(12, weight: 500, color: FideColors.ink)),
          const SizedBox(height: 2),
          Text(
            '$breakpoint · $path',
            style: fideText(11, color: FideColors.inkTertiary),
          ),
          const SizedBox(height: FideGap.x3),
          // 两个候选并排，等宽。等宽是刻意的：让选择看起来是平权的，
          // 不给「基线」更高位置暗示它更权威。
          Row(
            children: [
              Expanded(
                child: _Choice(caption: '新基线', value: base, hint: '上游重算'),
              ),
              const SizedBox(width: FideGap.x2),
              Expanded(
                child: _Choice(
                  caption: '我的微调',
                  value: delta,
                  hint: '保留不改',
                  emphasized: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: FideGap.x3),
          const Row(
            children: [
              _Action(label: '采用基线', primary: false),
              SizedBox(width: FideGap.x2),
              _Action(label: '保留微调', primary: true),
              Spacer(),
              _Action(label: '手动', primary: false),
            ],
          ),
        ],
      ),
    );
  }
}

/// 一个候选值。
class _Choice extends StatelessWidget {
  const _Choice({
    required this.caption,
    required this.value,
    required this.hint,
    this.emphasized = false,
  });

  final String caption;
  final String value;
  final String hint;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FideGap.x2,
        vertical: FideGap.x2,
      ),
      decoration: BoxDecoration(
        color: emphasized ? FideColors.inset : FideColors.canvas,
        borderRadius: BorderRadius.circular(FideRadii.sm),
        border: Border.all(
          color: emphasized ? FideColors.line : FideColors.lineSoft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(caption, style: fideText(10, color: FideColors.inkTertiary)),
          const SizedBox(height: 2),
          Text(value, style: fideText(15, weight: 500, color: FideColors.ink)),
          Text(hint, style: fideText(10, color: FideColors.inkTertiary)),
        ],
      ),
    );
  }
}

/// 一个动作按钮。
class _Action extends StatelessWidget {
  const _Action({required this.label, required this.primary});

  final String label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: FideGap.x3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primary ? FideColors.accent : FideColors.surface,
        borderRadius: BorderRadius.circular(FideRadii.sm),
        border: primary ? null : Border.all(color: FideColors.line),
      ),
      child: Text(
        label,
        style: fideText(
          12,
          weight: 500,
          color: primary ? Colors.white : FideColors.inkSecondary,
        ),
      ),
    );
  }
}

/// 属性面板：由 `spec + delta` 生成（方案 §6.1）。
///
/// 三条显示纪律，都来自真实失败模式：
///
/// 1. **显示运行时真值，不显示源码文本**（方案 §7.1）。值来自 VM Service
///    的 diagnostics，不是解析源码猜出来的——这一步整类 bug 直接消失。
/// 2. **复杂表达式灰显并提示「去源码改」**（方案 §11.2）。三元、闭包、
///    计算属性无法双向，假装能改的代价是用户改了没生效。
/// 3. **标出「另有 N 个覆盖」**（方案 §11.2）。同一属性可能有多套断点值，
///    只改最高优先级那一项。
library;

import '../app/ui.dart';

import '../app/tokens.dart';

/// 属性面板。
class PropsPanel extends StatelessWidget {
  const PropsPanel({super.key, required this.selectedNodeId});

  /// 当前选中的节点。`null` 时显示空态。
  final String? selectedNodeId;

  @override
  Widget build(BuildContext context) {
    if (selectedNodeId == null) {
      return const _PropsEmpty();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: FideGap.x3),
          alignment: Alignment.centerLeft,
          child: Text(
            selectedNodeId!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: fideText(13, weight: 500, color: FideColors.ink),
          ),
        ),
        const Divider(height: 1, color: FideColors.lineSoft),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(FideGap.x3),
            children: const [
              // TODO(skeleton): 按 FideBlockSpec.props 的 group 分三组渲染。
              // 现在给静态示意，把三种典型行（可编辑 / 令牌下拉 / 灰显）都摆出来，
              // 好让布局与灰显样式在骨架阶段就能被看到。
              _GroupLabel('内容'),
              _PropRow.edit(label: 'value', value: '欢迎回来'),
              SizedBox(height: FideGap.x2),
              _GroupLabel('外观'),
              _PropRow.token(label: 'style', token: 'display/medium'),
              SizedBox(height: FideGap.x2),
              _GroupLabel('行为'),
              _PropRow.edit(label: 'maxLines', value: '2'),
              SizedBox(height: FideGap.x2),
              _PropRow.readOnly(label: 'overflow', note: '运行时值来自表达式，去源码改'),
              SizedBox(height: FideGap.x4),
              _OverrideNotice(count: 2, breakpoint: 'compact'),
            ],
          ),
        ),
      ],
    );
  }
}

/// 分组标题。11 / 700 / 45% 黑，与列表行拉开一档。
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FideGap.x2),
      child: Text(
        text,
        style: fideText(11, weight: 500, color: FideColors.inkTertiary),
      ),
    );
  }
}

/// 一行属性。三种形态共用一个容器，保证行高与对齐一致。
class _PropRow extends StatelessWidget {
  const _PropRow.edit({required this.label, required this.value})
    : token = null,
      note = null,
      readOnly = false;

  const _PropRow.token({required this.label, required this.token})
    : value = null,
      note = null,
      readOnly = false;

  const _PropRow.readOnly({required this.label, required this.note})
    : value = null,
      token = null,
      readOnly = true;

  final String label;

  /// 可编辑的字面量值。
  final String? value;

  /// 令牌名。非空表示这一行渲染成令牌下拉。
  final String? token;

  /// 灰显说明。非空表示这一行不可编辑。
  final String? note;

  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final field = Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: FideGap.x2),
      decoration: BoxDecoration(
        color: readOnly ? FideColors.canvas : FideColors.surface,
        borderRadius: BorderRadius.circular(FideRadii.sm),
        border: Border.all(color: FideColors.line),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          if (token != null)
            const Icon(
              Icons.local_offer_outlined,
              size: 12,
              color: FideColors.inkTertiary,
            ),
          if (token != null) const SizedBox(width: FideGap.x1),
          Flexible(
            child: Text(
              readOnly ? '表达式' : (token ?? value ?? ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: fideText(
                12,
                color: readOnly ? FideColors.inkDisabled : FideColors.ink,
              ),
            ),
          ),
          if (token != null) ...[
            const Spacer(),
            const Icon(
              Icons.expand_more,
              size: 14,
              color: FideColors.inkTertiary,
            ),
          ],
        ],
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 属性名宽度固定 92：不固定的话，三行标签宽度不同会让右侧输入框
        // 左边缘参差，看起来像没对齐。
        SizedBox(
          width: 92,
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: fideText(12, color: FideColors.inkSecondary),
            ),
          ),
        ),
        Expanded(child: field),
      ],
    );
  }
}

/// 「另有 N 个覆盖」提示。
///
/// 它说的是：这个属性在其他断点下还有别的值，你正在改的只是其中一档。
/// 不提示的后果是用户以为自己改了全局，实际只改了手机端。
class _OverrideNotice extends StatelessWidget {
  const _OverrideNotice({required this.count, required this.breakpoint});

  final int count;
  final String breakpoint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FideGap.x2),
      decoration: BoxDecoration(
        color: FideColors.inset,
        borderRadius: BorderRadius.circular(FideRadii.sm),
      ),
      child: Text(
        '另有 $count 个覆盖（$breakpoint 之外）。这里改的是最高优先级那一项。',
        style: fideText(11, color: FideColors.inkSecondary, height: 16 / 11),
      ),
    );
  }
}

/// 空态：说清「选中一个节点就会出现什么」，不摆假数据。
class _PropsEmpty extends StatelessWidget {
  const _PropsEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FideGap.x5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune, size: 28, color: FideColors.inkDisabled),
            const SizedBox(height: FideGap.x3),
            Text(
              '没有选中节点',
              style: fideText(13, weight: 500, color: FideColors.inkSecondary),
            ),
            const SizedBox(height: FideGap.x1),
            Text(
              '在大纲里点一个节点，这里显示它的属性。\n值是运行时算出来的，不是从源码猜的。',
              textAlign: TextAlign.center,
              style: fideText(
                11,
                color: FideColors.inkTertiary,
                height: 16 / 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

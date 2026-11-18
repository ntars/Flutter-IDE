/// 同步率面板（方案 §8.3）。
///
/// 三项数字是产品的体温计，回答的不是「生成了多少代码」，而是
/// 「**生成器还跟得上人的意图吗**」。
///
/// 两个细节在这里落地：
/// - 阈值告警必须带「该怎么办」，只报数字等于把人晾在那里；
/// - **回收动作**要显眼。没有回收机制，系统一定会烂在「没人敢改」。
library;

import 'package:fide_core/fide_core.dart';

import '../app/ui.dart';

import '../app/tokens.dart';

/// 同步率面板。
class MetricsPanel extends StatelessWidget {
  const MetricsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: FideGap.x3),
          alignment: Alignment.centerLeft,
          child: Text(
            '同步率',
            style: fideText(13, weight: 500, color: FideColors.ink),
          ),
        ),
        const Divider(height: 1, color: FideColors.lineSoft),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.all(FideGap.x3),
            // TODO(skeleton): 读数来自 FideMetrics.fromValues(...)。
            // 这里用一组接近真实的示例值，把三种视觉状态都展示出来：
            // auto 正常、patch 接近阈值、orphan 触发告警。
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MetricsBar(autoCount: 68, patchCount: 24, orphanCount: 8),
                SizedBox(height: FideGap.x4),
                _AlertRow(
                  text: 'patch 24%，离 40% 阈值还有余量。',
                  level: _AlertLevel.ok,
                ),
                SizedBox(height: FideGap.x2),
                _AlertRow(
                  text: 'orphan 8%，接近 10% 阈值：有人在绕过意图大纲。',
                  level: _AlertLevel.warn,
                ),
                SizedBox(height: FideGap.x4),
                Divider(height: 1, color: FideColors.lineSoft),
                SizedBox(height: FideGap.x3),
                // 回收动作要显眼：它是这套机制唯一的出口。
                _RecycleRow(nodeId: 'hero.title', overrideCount: 2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 三段占比条 + 数字。
///
/// 用 `LayoutBuilder` 量宽再按比例给实宽，不用 `FractionallySizedBox`：
/// 在 `Column` 的非紧约束下它拿不到确定宽度，会收缩成 0——表现是
/// 「整条不见了」且不报错。这个坑在 Ondra 里踩过一次，记录在此。
class _MetricsBar extends StatelessWidget {
  const _MetricsBar({
    required this.autoCount,
    required this.patchCount,
    required this.orphanCount,
  });

  final int autoCount;
  final int patchCount;
  final int orphanCount;

  @override
  Widget build(BuildContext context) {
    final metrics = FideMetrics(
      autoCount: autoCount,
      patchCount: patchCount,
      orphanCount: orphanCount,
    );
    final total = metrics.total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 6,
          child: LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              double px(int n) => total == 0 ? 0 : w * n / total;
              return Row(
                children: [
                  _segment(px(autoCount), FideColors.accent),
                  _segment(px(patchCount), FideColors.inkDisabled),
                  _segment(px(orphanCount), FideColors.warning),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: FideGap.x2),
        Row(
          children: [
            _Legend(
              label: 'auto',
              value: metrics.ratioOf(FideValueOrigin.auto),
              color: FideColors.accent,
            ),
            const SizedBox(width: FideGap.x4),
            _Legend(
              label: 'patch',
              value: metrics.ratioOf(FideValueOrigin.patch),
              color: FideColors.inkDisabled,
            ),
            const SizedBox(width: FideGap.x4),
            _Legend(
              label: 'orphan',
              value: metrics.ratioOf(FideValueOrigin.orphan),
              color: FideColors.warning,
            ),
          ],
        ),
      ],
    );
  }

  Widget _segment(double width, Color color) => Container(
    width: width,
    height: 6,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}

/// 图例一项。
class _Legend extends StatelessWidget {
  const _Legend({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: FideGap.x1),
        Text(
          '$label ${(value * 100).round()}%',
          style: fideText(11, color: FideColors.inkSecondary),
        ),
      ],
    );
  }
}

/// 告警级别。三级就够：正常、留意、动手。
enum _AlertLevel { ok, warn, alert }

/// 一行告警。
class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.text, required this.level});

  final String text;
  final _AlertLevel level;

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      _AlertLevel.ok => FideColors.inkTertiary,
      _AlertLevel.warn => FideColors.warning,
      _AlertLevel.alert => FideColors.danger,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: FideGap.x2),
        Expanded(
          child: Text(
            text,
            style: fideText(
              11,
              color: FideColors.inkSecondary,
              height: 16 / 11,
            ),
          ),
        ),
      ],
    );
  }
}

/// 回收：一键清空某节点的 delta，回到 auto。
class _RecycleRow extends StatelessWidget {
  const _RecycleRow({required this.nodeId, required this.overrideCount});

  final String nodeId;
  final int overrideCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '回收覆盖',
                style: fideText(12, weight: 500, color: FideColors.ink),
              ),
              Text(
                '$nodeId 有 $overrideCount 处微调，清空后回到生成基线。',
                style: fideText(
                  11,
                  color: FideColors.inkTertiary,
                  height: 16 / 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: FideGap.x2),
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: FideGap.x3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FideRadii.sm),
            border: Border.all(color: FideColors.line),
          ),
          child: Text(
            '清空',
            style: fideText(12, weight: 500, color: FideColors.inkSecondary),
          ),
        ),
      ],
    );
  }
}

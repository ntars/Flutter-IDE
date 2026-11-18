/// 同步率统计：`auto / patch / orphan` 三项占比与阈值告警（方案 §8.3）。
///
/// 这三项是产品的「体温计」。它们回答的问题不是「生成了多少代码」，
/// 而是「**生成器还跟得上人的意图吗**」：
///
/// - `auto` 完全由生成器决定；
/// - `patch` 被人覆盖过；
/// - `orphan` 只在源码里存在，既无基线也无覆盖。
///
/// 两个阈值不是拍的，是从失败模式反推的：
/// - `patch > 40%` → 生成质量或策略有系统性偏差，该回去修规则，不是让人多改；
/// - `orphan > 10%` → 有人在绕过系统，该问清为什么，而不是补一条规则堵住。
///
/// 没有回收机制的系统一定会烂在「没人敢改」，所以 [FideMetrics] 旁边必须有
/// `FideDelta.clearNode`（已在 delta 层实现）。
library;

import '../codegen/codegen.dart';

/// 一次统计的读数。
final class FideMetrics {
  const FideMetrics({
    required this.autoCount,
    required this.patchCount,
    required this.orphanCount,
  });

  final int autoCount;
  final int patchCount;
  final int orphanCount;

  /// 总属性数。三项之和，用于算占比。
  int get total => autoCount + patchCount + orphanCount;

  /// 从一串已合成的属性值统计。
  factory FideMetrics.fromValues(Iterable<FideResolvedValue> values) {
    var auto = 0;
    var patch = 0;
    var orphan = 0;
    for (final v in values) {
      switch (v.origin) {
        case FideValueOrigin.auto:
          auto++;
        case FideValueOrigin.patch:
          patch++;
        case FideValueOrigin.orphan:
          orphan++;
      }
    }
    return FideMetrics(autoCount: auto, patchCount: patch, orphanCount: orphan);
  }

  /// 某一项的占比。总数为 0 时返回 0，不返回 NaN——
  /// 面板上显示 `NaN%` 会让人以为算出错了。
  double ratioOf(FideValueOrigin origin) {
    if (total == 0) return 0;
    final count = switch (origin) {
      FideValueOrigin.auto => autoCount,
      FideValueOrigin.patch => patchCount,
      FideValueOrigin.orphan => orphanCount,
    };
    return count / total;
  }

  /// 需要提请注意的告警。空列表表示一切正常。
  ///
  /// 每条告警都带「该怎么办」，不只是「超阈值了」——只报数字的告警
  /// 等于把人晾在那里。
  List<FideMetricsAlert> get alerts {
    final out = <FideMetricsAlert>[];
    if (ratioOf(FideValueOrigin.patch) > 0.4) {
      out.add(
        const FideMetricsAlert(
          kind: FideValueOrigin.patch,
          threshold: 0.4,
          advice:
              '生成的基线没有命中人的意图。先看这些覆盖集中在哪个物料，'
              '多半是它的默认值或断点策略不对，不要靠人继续改。',
        ),
      );
    }
    if (ratioOf(FideValueOrigin.orphan) > 0.1) {
      out.add(
        const FideMetricsAlert(
          kind: FideValueOrigin.orphan,
          threshold: 0.1,
          advice:
              '有代码绕过了意图大纲。找到写它的人问清原因——'
              '若那类需求真实存在，是协议缺了表达力，不是纪律问题。',
        ),
      );
    }
    return out;
  }
}

/// 一条阈值告警。
final class FideMetricsAlert {
  const FideMetricsAlert({
    required this.kind,
    required this.threshold,
    required this.advice,
  });

  final FideValueOrigin kind;

  /// 触发的阈值（0–1）。
  final double threshold;

  /// 该怎么办。
  final String advice;
}

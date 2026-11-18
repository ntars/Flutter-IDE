/// 断点策略表。**集中定义，不许散落在页面里**（方案 §5.4）。
///
/// 数值取自 Material 3 的 window size class，不自创：
/// compact 0 起、medium 600 起、expanded 840 起、large 1200 起。
///
/// 两条硬约束，都写在类型上而不是靠文档约束：
///
/// 1. **列数是整数栅格，不是百分比**。意图大纲里 `span: {compact: 4, medium: 8}`
///    是列数，不是宽度；栅格按列分，跨端才有同一个度量。
/// 2. **分类只看容器宽度，不看屏幕宽度**。`classify(containerWidth)` 的入参
///    必须是 `LayoutBuilder` 给的 `constraints.maxWidth`。方案 §7.4 明令禁止
///    组件读 `MediaQuery.sizeOf(context).width`——组件只看自己被分到多宽，
///    搬到侧栏、搬到底部栏才都自动对。
library;

/// 一个断点档位：最小宽度 + 栅格列数。
///
/// Flutter 3.22 起可用 record 类型（方案 §5.4 的写法），这里用 final class 是
/// 为了让 `cols` 有名字可读、也让序列化进 intent 时有字段名可用。
final class FideBreakpoint {
  const FideBreakpoint({
    required this.id,
    required this.minWidth,
    required this.cols,
  });

  /// 大纲里引用的档位名：`compact` / `medium` / `expanded` / `large`。
  final String id;

  /// 该档位的下界（含）。上界由下一个档位的 [minWidth] 给出。
  final double minWidth;

  /// 栅格列数。跨端一切 span 计算都以它为准。
  final int cols;

  @override
  String toString() => 'FideBreakpoint($id, ≥$minWidth, $cols 列)';
}

/// 断点策略表。
abstract final class FideBreakpoints {
  /// 全表，按 [FideBreakpoint.minWidth] 升序。
  ///
  /// 顺序即优先级：分类时从后往前找第一个满足下界的档位，所以这张表必须
  /// 保持升序。用常量列表而不是 Map：Map 的迭代顺序在 Dart 里虽然稳定，
  /// 但读代码的人不该被要求知道这件事。
  static const List<FideBreakpoint> all = [
    FideBreakpoint(id: 'compact', minWidth: 0, cols: 4),
    FideBreakpoint(id: 'medium', minWidth: 600, cols: 8),
    FideBreakpoint(id: 'expanded', minWidth: 840, cols: 12),
    FideBreakpoint(id: 'large', minWidth: 1200, cols: 12),
  ];

  /// 合法档位名，供校验器与属性面板使用。
  static List<String> get ids => all.map((b) => b.id).toList(growable: false);

  /// 按**容器**宽度归类。
  ///
  /// 入参必须是 `LayoutBuilder` 的 `constraints.maxWidth`，不是屏幕宽度。
  /// 传进屏幕宽度不会报错，但会让侧栏里的组件按整窗宽度排版——这是方案
  /// §7.4 要防的那类 bug，所以这里只写容器宽度这一个名字，不给屏幕宽度留别名。
  static FideBreakpoint classify(double containerWidth) {
    // 从最宽档位往回找。负数宽度按 compact 处理：布局未定时的保守值。
    for (var i = all.length - 1; i >= 0; i--) {
      if (containerWidth >= all[i].minWidth) return all[i];
    }
    return all.first;
  }

  /// 按名字取档位，不存在返回 `null`。
  static FideBreakpoint? byId(String id) {
    for (final b in all) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// 某档位的列数。档位名非法时返回 `null`，由调用方决定报错方式。
  static int? colsOf(String id) => byId(id)?.cols;
}

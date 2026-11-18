/// 代码生成：`intent + delta → Dart 源码片段`（方案 §5.3、§7.5）。
///
/// 本层**只产出字符串，不碰文件系统**。写盘是 `ast_writer` 的事。
/// 这条界让 codegen 可以纯函数式测试：给定同一输入，逐字节比对输出。
/// 方案 §15 的三条验收标准里「同一输入两次生成结果一致」就靠这个边界成立。
///
/// 生成期 AI 的唯一介入点也在这里（方案 §7.5）：模型输出的是「某个 section 的
/// 实现片段」，本层负责把它接进产物，并交给校验器与 golden test。运行时零 AI。
library;

import '../project_model/delta.dart';
import '../project_model/intent.dart';
import '../project_model/node.dart';

/// 一个待写回的产物。
///
/// 刻意不含文件名：文件名由 `ast_writer` 按节点 id 推导。codegen 不知道
/// 代码放在哪个文件里，也就不会在重构目录结构时跟着改一遍。
final class FideGeneratedFragment {
  const FideGeneratedFragment({
    required this.nodeId,
    required this.source,
    required this.semanticsIdentifier,
  });

  /// 对应的意图节点。
  final String nodeId;

  /// Dart 源码片段。**不含 import，不含文件头**——它只是表达式级片段，
  /// 由 ast_writer 插进已有的 widget 树。
  final String source;

  /// 写进 `Semantics(identifier:)` 的值，等于 [nodeId]。
  ///
  /// 双锚点的另一半（方案 §5.2）：`creationLocation` 精确但 release 不保留，
  /// 这个字符串跨版本稳定，是写回时找目标的依据。
  final String semanticsIdentifier;
}

/// 合成结果：一个属性最终取什么值，以及它来自 base 还是 delta。
///
/// 冲突仲裁面板（方案 §8.2）需要同时展示 base 与 delta，所以这里不只给
/// 最终值，还给出两侧来源——「不许让用户盲选」的前提是两边的值都在手上。
final class FideResolvedValue {
  const FideResolvedValue({
    required this.path,
    required this.base,
    required this.delta,
    required this.effective,
  });

  /// 属性路径，如 `props.style.fontSize`。
  final String path;

  /// 生成基线算出来的值。
  final Object? base;

  /// 覆盖层给的微调值，没有覆盖时为 `null`。
  final Object? delta;

  /// 实际生效的值。
  final Object? effective;

  /// 是否存在冲突：base 与 delta 都非空且不相等。
  ///
  /// 这个判定是「同步率」与「冲突数」共同的来源，只在这里算一次。
  bool get hasConflict => delta != null && base != null && base != delta;

  /// 值的来源。
  FideValueOrigin get origin {
    if (delta == null) return FideValueOrigin.auto;
    return FideValueOrigin.patch;
  }
}

/// 三个状态（方案 §9 第 3 条）。
///
/// 大多数工具做「同步 / 独立」二态，实际需要的是三态——第三种 `orphan`
/// 指的是源码被手改到已无对应覆盖、也无对应基线的状态，它必须能被看见，
/// 否则会变成永久的技术债。
enum FideValueOrigin {
  /// 完全由生成器决定。
  auto,

  /// 被覆盖层微调过。
  patch,

  /// 既无基线也无覆盖，只在源码里存在。
  orphan,
}

/// 生成器。按物料 id 分派到具体的 emitter。
final class FideCodegen {
  const FideCodegen({required this.emitters});

  /// 物料 id → 片段生成器。第三方物料只要注册到这里就能被生成，
  /// 不需要改内核——这是物料协议存在的意义（方案 §8.1）。
  final Map<String, FideEmitter> emitters;

  /// 生成一页的全部片段。
  ///
  /// 步骤（方案 §5.3 的合成公式）：
  /// 1. 按断点档位切分，逐档生成基线；
  /// 2. 用 delta 覆盖基线中被命中的属性；
  /// 3. 产出「每断点一份」的片段列表。
  List<FideGeneratedFragment> generate(FideIntent intent, FideDelta delta) {
    // TODO(skeleton): 逐断点生成 + delta 合成 + 物料分派。
    //
    // 实现顺序建议（不要跳步，跳步会让 diff 噪声在第一步就混进来）：
    //   1. 单档位、单叶子的最小闭环：text 物料 → 一段 Text(...)；
    //   2. 加上容器：Row/Column 递归包 children；
    //   3. 加上 LayoutBuilder 外层与断点分派；
    //   4. 最后才接 delta。
    throw UnimplementedError('FideCodegen.generate 待实现（骨架阶段）');
  }

  /// 合成单个属性：`产物 = base + delta`。
  ///
  /// **这条是纯函数，已实现**，因为它承载了整套设计的正确性证明：
  /// 命中 delta 的属性必须用 delta 值，未被命中的用 base，
  /// 而且两者都留在返回值里供冲突面板展示。
  static FideResolvedValue resolve({
    required String nodeId,
    required String breakpoint,
    required String path,
    required Object? base,
    required FideDelta delta,
  }) {
    final override = delta.pick(nodeId, breakpoint, path);
    return FideResolvedValue(
      path: path,
      base: base,
      delta: override?.value,
      // delta 命中即胜出。方案 §8.2 第 1 条：「delta 命中的属性，生成器
      // 永不许静默覆盖」——所以这里没有「哪个更新」的判断，delta 无条件优先。
      effective: override != null ? override.value : base,
    );
  }
}

/// 单个物料的片段生成器。
///
/// 物料作者实现这个接口就能被生成。契约只有一条：**输出必须是静态 Dart，
/// 不许引入任何运行时请求**（方案 §7.5 铁律第 2 条）。
abstract interface class FideEmitter {
  /// 物料 id，必须与 `spec.yaml` 的 `id` 一致。
  String get widgetId;

  /// 为一个叶子节点产出表达式级 Dart 片段。
  ///
  /// [resolved] 是已经合成完毕的属性集合，emitter 不需要（也不应该）
  /// 自己再去查 delta——合成只在一个地方发生。
  String emitLeaf(FideNode node, Map<String, FideResolvedValue> resolved);

  /// 为一个容器节点产出片段，子节点片段由 [children] 传入。
  String emitContainer(FideNode node, List<String> children);
}

/// 覆盖层（Delta）：人手微调只记差异，不复制整页（方案 §5.3）。
///
/// **这是整个产品最重要的一条设计。** 它替代了「同步按钮」：
///
/// ```
/// 产物 = 生成基线(base) + 覆盖层(delta)
/// ```
///
/// - `base` 每次可重算，随时可丢（改一次大纲就重新生成）；
/// - `delta` 永久保留，体积极小（只记「哪个节点、哪个断点、哪个属性、什么值」）；
/// - 二者叠加天然等于「既跟上了上游变更，又保住了我的微调」。
///
/// 所以不需要同步。同步是默认行为，真正需要的是**冲突仲裁**——即当 base 的
/// 新值与 delta 的旧值指向同一处时，让人来选。
library;

/// 覆盖的粒度：一个节点在某一个断点下的一组属性差异。
///
/// 键的构造规则（全库唯一，生成器与面板都靠它对齐）：
/// `nodeId` + `/` + `breakpointId` + `/` + `propPath`。
/// 例如 `hero.title/compact/props.style.fontSize`。
///
/// 用字符串键而不是嵌套 Map：覆盖层要被序列化进 git，扁平结构 diff 只有一行，
/// 嵌套结构改一个值会产生三行上下文变化。方案 §15 的验收标准「改一个值，
/// git diff 只有一行」就是靠这个扁平化成立的。
final class FideOverride {
  const FideOverride({
    required this.nodeId,
    required this.breakpoint,
    required this.path,
    required this.value,
  });

  /// 被覆盖的节点 id，对应源码里的 `Semantics(identifier:)`。
  final String nodeId;

  /// 断点档位名（`compact` / `medium` / `expanded` / `large`）。
  ///
  /// 覆盖必须绑断点：同一个字号在手机与桌面本就该不同，不绑断点的覆盖
  /// 等于把一次局部微调放大成全端变更。
  final String breakpoint;

  /// 属性路径，形如 `props.style.fontSize` 或 `layout.dir`。
  final String path;

  /// 新值。类型由属性路径决定，此处保持 `Object?` 交给校验器判。
  final Object? value;

  /// 覆盖层内的唯一键。见类文档。
  String get key => '$nodeId/$breakpoint/$path';

  @override
  String toString() => 'FideOverride($key = $value)';
}

/// 一页的完整覆盖层。
final class FideDelta {
  const FideDelta({
    required this.version,
    required this.page,
    this.overrides = const {},
  });

  final int version;

  /// 覆盖层所属页面 id。
  final String page;

  /// 键为 [FideOverride.key]，保证同一处只有一个覆盖值。
  ///
  /// Map 而非 List：覆盖的语义是「这个位置的值是 X」，重复条目没有意义。
  /// 用 List 会让「同键两条」变成一种可能被静默接受的状态。
  final Map<String, FideOverride> overrides;

  /// 该节点在该断点下被覆盖的属性路径集合。冲突仲裁面板按它筛。
  ///
  /// 这是「delta 命中的属性，生成器永不许静默覆盖」（方案 §8.2 第 1 条）
  /// 的检索入口：codegen 每写一个属性前都查一次。
  Set<String> pathsOf(String nodeId, String breakpoint) {
    final result = <String>{};
    for (final o in overrides.values) {
      if (o.nodeId == nodeId && o.breakpoint == breakpoint) {
        result.add(o.path);
      }
    }
    return result;
  }

  /// 取某处的覆盖值，没有覆盖返回 `null`。
  FideOverride? pick(String nodeId, String breakpoint, String path) =>
      overrides['$nodeId/$breakpoint/$path'];

  /// 清空某节点的全部覆盖，返回新的 delta。
  ///
  /// 方案 §8.3 的「回收动作」：单节点 delta 一键清空回 `auto`。
  /// 没有回收机制，系统一定会烂在「没人敢改」。
  FideDelta clearNode(String nodeId) {
    final next = <String, FideOverride>{};
    for (final entry in overrides.entries) {
      if (entry.value.nodeId != nodeId) next[entry.key] = entry.value;
    }
    return FideDelta(
      version: version,
      page: page,
      overrides: Map.unmodifiable(next),
    );
  }

  /// 空覆盖层。新建页面时用它占位，避免 codegen 到处判 null。
  static FideDelta empty(String page) =>
      FideDelta(version: 1, page: page, overrides: const {});

  /// 从 YAML 解析。
  ///
  /// 骨架阶段留签名。解析规则与序列化必须严格互逆，否则「打开再保存」
  /// 会改写用户文件——那是最不可接受的一类 bug，所以两边要一起实现、一起测。
  static FideDelta parse(String yamlSource) {
    // TODO(skeleton): 解析 overrides 的嵌套结构并展平成 [FideOverride.key]。
    throw UnimplementedError('FideDelta.parse 待实现（骨架阶段）');
  }
}

/// 意图大纲的节点模型（方案 §5.1）。
///
/// 三个概念在这里定死，后面所有层都按这三条走：
///
/// 1. **`children` 的顺序 = 语义顺序**。数组顺序同时是读屏顺序与 Tab 焦点顺序，
///    永远不允许为了视觉效果改顺序（改位置等于改语义，这件事必须显式发生）。
/// 2. **叶子没有布局权**。`kind == leaf` 时带 `layout` 直接判非法，校验器拒绝。
/// 3. **`foldTo` 必填**。折叠不等于删除，「窄屏时去哪」必须说清，没有默认值。
library;

/// 节点种类。
///
/// 只有两种，刻意不设第三种：
/// - `container` 是容器，排布权归它，可以说 `layout`；
/// - `leaf` 是叶子，身份权归它，只能说 `widget` 与 `props`。
///
/// 方案 §4.2 的「排布权归容器，身份权归叶子」就是这一行枚举的全部内容。
enum FideNodeKind {
  container,
  leaf;

  /// 从 YAML 的 `kind:` 解析。未知值返回 `null`，由校验器报错而不是静默降级。
  static FideNodeKind? parse(String raw) {
    for (final k in values) {
      if (k.name == raw) return k;
    }
    return null;
  }
}

/// 折叠去处。**必填，没有 `none` 之外的默认值。**
///
/// 五个枚举值对应五类真实交互，方案 §5.1 已列全：
/// - `overflow` 收进「更多」菜单
/// - `icon` 变成图标（文字标签退化）
/// - `tooltip` 变成悬停提示
/// - `collapse` 变成可展开区块
/// - `none` 永不折叠（必须是刻意声明的）
enum FideFoldTo {
  overflow,
  icon,
  tooltip,
  collapse,
  none;

  static FideFoldTo? parse(String raw) {
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return null;
  }

  /// 是否真的会消失。`none` 之外都算「窄屏时不在原地」。
  bool get hidesOnCompact => this != FideFoldTo.none;
}

/// 容器的排布方向。只允许 Flex 系能表达的三种，外加栅格。
///
/// 方案 §7.3 的能力边界：拖拽只能表达 `Row` / `Column` / `Flex` / `Grid` / `Wrap`
/// 能表达的位置。自由定位是显式降级选项，不在枚举里——它必须由单独的
/// `positionMode` 字段显式打开，不能混进 `dir`。
enum FideLayoutDir {
  row,
  column,
  wrap,
  grid;

  static FideLayoutDir? parse(String raw) {
    for (final d in values) {
      if (d.name == raw) return d;
    }
    return null;
  }
}

/// 按断点变化的栅格占用。
///
/// `span` 是**列数**，不是百分比或像素。列数由 [FideBreakpoints] 给出：
/// compact 4 列、medium 8 列、expanded 12 列。所以 `span.compact = 4` 表示
/// 在 compact 档位占满整行，`span.expanded = 6` 表示占一半。
///
/// 缺省的档位表示「跟随更小的档位」——这是唯一允许的隐含行为，且方向单一
/// （只会往上继承，不会往下），因为窄屏信息更少，宽屏加列是安全的。
final class FideSpan {
  const FideSpan({required this.byBreakpoint});

  /// 档位名 → 列数。键必须是 [FideBreakpoints.ids] 里的值。
  final Map<String, int> byBreakpoint;

  /// 某档位的列数。未声明时向上（更窄档位）继承，全部未声明返回 `null`。
  ///
  /// 继承方向单一：只会从更窄档位往上取，绝不从更宽的档位往下取。理由是
  /// 窄屏信息更少，宽屏加列不会溢出；反过来把 12 列的声明继承给 4 列的
  /// compact 档位，直接就是溢出。
  int? spanOf(String breakpointId) {
    final direct = byBreakpoint[breakpointId];
    if (direct != null) return direct;

    // 走到目标档位就停，取路径上最后一个已声明的值。
    int? inherited;
    for (final bp in _orderedBreakpoints) {
      final value = byBreakpoint[bp];
      if (value != null) inherited = value;
      if (bp == breakpointId) break;
    }
    return inherited;
  }

  /// 更窄到更宽的档位顺序。用于 [spanOf] 向上继承。
  ///
  /// 这里硬编码顺序而不是 import `FideBreakpoints`：本文件只描述数据结构，
  /// 不该因为「断点表长什么样」而牵连依赖。两者一致性由校验器保证。
  static const List<String> _orderedBreakpoints = [
    'compact',
    'medium',
    'expanded',
    'large',
  ];
}

/// 容器布局声明。**只有 `container` 节点可以有这个字段。**
final class FideLayout {
  const FideLayout({required this.dir, this.gap = 0, this.span});

  /// 排布方向。
  final FideLayoutDir dir;

  /// 子节点间距，单位是设计令牌 `space/*` 折算后的**逻辑像素**。
  ///
  /// 为什么不是令牌名：`gap` 会参与 codegen 计算（`SizedBox(height: gap)`），
  /// 而令牌名是给人读的。两者在生成产物里最终都变成同一个数字，所以这里
  /// 只留数字，避免 codegen 每次都要查表。校验器负责保证写入时已折算。
  final double gap;

  /// 栅格占用。容器可以不声明（跟随父容器），叶子无权声明。
  final FideSpan? span;
}

/// 意图大纲中的一个节点。
///
/// 用 `const` 构造 + `final` 字段：意图树在读取后不再变异，任何修改都走
/// 「生成一棵新树」的路径。这让 base / delta 的合成（方案 §5.3）天然没有
/// 副作用，也让缓存键可靠。
final class FideNode {
  const FideNode({
    required this.id,
    required this.kind,
    this.layout,
    this.widget,
    this.priority = 2,
    this.foldTo,
    this.props = const {},
    this.children = const [],
  });

  /// 稳定标识，形如 `hero.title`（点分路径）。
  ///
  /// **这个 id 是双锚点里「写回」那一半**（方案 §5.2）：它会被写成源码里的
  /// `Semantics(identifier: 'hero.title')`，文件被大规模重排后仍然有效。
  /// 因此它必须唯一且稳定——重命名要当作一次显式重构，不能随内容漂移。
  final String id;

  final FideNodeKind kind;

  /// 布局声明。仅 `container` 可用。
  final FideLayout? layout;

  /// 物料 id，形如 `ntars.text`。仅 `leaf` 必填。
  final String? widget;

  /// 语义重要度，1 最重要、3 最次要。
  ///
  /// 用途有三：窄屏折叠时决定先折叠谁、骨架屏按它排序、a11y 不额外处理。
  /// 默认 2 而不是 1：把全部节点默认成「最重要」等于没有优先级。
  final int priority;

  /// 折叠去处。**必填**（类型上可空是为了让校验器能报出「缺失」而不是在
  /// 解析阶段就崩，报错信息更准确）。
  final FideFoldTo? foldTo;

  /// 叶子属性。键是物料协议里的属性名，值来自 YAML（`Object?`）。
  final Map<String, Object?> props;

  /// 子节点。顺序即语义顺序。
  final List<FideNode> children;

  /// 是否为叶子。
  bool get isLeaf => kind == FideNodeKind.leaf;

  /// 是否为容器。
  bool get isContainer => kind == FideNodeKind.container;

  /// 深度优先遍历整棵树（含自身）。
  ///
  /// 校验器、codegen、同步率统计都要走一遍全树，统一在这里给一个迭代器式的
  /// 遍历，避免三处各写一次递归（而且各写一次就会有一处忘了处理异常）。
  Iterable<FideNode> walk() sync* {
    yield this;
    for (final child in children) {
      yield* child.walk();
    }
  }

  /// 按 id 查节点，找不到返回 `null`。
  FideNode? findById(String target) {
    for (final node in walk()) {
      if (node.id == target) return node;
    }
    return null;
  }

  /// 从根到目标节点的路径（含两端）。找不到返回空列表。
  ///
  /// 面包屑与大纲面板的展开状态都靠它。
  List<FideNode> pathTo(String target) {
    final stack = <FideNode>[];
    bool visit(FideNode node) {
      stack.add(node);
      if (node.id == target) return true;
      for (final child in node.children) {
        if (visit(child)) return true;
      }
      stack.removeLast();
      return false;
    }

    return visit(this) ? List.unmodifiable(stack) : const [];
  }

  /// 生成只替换了 [children] 的新节点。其余字段原样保留。
  ///
  /// 意图树不可变，拖拽改顺序、增删节点都走这里。
  FideNode withChildren(List<FideNode> next) => FideNode(
    id: id,
    kind: kind,
    layout: layout,
    widget: widget,
    priority: priority,
    foldTo: foldTo,
    props: props,
    children: List.unmodifiable(next),
  );

  @override
  String toString() => 'FideNode($id, ${kind.name})';
}

/// 物料协议的强类型表示（方案 §8.1）。
///
/// 一份 `spec.yaml` 描述一个物料的身份、插槽、属性、响应式能力与无障碍角色。
/// 这四组字段不是随意的清单，每一组都对应生成器或面板上的一个具体动作：
///
/// | 字段 | 谁在读 | 用来做什么 |
/// |---|---|---|
/// | `props` | 属性面板 | 渲染哪几种编辑器、校验取值范围 |
/// | `props.group` | 属性面板 | 按内容/外观/行为分组，不把 20 个属性堆一列 |
/// | `responsive.ownsLayout` | 校验器 | 该物料能否在意图里声明 layout |
/// | `responsive.minWidth` | 校验器 | 窄于此宽度时强制折叠 |
/// | `a11y.role` | codegen | 生成 `Semantics` 的角色 |
/// | `slots` | 生成器 | 往哪里塞子节点 |
library;

import 'package:fide_design/fide_design.dart';

/// 属性类型。**只有七种**，每多一种生成器就要多一个分支。
enum FidePropType {
  /// 字符串。
  string,

  /// 整数。
  int,

  /// 浮点。
  double,

  /// 布尔。
  bool,

  /// 枚举，取值由 [FidePropSpec.values] 给出。
  enumeration,

  /// 指向设计令牌的名字，必须是 `FideTokens` 里已注册的键。
  ///
  /// 这一种是「设计令牌唯一真源」在协议上的落点：写成 token-ref 的属性
  /// 不许填裸值，校验器据此拦截硬编码。
  tokenRef,

  /// 物料 id，用于插槽里能放什么。
  blockRef;

  static FidePropType? parse(String raw) {
    final normalized = raw.replaceAll('-', '');
    for (final t in values) {
      if (t.name.toLowerCase() == normalized.toLowerCase()) return t;
    }
    return null;
  }
}

/// 属性在面板上的分组。
enum FidePropGroup {
  /// 内容：文字、图标、数据源。
  content,

  /// 外观：颜色、字号、圆角。
  appearance,

  /// 行为：最大行数、溢出策略、可交互。
  behavior;

  static FidePropGroup? parse(String raw) {
    for (final g in values) {
      if (g.name == raw) return g;
    }
    return null;
  }
}

/// 一个属性的声明。
final class FidePropSpec {
  const FidePropSpec({
    required this.name,
    required this.type,
    this.required = false,
    this.group = FidePropGroup.content,
    this.defaultValue,
    this.min,
    this.max,
    this.values = const [],
  });

  /// 属性名，就是 Dart 构造参数的具名参数名。
  final String name;

  final FidePropType type;

  /// 必填。物料声明必填但意图里没给值 → 校验错误。
  final bool required;

  final FidePropGroup group;

  /// 默认值。生成器在意图未给值时用它，**不写进产物**——
  /// 让 Dart 自己用构造参数的默认值，产物才更干净。
  final Object? defaultValue;

  /// 数值型的下界（含）。仅 int / double 有效。
  final num? min;

  /// 数值型的上界（含）。仅 int / double 有效。
  final num? max;

  /// 枚举型的合法取值。
  final List<String> values;
}

/// 响应式能力声明。
///
/// 这两条是「复杂表达式不可视化」那类问题的前置防线（方案 §11.2）：
/// 若封装组件不声明 [minWidth]，面板就不知道该在什么时候把属性灰掉。
final class FideResponsiveSpec {
  const FideResponsiveSpec({required this.ownsLayout, required this.minWidth});

  /// 该物料是否自己在内部处理布局。
  ///
  /// `true` 表示它不接受外部 layout（例如 `AppBar`）；
  /// `false` 表示它是普通可排布元素。
  final bool ownsLayout;

  /// 最小可用宽度（逻辑像素）。窄于此值应强制折叠。
  final double minWidth;
}

/// 无障碍声明。
final class FideA11ySpec {
  const FideA11ySpec({required this.role, required this.identifierStrategy});

  /// 语义角色，写进 `Semantics` 的角色字段。
  final String role;

  /// identifier 生成策略。
  ///
  /// 骨架阶段只有 `auto` 一种：取意图节点 id。将来若需要「按内容哈希生成」，
  /// 在这里加枚举——但不能让物料自定义格式，否则写回定位会散掉。
  final String identifierStrategy;
}

/// 一份完整的物料声明。
final class FideBlockSpec {
  const FideBlockSpec({
    required this.id,
    required this.version,
    required this.widget,
    required this.props,
    required this.responsive,
    required this.a11y,
    this.slots = const [],
  });

  /// 物料 id，形如 `ntars.text`。**这是生态里的命名空间**：
  /// 官方用 `ntars.*`，第三方用自家前缀，因此不需要中心注册。
  final String id;

  /// 语义版本。生成器按它判断产物是否要重新生成。
  final String version;

  /// 对应的 Flutter Widget 类名。生成器直接写这个字符串。
  ///
  /// 它必须是真实存在的类——这一点骨架阶段不校验（需要整个 Flutter
  /// 的符号表），留作后续用 analyzer 解析项目来验证。
  final String widget;

  /// 插槽名列表。空表示这是叶子物料，不接受子节点。
  final List<String> slots;

  /// 属性声明表，键为属性名。
  final Map<String, FidePropSpec> props;

  final FideResponsiveSpec responsive;

  final FideA11ySpec a11y;

  /// 是否为叶子物料。没有插槽就是叶子——这是唯一的判定依据，
  /// 不另设 `kind` 字段，避免两处事实互相矛盾。
  bool get isLeaf => slots.isEmpty;

  /// 某属性是否被声明为 token-ref。校验器用它决定要不要查令牌表。
  bool isTokenRef(String propName) =>
      props[propName]?.type == FidePropType.tokenRef;

  /// 取出所有 token-ref 属性名。属性面板据此渲染令牌下拉而不是输入框。
  List<String> get tokenRefProps => props.values
      .where((p) => p.type == FidePropType.tokenRef)
      .map((p) => p.name)
      .toList(growable: false);

  /// 某属性的合法令牌。仅当类型为 token-ref 时非空。
  ///
  /// 返回全部已注册令牌而非该属性专属的子集：骨架阶段没有在协议里声明
  /// 「这个属性只接受字号令牌」，早期过度约束会让物料写不出来。
  List<String> tokensFor(String propName) => isTokenRef(propName)
      ? FideTokens.all.keys.toList(growable: false)
      : const [];
}

/// 设计令牌：颜色 / 间距 / 圆角 / 字号 / 字重 / 动效时长。
///
/// **这一层是产品的唯一真源**（方案 §14 `design/tokens.yaml` 的替代实现）。
/// 骨架阶段选择用 Dart 常量而不是 YAML，代价与收益都写清楚：
///
/// - 收益：没有生成步骤，`dart pub get` 之后立刻可读；校验器与 codegen 直接
///   import 本文件，不需要解析器。
/// - 代价：第三方物料作者要用令牌，必须依赖 `fide_design` 包。这在生态上
///   是可接受的——令牌本来就是这个产品的契约，不该让每个物料自己抄一份色值。
///
/// 命名沿用 `group/variant` 两段式（`display/medium`、`space/4`），因为意图大纲里
/// 写的就是 `style: display/medium`（方案 §5.1），令牌名必须能和它一一对上。
///
/// 三条纪律（与方案 §7.2 的 diff 纪律同源）：
/// 1. 组件只允许引用本文件的常量，不得内联裸值；
/// 2. 令牌只增不改值——改值等于全量产物 diff，要单独发一次版本；
/// 3. 物料 `spec.yaml` 里的 `type: token-ref` 只能指向 [_registry] 里存在的键。
library;

/// 令牌种类。校验器据此判断「这个属性该填颜色还是该填间距」。
enum FideTokenKind { color, space, radius, fontSize, fontWeight, duration }

/// 单条令牌：名字、种类、值。
///
/// [value] 的运行时类型由 [kind] 决定：
/// - [FideTokenKind.color] → `int`（0xAARRGGBB，与 `Color.value` 同构）
/// - 其它 → `double`（字重是可变字体的轴值，也是 double）
final class FideToken {
  const FideToken({
    required this.name,
    required this.kind,
    required this.value,
  });

  /// 形如 `accent/primary`、`space/4` 的两段式名字。
  final String name;
  final FideTokenKind kind;

  /// 见类文档。颜色为 `int`，其余为 `double`。
  final Object value;

  @override
  String toString() => 'FideToken($name, ${kind.name}, $value)';
}

/// 原始色。
///
/// 单色界面：强调色是近黑而不是蓝。整个产品只有一处彩色——`danger`，
/// 因为「删除 / 失败」是唯一值得用颜色标记的语义。
abstract final class FideRawColor {
  /// 近黑强调色，与正文同色但靠字重区分。
  static const int ink = 0xFF1C1F28;
  static const int inkStrong = 0xFF111318;

  /// 文字梯度，按黑度分级。
  static const int ink90 = 0xE6000000;
  static const int ink80 = 0xCC000000;
  static const int ink60 = 0x99000000;
  static const int ink45 = 0x73000000;
  static const int ink30 = 0x4D000000;
  static const int ink20 = 0x33000000;

  /// 面层：内容白、外壳灰、凹槽更深一档。
  static const int surface = 0xFFFFFFFF;
  static const int canvas = 0xFFF6F7FA;
  static const int inset = 0xFFEFF1F5;

  /// 线：1 逻辑像素发丝线，替代投影作为主要分层手段。
  static const int line = 0x1A000000;
  static const int lineSoft = 0x0D000000;

  /// 唯一彩色。
  static const int danger = 0xFFFA382E;
  static const int warning = 0xFFFF9F05;
}

/// 间距：4 基准。不用 8 基准——IDE 面板内部 12 / 20 这类值出现频率很高。
abstract final class FideSpaceRaw {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 24;
  static const double x6 = 32;
  static const double x7 = 48;
  static const double x8 = 64;
}

/// 圆角。只保留实际会用到的档位，多一档就会让相邻两块差 2px。
abstract final class FideRadiusRaw {
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double pill = 999;
}

/// 字号阶梯。
///
/// 名字用语义档位而不是 `h1/h2`：意图大纲里写的是 `style: display/medium`，
/// 「中号标题」比「二级标题」更接近人的说法，也更容易让多端翻译判断重要性。
abstract final class FideFontSize {
  static const double displayLarge = 40;
  static const double displayMedium = 32;
  static const double displaySmall = 28;
  static const double titleLarge = 20;
  static const double titleMedium = 17;
  static const double titleSmall = 15;
  static const double bodyLarge = 15;
  static const double bodyMedium = 14;
  static const double bodySmall = 13;
  static const double labelMedium = 12;
  static const double labelSmall = 11;
}

/// 字重轴值。
///
/// 走可变字体轴值而不是 [FontWeight] 枚举：只声明一个 wght 轴时，请求 w700
/// 会被渲染层合成加粗，笔画发糊。这两条在 Ondra 里已实测过，此处沿用结论。
abstract final class FideWeightRaw {
  static const double body = 330;
  static const double subtle = 380;
  static const double title = 450;
  static const double control = 500;
  static const double strong = 600;
}

/// 动效时长。四档够用：触觉 / 咬合 / 悬停 / 面板。
abstract final class FideDurationRaw {
  static const double tap = 70;
  static const double snap = 120;
  static const double hover = 150;
  static const double panel = 300;
}

/// 令牌注册表。
///
/// 校验器只认这里的键。没有注册的名字一律报错，**不做前缀模糊匹配**：
/// 允许模糊匹配等于给拼写错误开后门，而令牌名拼错在运行时不会崩——只会
/// 静默回退成默认值，那种 bug 最难查。
abstract final class FideTokens {
  /// 全部已注册令牌，键为 `group/variant` 形式。
  static const Map<String, FideToken> _registry = {
    // 颜色：角色名而非原始名，物料只能引用语义。
    'accent/primary': FideToken(
      name: 'accent/primary',
      kind: FideTokenKind.color,
      value: FideRawColor.ink,
    ),
    'accent/strong': FideToken(
      name: 'accent/strong',
      kind: FideTokenKind.color,
      value: FideRawColor.inkStrong,
    ),
    'ink/primary': FideToken(
      name: 'ink/primary',
      kind: FideTokenKind.color,
      value: FideRawColor.ink,
    ),
    'ink/secondary': FideToken(
      name: 'ink/secondary',
      kind: FideTokenKind.color,
      value: FideRawColor.ink60,
    ),
    'ink/tertiary': FideToken(
      name: 'ink/tertiary',
      kind: FideTokenKind.color,
      value: FideRawColor.ink45,
    ),
    'ink/disabled': FideToken(
      name: 'ink/disabled',
      kind: FideTokenKind.color,
      value: FideRawColor.ink30,
    ),
    'surface/base': FideToken(
      name: 'surface/base',
      kind: FideTokenKind.color,
      value: FideRawColor.surface,
    ),
    'surface/canvas': FideToken(
      name: 'surface/canvas',
      kind: FideTokenKind.color,
      value: FideRawColor.canvas,
    ),
    'surface/inset': FideToken(
      name: 'surface/inset',
      kind: FideTokenKind.color,
      value: FideRawColor.inset,
    ),
    'line/base': FideToken(
      name: 'line/base',
      kind: FideTokenKind.color,
      value: FideRawColor.line,
    ),
    'line/soft': FideToken(
      name: 'line/soft',
      kind: FideTokenKind.color,
      value: FideRawColor.lineSoft,
    ),
    'status/danger': FideToken(
      name: 'status/danger',
      kind: FideTokenKind.color,
      value: FideRawColor.danger,
    ),
    'status/warning': FideToken(
      name: 'status/warning',
      kind: FideTokenKind.color,
      value: FideRawColor.warning,
    ),

    // 间距。
    'space/1': FideToken(
      name: 'space/1',
      kind: FideTokenKind.space,
      value: FideSpaceRaw.x1,
    ),
    'space/2': FideToken(
      name: 'space/2',
      kind: FideTokenKind.space,
      value: FideSpaceRaw.x2,
    ),
    'space/3': FideToken(
      name: 'space/3',
      kind: FideTokenKind.space,
      value: FideSpaceRaw.x3,
    ),
    'space/4': FideToken(
      name: 'space/4',
      kind: FideTokenKind.space,
      value: FideSpaceRaw.x4,
    ),
    'space/5': FideToken(
      name: 'space/5',
      kind: FideTokenKind.space,
      value: FideSpaceRaw.x5,
    ),
    'space/6': FideToken(
      name: 'space/6',
      kind: FideTokenKind.space,
      value: FideSpaceRaw.x6,
    ),
    'space/7': FideToken(
      name: 'space/7',
      kind: FideTokenKind.space,
      value: FideSpaceRaw.x7,
    ),
    'space/8': FideToken(
      name: 'space/8',
      kind: FideTokenKind.space,
      value: FideSpaceRaw.x8,
    ),

    // 圆角。
    'radius/xs': FideToken(
      name: 'radius/xs',
      kind: FideTokenKind.radius,
      value: FideRadiusRaw.xs,
    ),
    'radius/sm': FideToken(
      name: 'radius/sm',
      kind: FideTokenKind.radius,
      value: FideRadiusRaw.sm,
    ),
    'radius/md': FideToken(
      name: 'radius/md',
      kind: FideTokenKind.radius,
      value: FideRadiusRaw.md,
    ),
    'radius/lg': FideToken(
      name: 'radius/lg',
      kind: FideTokenKind.radius,
      value: FideRadiusRaw.lg,
    ),
    'radius/xl': FideToken(
      name: 'radius/xl',
      kind: FideTokenKind.radius,
      value: FideRadiusRaw.xl,
    ),
    'radius/pill': FideToken(
      name: 'radius/pill',
      kind: FideTokenKind.radius,
      value: FideRadiusRaw.pill,
    ),

    // 字号：`style:` 属性引用的就是这一组。
    'display/large': FideToken(
      name: 'display/large',
      kind: FideTokenKind.fontSize,
      value: FideFontSize.displayLarge,
    ),
    'display/medium': FideToken(
      name: 'display/medium',
      kind: FideTokenKind.fontSize,
      value: FideFontSize.displayMedium,
    ),
    'display/small': FideToken(
      name: 'display/small',
      kind: FideTokenKind.fontSize,
      value: FideFontSize.displaySmall,
    ),
    'title/large': FideToken(
      name: 'title/large',
      kind: FideTokenKind.fontSize,
      value: FideFontSize.titleLarge,
    ),
    'title/medium': FideToken(
      name: 'title/medium',
      kind: FideTokenKind.fontSize,
      value: FideFontSize.titleMedium,
    ),
    'title/small': FideToken(
      name: 'title/small',
      kind: FideTokenKind.fontSize,
      value: FideFontSize.titleSmall,
    ),
    'body/large': FideToken(
      name: 'body/large',
      kind: FideTokenKind.fontSize,
      value: FideFontSize.bodyLarge,
    ),
    'body/medium': FideToken(
      name: 'body/medium',
      kind: FideTokenKind.fontSize,
      value: FideFontSize.bodyMedium,
    ),
    'body/small': FideToken(
      name: 'body/small',
      kind: FideTokenKind.fontSize,
      value: FideFontSize.bodySmall,
    ),
    'label/medium': FideToken(
      name: 'label/medium',
      kind: FideTokenKind.fontSize,
      value: FideFontSize.labelMedium,
    ),
    'label/small': FideToken(
      name: 'label/small',
      kind: FideTokenKind.fontSize,
      value: FideFontSize.labelSmall,
    ),

    // 字重。
    'weight/body': FideToken(
      name: 'weight/body',
      kind: FideTokenKind.fontWeight,
      value: FideWeightRaw.body,
    ),
    'weight/subtle': FideToken(
      name: 'weight/subtle',
      kind: FideTokenKind.fontWeight,
      value: FideWeightRaw.subtle,
    ),
    'weight/title': FideToken(
      name: 'weight/title',
      kind: FideTokenKind.fontWeight,
      value: FideWeightRaw.title,
    ),
    'weight/control': FideToken(
      name: 'weight/control',
      kind: FideTokenKind.fontWeight,
      value: FideWeightRaw.control,
    ),
    'weight/strong': FideToken(
      name: 'weight/strong',
      kind: FideTokenKind.fontWeight,
      value: FideWeightRaw.strong,
    ),

    // 动效。
    'duration/tap': FideToken(
      name: 'duration/tap',
      kind: FideTokenKind.duration,
      value: FideDurationRaw.tap,
    ),
    'duration/snap': FideToken(
      name: 'duration/snap',
      kind: FideTokenKind.duration,
      value: FideDurationRaw.snap,
    ),
    'duration/hover': FideToken(
      name: 'duration/hover',
      kind: FideTokenKind.duration,
      value: FideDurationRaw.hover,
    ),
    'duration/panel': FideToken(
      name: 'duration/panel',
      kind: FideTokenKind.duration,
      value: FideDurationRaw.panel,
    ),
  };

  /// 全部已注册令牌。返回不可变视图，调用方不得改写。
  static Map<String, FideToken> get all => Map.unmodifiable(_registry);

  /// 按名字查令牌，不存在返回 `null`。
  ///
  /// 校验器用它判 `token-ref` 是否合法；codegen 用它把令牌名换成字面量。
  static FideToken? lookup(String name) => _registry[name];

  /// 是否已注册。比 `lookup(...) != null` 读起来更接近校验器的语气。
  static bool contains(String name) => _registry.containsKey(name);

  /// 按种类筛出全部令牌名，供属性面板渲染下拉选项。
  static List<String> namesOf(FideTokenKind kind) => _registry.values
      .where((t) => t.kind == kind)
      .map((t) => t.name)
      .toList(growable: false);
}

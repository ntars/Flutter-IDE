/// 设计令牌的 Flutter 适配层。
///
/// `fide_design` 是纯 Dart（颜色写成 `int`），因为内核与 CLI 不能依赖 Flutter。
/// 界面侧需要真正的 `Color` / `TextStyle`，所以在这一处做转换。
///
/// **只有这一个文件做转换。** 页面与组件一律引用本文件导出的常量，
/// 不自己写 `Color(0xFF...)`——不然「色值只在一处」这条就废了。
library;

import 'package:fide_design/fide_design.dart';

import 'ui.dart';

/// 把纯 Dart 的 ARGB 整数转成 [Color]。
Color fideColor(int argb) => Color(argb);

/// 颜色角色。名字与 `fide_design` 的令牌名一一对应。
abstract final class FideColors {
  static const Color accent = Color(FideRawColor.ink);
  static const Color accentStrong = Color(FideRawColor.inkStrong);
  static const Color ink = Color(FideRawColor.ink);
  static const Color inkSecondary = Color(FideRawColor.ink60);
  static const Color inkTertiary = Color(FideRawColor.ink45);
  static const Color inkDisabled = Color(FideRawColor.ink30);
  static const Color surface = Color(FideRawColor.surface);
  static const Color canvas = Color(FideRawColor.canvas);
  static const Color inset = Color(FideRawColor.inset);
  static const Color line = Color(FideRawColor.line);
  static const Color lineSoft = Color(FideRawColor.lineSoft);
  static const Color danger = Color(FideRawColor.danger);
  static const Color warning = Color(FideRawColor.warning);
}

/// 间距，短名便于在布局里读。
abstract final class FideGap {
  static const double x1 = FideSpaceRaw.x1;
  static const double x2 = FideSpaceRaw.x2;
  static const double x3 = FideSpaceRaw.x3;
  static const double x4 = FideSpaceRaw.x4;
  static const double x5 = FideSpaceRaw.x5;
  static const double x6 = FideSpaceRaw.x6;
  static const double x7 = FideSpaceRaw.x7;
  static const double x8 = FideSpaceRaw.x8;
}

/// 圆角。
abstract final class FideRadii {
  static const double xs = FideRadiusRaw.xs;
  static const double sm = FideRadiusRaw.sm;
  static const double md = FideRadiusRaw.md;
  static const double lg = FideRadiusRaw.lg;
  static const double xl = FideRadiusRaw.xl;

  /// 胶囊。用 999 而不是 9999：两者在视觉上等价，但 999 换算成
  /// `Radius.circular` 时不会被误读成「一个具体的量」。
  static const double pill = FideRadiusRaw.pill;
}

/// 统一的文字构造。
///
/// 字重走 `FontVariation` 轴值而非 `FontWeight`：只声明一个 wght 轴的可变
/// 字体上请求 w700，渲染层会补一次合成加粗，笔画发糊、字宽跳动。这是
/// Ondra 里实测过的结论，此处沿用。
TextStyle fideText(
  double size, {
  double weight = FideWeightRaw.body,
  Color? color,
  double? height,
  double? spacing,
}) => TextStyle(
  fontSize: size,
  fontVariations: [FontVariation('wght', weight)],
  color: color,
  height: height,
  letterSpacing: spacing,
  // 中文在桌面上不该被强行撑开字距。
  leadingDistribution: TextLeadingDistribution.even,
);

/// 全应用主题。
///
/// 只做三件事：给定色板、去掉 Material 3 的默认染色、把字体统一到 [fideText]。
/// 骨架阶段不做深色——主题模式要动原生窗口的 `NSAppearance`，那是平台层的事，
/// 半成品深色比没有深色更糟。
ThemeData fideTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: FideColors.accent,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: FideColors.canvas,
  );
  return base.copyWith(
    // IDE 里不该出现水波纹：面板点击是「选中」不是「涟漪」。
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textTheme: base.textTheme.apply(
      bodyColor: FideColors.ink,
      displayColor: FideColors.ink,
    ),
  );
}

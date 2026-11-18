/// Fide 设计层：令牌 + 断点策略表。
///
/// 这一层是**纯 Dart**（`dart:ui` 都不用，颜色写成 `int` 的 ARGB），原因有二：
///
/// 1. 校验器要判断 `type: token-ref` 的属性指向的令牌是否存在。若令牌定义在
///    Flutter 包里，`ide_core` 就得依赖 Flutter，内核也就再也不能「脱离 IDE
///    用 CLI 跑」（方案 §6.1 的关键决策）。
/// 2. 断点策略要被 codegen 读，而 codegen 是纯 Dart。
///
/// 界面侧用一个极薄的适配把它转成 `Color`，见 `packages/ide_app/lib/app/tokens.dart`。
library;

export 'src/breakpoints.dart';
export 'src/tokens.dart';

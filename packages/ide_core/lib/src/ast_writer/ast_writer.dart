/// AST 写回：analyzer + 区间精确替换（方案 §7.2）。
///
/// **不做整文件重排，做区间替换。** 步骤：
///
/// ```
/// 1. parseString(source) 得到 AST
/// 2. 按 Semantics.identifier 找到目标 Widget 表达式节点
/// 3. 定位目标参数的实参节点，取 offset / length
/// 4. 用新字面量替换该区间文本
/// 5. 仅对该区间跑格式化对齐
/// 6. 写盘 → hot reload
/// ```
///
/// 关于「Dart 没有 recast」这件事，方案 §7.2 的判断基本正确但不完整：
/// `dart_style` 确实会重排整个文件，但 diff 噪声还有第二个来源——**formatter
/// 版本差异**。`dart_style` 3.7 引入 tall-style 格式化器，与 2.x 输出不兼容，
/// 同一份代码在两个版本下 diff 是整文件级别。所以三条纪律之外必须加一条：
/// **锁定 formatter 版本并写进锁文件**，否则 CI 与本地会互相覆盖。
library;

import 'package:analyzer/dart/analysis/utilities.dart';

/// 一处待替换的文本区间。
///
/// 用 offset + length 而不是 start/end：analyzer 的 AST 节点本身就是这个
/// 表示法，转换路径最短，也少一次「end 含不含」的歧义。
final class FideTextEdit {
  const FideTextEdit({
    required this.offset,
    required this.length,
    required this.replacement,
  });

  final int offset;
  final int length;
  final String replacement;

  @override
  String toString() => 'Edit($offset, $length → ${replacement.trim()})';
}

/// 写回结果。
final class FideWriteResult {
  const FideWriteResult({
    required this.success,
    this.source,
    this.error,
    this.edits = const [],
  });

  final bool success;

  /// 替换后的完整源码。失败时为 `null`。
  final String? source;

  /// 失败原因。写成「人话 + 定位」，因为这条信息会直接显示在 IDE 上。
  final String? error;

  /// 实际应用的全部替换。用于「改了哪几处」的确认提示。
  final List<FideTextEdit> edits;
}

/// 区间写回器。
abstract final class FideAstWriter {
  /// 定位某个 `Semantics(identifier: 'target')` 包住的 Widget 表达式。
  ///
  /// 返回该表达式的 `(offset, length)`，找不到返回 `null`。
  ///
  /// 为什么按 `identifier` 而不是按变量名或行号：
  /// - 行号在大规模重排后失效；
  /// - 变量名可能被格式化或重命名；
  /// - `Semantics(identifier:)` 是生成时写入源码的稳定字符串，重构后仍有效
  ///   （方案 §5.2 的「双锚点互补」）。
  static FideRange? locateByIdentifier(String source, String identifier) {
    // 先确认这份源码能被解析。语法错的源码里找不到锚点是正常结果，不该抛异常。
    final parsed = parseString(content: source, throwIfDiagnostics: false);
    if (parsed.errors.isNotEmpty) return null;

    // TODO(skeleton): 实现 RecursiveAstVisitor：
    //   重写 visitMethodInvocation，命中 `Semantics` 且其 `identifier:` 具名
    //   参数的字符串字面量等于 identifier 时，取 `child:` 参数表达式的
    //   (offset, length) 返回。多个匹配视为错误（id 本应唯一，校验器已保证）。
    //
    // 现在直接返回 null，让调用方走「不写回」分支——这比返回一个猜的区间安全：
    // 猜错的区间会改坏别的属性，而返回 null 只是这次没改成功。
    return null;
  }

  /// 把一个属性替换成新值。
  ///
  /// 骨架阶段只实现「整段表达式替换」这一种编辑，也就是把
  /// `fontSize: 24` 里的 `24` 换成 `40`。更复杂的编辑（增删参数）留待后续。
  static FideWriteResult replaceProperty({
    required String source,
    required FideRange range,
    required String replacement,
  }) {
    if (range.offset < 0 || range.offset + range.length > source.length) {
      return const FideWriteResult(
        success: false,
        error: '替换区间越界，已放弃写入（源文件未改动）。',
      );
    }

    final edit = FideTextEdit(
      offset: range.offset,
      length: range.length,
      replacement: replacement,
    );

    final next = source.replaceRange(
      edit.offset,
      edit.offset + edit.length,
      edit.replacement,
    );

    // 写回后必须自检：区间算错会产出语法错误的文件，而这种错误在编辑器里
    // 可能被缓存掩盖，等到 `flutter run` 才炸。方案 §11.2 的应对是
    // 「写回前后跑 dart analyze，失败自动回滚」——这里先做语法级自检，
    // 完整的 analyze 由调用方在写盘后执行。
    final check = parseString(content: next, throwIfDiagnostics: false);
    if (check.errors.isNotEmpty) {
      return FideWriteResult(
        success: false,
        error: '替换后源码存在语法错误，已放弃写入：${check.errors.first.message}',
      );
    }

    return FideWriteResult(success: true, source: next, edits: [edit]);
  }
}

/// 源码中的一段区间。
final class FideRange {
  const FideRange({required this.offset, required this.length});

  final int offset;
  final int length;

  @override
  String toString() => 'FideRange($offset, $length)';
}

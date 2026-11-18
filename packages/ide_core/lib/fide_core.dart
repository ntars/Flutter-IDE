/// Fide 内核。
///
/// 纯 Dart 库，**不依赖 Flutter**。可以完全脱离 IDE 用 CLI 调用（方案 §6.1）。
/// 这带来三个好处，也是它必须保持纯 Dart 的理由：
///
/// - CI 可跑：`dart run fide_cli build` 能进流水线，不需要图形环境；
/// - 可单测：所有逻辑都在 `dart test` 覆盖范围内，不用 widget test；
/// - 桌面端崩了也不影响构建：界面只是内核的一个视图（方案 §4.1）。
///
/// 分层与依赖方向：
///
/// ```
/// project_model  ← 读 intent / delta / 物料 spec
///      ↓
/// validator      ← 校验，失败即拒绝，不产出半成品
///      ↓
/// codegen        ← intent + delta → Dart 源码片段（纯字符串，不落盘）
///      ↓
/// ast_writer     ← analyzer + 区间替换，把片段写回真实文件
///      ↓
/// vm_bridge      ← 连 VM Service，点选与热重载（唯一与运行中进程打交道的层）
///      ↓
/// metrics        ← 同步率统计，给面板读数
/// ```
///
/// 依赖只向下，不向上。`vm_bridge` 不知道 codegen 的存在，`codegen` 也不知道
/// 文件系统——它只产出字符串。这条界让每一层都能单独替换。
library;

export 'src/ast_writer/ast_writer.dart';
export 'src/codegen/codegen.dart';
export 'src/metrics/metrics.dart';
export 'src/project_model/delta.dart';
export 'src/project_model/intent.dart';
export 'src/project_model/node.dart';
export 'src/project_model/project.dart';
export 'src/validator/validator.dart';
export 'src/vm_bridge/vm_bridge.dart';

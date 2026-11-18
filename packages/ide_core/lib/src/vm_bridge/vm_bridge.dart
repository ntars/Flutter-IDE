/// VM Service 桥：点选与热重载（方案 §7.1）。
///
/// **这是内核里唯一与运行中进程打交道的层。** 它上面是界面，下面是 Flutter
/// 运行时，中间不夹任何其他逻辑——这层越薄，出问题越好查。
///
/// 一条重要判断：属性面板显示的是**运行时算出来的真值**，不是从源码文本里
/// 猜的。方案 §7.1 说这一步「能砍掉大量解析 bug」——准确地说，它把一整类
/// bug 从「解析结果和实际渲染不一致」变成「不需要解析」。所以面板的数据源
/// 必须是本层的 `diagnostics`，不能是 ast_writer 的读源码结果。
library;

import 'package:vm_service/vm_service.dart';

/// 一个被选中的 Widget 的运行时快照。
///
/// 两侧信息合起来才是完整锚点（方案 §5.2）：
/// - [file] + [line] + [column] 来自 `creationLocation`，精确但 release 不保留；
/// - [identifier] 来自生成时写入源码的 `Semantics(identifier:)`，跨版本稳定。
///
/// **点选优先用前者，写回用后者。** 这样即使文件被大规模重排，写回也不会
/// 打错地方。
final class FideSelection {
  const FideSelection({
    required this.file,
    required this.line,
    required this.column,
    required this.identifier,
    required this.diagnostics,
    required this.widgetName,
  });

  /// 源码文件路径（运行时给出的是 URI，已转成本地路径）。
  final String file;

  /// 1 起始的行号。
  final int line;

  /// 1 起始的列号。
  final int column;

  /// 稳定标识。没有写 `Semantics(identifier:)` 时为 `null`——这种节点
  /// 只能显示、不能写回，界面必须如实灰显（方案 §11.2「不假装能改」）。
  final String? identifier;

  /// 运行时属性真值。键是 Widget 的字段名（`fontSize`、`width`…）。
  final Map<String, Object?> diagnostics;

  /// Widget 类型名，用于在面板标题里显示「你在选中什么」。
  final String widgetName;

  /// 是否可以写回。没有 identifier 就只能看。
  bool get writable => identifier != null;
}

/// VM Service 桥。
///
/// 连接生命周期由调用方管：IDE 在窗口打开时连、关闭时断。CLI 一般不连
/// （它只做 codegen），所以本层不会在构造时自动连。
final class FideVmBridge {
  FideVmBridge(this._service);

  final VmService _service;

  /// 订阅选中事件。
  ///
  /// 实现要点（方案 §7.1 的伪代码）：`enableWidgetInspector` 之后订阅
  /// `InspectorService` 的选中流，把 `creationLocation` 与 `semanticsIdentifier`
  /// 一起取出。`diagnostics` 需要额外请求一次 `getSelectedWidget`，
  /// 不能从选中事件里拿——事件只带 id。
  ///
  /// 返回取消订阅函数，调用方在面板关闭时调用。
  Future<void Function()> onSelect(void Function(FideSelection) handler) async {
    // TODO(skeleton): 具体实现顺序：
    //   1. await _service.callServiceExtension('ext.flutter.inspector.setPubRootDirectories');
    //   2. 订阅 onExtensionEvent 里的 'ext.flutter.inspector.selectedWidget';
    //   3. 用 objectId 调 'ext.flutter.inspector.getSelectedWidget' 取 diagnostics；
    //   4. 组装 FideSelection 交给 handler。
    throw UnimplementedError('FideVmBridge.onSelect 待实现（骨架阶段）');
  }

  /// 触发一次热重载。写回成功后调用。
  ///
  /// 失败不抛异常：热重载失败通常意味着用户的代码有编译错误，那是一个
  /// 需要显示在界面上的状态，不是程序异常。
  Future<FideReloadResult> hotReload() async {
    // TODO(skeleton): 调 _service.callMethod('reloadSources') 并解析结果。
    throw UnimplementedError('FideVmBridge.hotReload 待实现（骨架阶段）');
  }

  /// 断开连接。
  Future<void> dispose() async {
    await _service.dispose();
  }
}

/// 热重载结果。
final class FideReloadResult {
  const FideReloadResult({required this.success, this.detail});

  final bool success;

  /// 失败时的编译错误摘要。要给到界面，因为用户需要知道改坏了什么。
  final String? detail;
}

/// 应用外壳状态。
///
/// 用 `ChangeNotifier` + 一个实例，不引状态管理库。理由与 Ondra 的做法一致：
/// 桌面 IDE 的状态是「一屏之内的一组选中项与开关」，用不上依赖注入、
/// 也用不上响应式流。引入一个库只会让「clone 下来就能跑」多一道理解成本。
///
/// 状态只存**界面自身**的开关（哪一页、选中哪个节点、面板开合）。
/// **意图树与源码不在这里**——它们是真源的投影，每次都从内核读，
/// 存一份副本就出现了两个真源（违反方案 §4.1）。
library;

import 'package:flutter/foundation.dart';

/// 五个面板的可见性。IDE 的骨架就是这五个格子，别的一概没有。
enum FidePanel {
  /// 大纲：意图树。
  outline,

  /// 画布：内嵌运行的 Flutter 目标。
  canvas,

  /// 属性：由 spec + delta 生成。
  props,

  /// 冲突仲裁。
  conflict,

  /// 同步率。
  metrics,
}

/// 应用外壳状态。
final class FideShellState extends ChangeNotifier {
  bool _outlineVisible = true;
  bool _propsVisible = true;
  String? _selectedNodeId;
  String? _activePageId;

  bool get outlineVisible => _outlineVisible;
  bool get propsVisible => _propsVisible;

  /// 当前选中的意图节点。`null` 表示没有选中，属性面板显示空态。
  String? get selectedNodeId => _selectedNodeId;

  /// 当前打开的页面。
  String? get activePageId => _activePageId;

  /// 选中一个节点。相同 id 不重复通知——滚动与悬停会高频触发它。
  void selectNode(String? nodeId) {
    if (_selectedNodeId == nodeId) return;
    _selectedNodeId = nodeId;
    notifyListeners();
  }

  /// 切换页面。切页会清掉选中，因为节点 id 在页面之间不通用。
  void openPage(String? pageId) {
    if (_activePageId == pageId) return;
    _activePageId = pageId;
    _selectedNodeId = null;
    notifyListeners();
  }

  void toggleOutline() {
    _outlineVisible = !_outlineVisible;
    notifyListeners();
  }

  void toggleProps() {
    _propsVisible = !_propsVisible;
    notifyListeners();
  }
}

/// 根组件。
///
/// 只做三件事：建主题、持有外壳状态、装上外壳。**不在这里读项目、不连 VM**——
/// 那些是 `main.dart` 的启动时序，与界面装配分开。
library;

import 'ui.dart';

import 'shell.dart';
import 'shell_state.dart';
import 'tokens.dart';

/// 应用根。
class FideApp extends StatefulWidget {
  const FideApp({super.key});

  @override
  State<FideApp> createState() => _FideAppState();
}

class _FideAppState extends State<FideApp> {
  /// 外壳状态的生命周期跟着 App，不跟着某个面板：
  /// 选中项要在面板之间共享，挂到面板上会导致切面板时丢状态。
  final FideShellState _state = FideShellState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fide',
      debugShowCheckedModeBanner: false,
      theme: fideTheme(),
      home: FideShell(state: _state),
    );
  }
}

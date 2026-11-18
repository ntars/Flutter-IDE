// Fide 桌面端入口。
//
// 启动时序（顺序有理由，不要重排）：
//
// 1. `ensureInitialized`：之后才能用平台通道；
// 2. 读项目：第一帧就要有大纲，晚读会让界面闪一次空态；
// 3. `runApp`：先出窗口，再连运行中的目标；
// 4. 连 VM Service：**放在 runApp 之后**。连接慢或失败都不该让窗口空着，
//    这与 Ondra 的处理一致（首帧不等内核）。
//
// 骨架阶段第 2、4 步未接，各留一行 TODO 与说明。
import 'app/ui.dart';

import 'app/fide_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO(skeleton): 读项目并解析意图大纲。
  //   final project = FideProject.open(projectRoot);
  //   final result = project?.readIntent('home');
  // 结果交给 shell state，界面从 state 读——界面不自己读盘。

  runApp(const FideApp());

  // TODO(skeleton): 在首帧之后连 VM Service。
  //   final bridge = await FideVmBridge.connect(wsUri);
  //   await bridge.onSelect(state.selectNode);
  // 连接失败不是启动失败：界面照常起来，画布显示「未连接」。
}

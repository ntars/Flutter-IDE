/// 画布容器（方案 §6.1）：内嵌 `flutter run` 运行中的目标。
///
/// 真正的画布需要把另一个 Flutter 进程的画面嵌进来。桌面端有三条路，
/// 骨架阶段**先不选**，只把三者的代价写在下面，等阶段一的里程碑去实测：
///
/// | 方式 | 做法 | 代价 |
/// |---|---|---|
/// | 独立窗口 + 截帧 | 目标跑在子进程里，定时抓帧贴到本面板 | 交互延迟高，滚动不跟手 |
/// | 平台视图嵌入 | 原生侧把子进程窗口挂成子视图（macOS `addChildWindow`） | 只能桌面，Web 端没有 |
/// | 不嵌，只做点选 | 目标跑在自己的窗口里，IDE 只连 VM Service 做点选与写回 | 没有「画布」，但点选链路完整 |
///
/// 第三条是阶段一验收（「改一个属性，git diff 只有一行」）需要的最小形态，
/// 所以骨架先按它留出位置：这个面板现在显示的是「未连接」，而不是一个
/// 假的可视化编辑区。假画布比没有画布更糟——它会让人以为功能已经存在。
library;

import '../app/ui.dart';

import '../app/tokens.dart';

/// 画布面板。
class CanvasPanel extends StatelessWidget {
  const CanvasPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: FideGap.x3),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Text(
                '画布',
                style: fideText(13, weight: 500, color: FideColors.ink),
              ),
              const SizedBox(width: FideGap.x2),
              Text('未连接', style: fideText(11, color: FideColors.inkTertiary)),
              const Spacer(),
              // 断点档位切换：它改变的是「画布按多宽排版」，
              // 而组件内部用的是 LayoutBuilder，所以这里切档等于改容器宽度。
              for (final id in const ['compact', 'medium', 'expanded'])
                Padding(
                  padding: const EdgeInsets.only(left: FideGap.x1),
                  child: _SizeChip(label: id, active: id == 'expanded'),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: FideColors.lineSoft),
        Expanded(
          child: Container(
            color: FideColors.canvas,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_circle_outline,
                    size: 32,
                    color: FideColors.inkDisabled,
                  ),
                  const SizedBox(height: FideGap.x3),
                  Text(
                    '尚未连接运行中的目标',
                    style: fideText(
                      13,
                      weight: 500,
                      color: FideColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: FideGap.x1),
                  SizedBox(
                    width: 380,
                    child: Text(
                      '连上 VM Service 之后，这里显示运行中的界面，'
                      '点一下就能在大纲与属性面板里定位到对应节点。'
                      '属性面板显示的是运行时真值，不是从源码猜的。',
                      textAlign: TextAlign.center,
                      style: fideText(
                        11,
                        color: FideColors.inkTertiary,
                        height: 16 / 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 档位切换小胶囊。
class _SizeChip extends StatelessWidget {
  const _SizeChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: FideGap.x2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? FideColors.inset : Colors.transparent,
        borderRadius: BorderRadius.circular(FideRadii.pill),
      ),
      child: Text(
        label,
        style: fideText(
          10,
          weight: active ? 500 : 330,
          color: active ? FideColors.ink : FideColors.inkTertiary,
        ),
      ),
    );
  }
}

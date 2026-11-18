/// 桌面外壳：左栏导航 + 大纲 + 画布 + 右栏（属性 / 冲突 / 同步率）。
///
/// 布局按「先量宽、再决定几栏」的顺序做，用 `LayoutBuilder` 而不是
/// `MediaQuery`——理由与组件层同一条原则：只看自己被分到多宽
/// （方案 §7.4）。窗口拉窄时右栏先让位，不是画布先塌。
library;

import 'ui.dart';

import '../canvas/canvas_panel.dart';
import '../conflict_panel/conflict_panel.dart';
import '../metrics_panel/metrics_panel.dart';
import '../outline_panel/outline_panel.dart';
import '../props_panel/props_panel.dart';
import 'shell_state.dart';
import 'tokens.dart';
import 'version.dart';

/// 右侧竖排的三个面板用切换而不是并列：1400 宽下再塞三栏，
/// 每栏都窄到放不下一行「属性名 + 值」。
enum _RightTab { props, conflict, metrics }

/// 应用外壳。
class FideShell extends StatefulWidget {
  const FideShell({super.key, required this.state});

  final FideShellState state;

  @override
  State<FideShell> createState() => _FideShellState();
}

class _FideShellState extends State<FideShell> {
  _RightTab _rightTab = _RightTab.props;

  @override
  void initState() {
    super.initState();
    // 外壳只监听「选中」与「页」这两件事：它们是重绘面板的唯一原因。
    widget.state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;

    return Scaffold(
      backgroundColor: FideColors.canvas,
      body: LayoutBuilder(
        builder: (context, box) {
          // 1100 以下收起大纲与右栏，只留画布。骨架阶段不做抽屉——
          // 抽屉要么有动画、要么会挡住画布，两者都得实测过才敢放进去。
          final wide = box.maxWidth >= fideWindowMinWidth;

          return Row(
            children: [
              const _Sidebar(),
              const VerticalDivider(width: 1, color: FideColors.lineSoft),
              if (wide && s.outlineVisible) ...[
                SizedBox(
                  width: 260,
                  child: OutlinePanel(
                    selectedNodeId: s.selectedNodeId,
                    onSelect: s.selectNode,
                  ),
                ),
                const VerticalDivider(width: 1, color: FideColors.lineSoft),
              ],
              const Expanded(child: CanvasPanel()),
              if (wide) ...[
                const VerticalDivider(width: 1, color: FideColors.lineSoft),
                SizedBox(
                  width: fidePropsPanelWidth,
                  child: Column(
                    children: [
                      _RightTabBar(
                        active: _rightTab,
                        onChanged: (t) => setState(() => _rightTab = t),
                      ),
                      const Divider(height: 1, color: FideColors.lineSoft),
                      Expanded(
                        child: switch (_rightTab) {
                          _RightTab.props => PropsPanel(
                            selectedNodeId: s.selectedNodeId,
                          ),
                          _RightTab.conflict => const ConflictPanel(),
                          _RightTab.metrics => const MetricsPanel(),
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// 右栏的切换条。三个面板共用一条，避免每个面板各带一个表头。
class _RightTabBar extends StatelessWidget {
  const _RightTabBar({required this.active, required this.onChanged});

  final _RightTab active;
  final ValueChanged<_RightTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: FideGap.x2),
      child: Row(
        children: [
          for (final tab in _RightTab.values)
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onChanged(tab),
                  child: Container(
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == active
                          ? FideColors.inset
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(FideRadii.sm),
                    ),
                    child: Text(
                      switch (tab) {
                        _RightTab.props => '属性',
                        _RightTab.conflict => '冲突',
                        _RightTab.metrics => '同步率',
                      },
                      style: fideText(
                        12,
                        weight: tab == active ? 500 : 330,
                        color: tab == active
                            ? FideColors.ink
                            : FideColors.inkTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 左栏导航。
///
/// 只有三组：项目（页面列表）、物料、设置。骨架阶段不做图标栏——
/// 240 宽足够直接放文字，加图标只会让菜单变成一列符号。
class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fideSidebarWidth,
      color: FideColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 表头：品牌 + 版本。高度 48 与大纲表头一致，两条分割线才会连成一根。
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: FideGap.x3),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(
                  fideProductName,
                  style: fideText(14, weight: 500, color: FideColors.ink),
                ),
                const SizedBox(width: FideGap.x2),
                Text(
                  'v$fideVersion',
                  style: fideText(10, color: FideColors.inkTertiary),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: FideColors.lineSoft),
          const _NavGroupLabel('页面'),
          const _NavItem(label: 'home', active: true),
          const _NavGroupLabel('物料'),
          const _NavItem(label: 'ntars.text'),
          const _NavItem(label: 'ntars.button'),
          const _NavItem(label: 'ntars.card'),
          const Spacer(),
          const Divider(height: 1, color: FideColors.lineSoft),
          Padding(
            padding: const EdgeInsets.all(FideGap.x3),
            child: Text(
              fideStage,
              style: fideText(
                10,
                color: FideColors.inkTertiary,
                height: 15 / 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 分组标题。
class _NavGroupLabel extends StatelessWidget {
  const _NavGroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: FideGap.x3,
        top: FideGap.x3,
        bottom: FideGap.x1,
      ),
      child: Text(
        text,
        style: fideText(10, weight: 500, color: FideColors.inkTertiary),
      ),
    );
  }
}

/// 导航项。30 高、圆角 6、左内距 8——与大纲行高对齐。
class _NavItem extends StatelessWidget {
  const _NavItem({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FideGap.x2, vertical: 1),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: FideGap.x2),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: active ? FideColors.inset : Colors.transparent,
          borderRadius: BorderRadius.circular(FideRadii.sm),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: fideText(
            13,
            weight: active ? 500 : 330,
            color: active ? FideColors.ink : FideColors.inkSecondary,
          ),
        ),
      ),
    );
  }
}

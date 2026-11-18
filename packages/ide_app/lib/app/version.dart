/// 产品标识与窗口基线。
///
/// 版本号与 `pubspec.yaml` 保持一致（`+N` 是构建号，不写在这里）。
///
/// **名字分三处写，各有各的用途**，不要合成一个：
/// - [fideProductName]：界面里显示的名字。
/// - [fideWindowTitle]：窗口标题。
/// - 进程名：由原生侧决定（`macos/Runner/Configs/AppInfo.xcconfig`）。
///
/// 产品名刻意**不含 Flutter**：`Flutter` 是 Google 的商标，Google 品牌指南
/// 限制第三方暗示官方背书（方案 §16）。文档里描述为「a visual IDE for Flutter」
/// 是安全的，把它放进产品名不是。骨架阶段用技术标识 `Fide` 占位，
/// 正式品牌名与商标在阶段三落地。
library;

/// 界面里显示的短名。侧栏只有 200 宽，全名会把菜单挤窄。
const String fideProductName = 'Fide';

/// 窗口标题。
const String fideWindowTitle = 'Fide';

/// 一句话定位。
const String fideSlogan = '源码优先的 Flutter 可视化搭建 IDE';

const String fideVersion = '0.1.0';
const String fideStage = '骨架 · 内核已可独立运行，界面待接';

/// 主窗尺寸。
///
/// 1400×900 是五个面板并列的下限：大纲 260 + 属性 300 之后再留画布，
/// 1400 才不至于让画布窄过 840（expanded 档位）。
const double fideWindowWidth = 1400;
const double fideWindowHeight = 900;
const double fideWindowMinWidth = 1100;
const double fideWindowMinHeight = 700;

/// 侧栏宽度。与 Ondra 的 200 对齐，是「中文菜单项 + 图标」的舒适下限。
const double fideSidebarWidth = 240;

/// 属性面板宽度。300 能放下「属性名 + 令牌下拉」一行。
const double fidePropsPanelWidth = 300;

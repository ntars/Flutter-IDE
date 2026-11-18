# Flutter-IDE

源码优先的可视化搭建 IDE：**不锁定、源码归你**。在画布上拖拽、在属性面板上改值，产出的永远是干净、可读、可脱离工具维护的 Dart 代码。

> **Not affiliated with or endorsed by Google.** `Flutter` 是 Google 的商标；
> 本项目与其无关，「Flutter-IDE」只是仓库的技术标识，产品名与商标走独立注册
> （见 [TRADEMARK.md](TRADEMARK.md)）。

判定这个项目是否成立的唯一标准：

> 把 Flutter-IDE 删掉，项目还能不能正常 `flutter run`、正常被人接手开发？

能，这个项目就成立；不能，它就是又一个私有 Schema 平台。所以本仓库**没有任何
只存在于工具内部、不在磁盘文件里的项目结构**——意图大纲、覆盖层、设计令牌
全是进 git 的明文文件。

---

## 它不是什么

先划清边界，防止范围蔓延（完整非目标清单见 `docs/architecture.md`）：

| 不做 | 理由 |
|---|---|
| 可视化逻辑编程 | 业务流程、状态管理、请求封装一律手写 Dart。可视化逻辑图的维护成本高于直接读代码 |
| 平台后端 | 不提供托管数据库、认证、云函数。绑定后端等于重演「出码断联」 |
| 运行时 AI | 任何需要在页面打开时调用模型的路径一律不做。AI 只在生成期介入，产物进 git |
| 100% 自动 | 信息架构迁移、密度档位必须由人声明。自动得越多，错的越 silent |

## 三条核心理念

1. **源码是唯一真源**。设计器、属性面板、画布都只是源码的视图，不是持有者。
2. **意图是一等公民**。组件只说「我是什么、我多重要、窄屏时去哪」，
   不说「我在第几行第几列」。排布权归容器，身份权归叶子。
3. **生成时决策，运行时不决策**。人填意图 → 生成器产布局 → 校验器与
   golden test 把关 → 人看 diff → commit。运行时零 AI、纯静态、完全可复现。

## 架构

```
┌──────────────────────────────────────────────┐
│  ide_app（Flutter Desktop 界面）               │
│  ├─ 画布容器        ├─ 大纲面板                │
│  ├─ 属性面板        ├─ 冲突仲裁                │
│  └─ 同步率面板                                │
├──────────────────────────────────────────────┤
│  ide_core（纯 Dart 内核，可独立 CLI 跑）        │
│  ├─ project_model   intent / delta / 令牌      │
│  ├─ codegen         intent+delta → Dart 片段   │
│  ├─ ast_writer      analyzer + 区间精确写回     │
│  ├─ vm_bridge       VM Service 点选与热重载     │
│  ├─ validator       五条硬规则                 │
│  └─ metrics         同步率 auto/patch/orphan   │
├──────────────────────────────────────────────┤
│  material_sdk（物料协议）+ design（令牌与断点） │
├──────────────────────────────────────────────┤
│  cli（CI 入口）                                │
└──────────────────────────────────────────────┘
```

**内核与界面分离**是关键决策：内核不依赖 Flutter，`dart test` 可单测、CI 可跑、
桌面端崩了不影响构建。这个论断由 `packages/cli/` 证明——它能独立完成校验与物料检查。

## 目录结构

```
Flutter-IDE/
├── LICENSE               Apache-2.0（内核/SDK/物料）
├── LICENSE-MIT           MIT（界面/模板/文档）
├── LICENSING.md          分层路由表
├── NOTICE                第三方披露 + 生成代码豁免
├── CONTRIBUTING.md       DCO 说明
├── TRADEMARK.md          品牌使用规则
│
├── packages/
│   ├── ide_core/         纯 Dart 内核，无 Flutter 依赖
│   ├── ide_app/          Flutter Desktop 外壳（五面板）
│   ├── material_sdk/     物料协议：第三方可写物料而不改引擎
│   └── cli/              `fide` 命令行，CI 可用
│
├── blocks/               官方物料库（text / button / card）
├── design/               设计令牌 + 断点策略表（唯一真源）
├── templates/            模板（MIT）：starter_app
└── docs/                 契约文档
```

多包用 **Dart pub workspaces** 组织（不用 melos）：一份 `pubspec.lock`，
`dart pub get` 一次解析全部依赖。

## 快速开始

```sh
dart pub get

# 校验意图大纲（对模板项目）
dart run packages/cli/bin/fide.dart validate --project templates/starter_app

# 列出物料库
dart run packages/cli/bin/fide.dart blocks --project .

# 桌面外壳（骨架阶段：五个面板 + 示例数据）
cd packages/ide_app && flutter run -d macos
```

退出码约定（CI 依赖）：`0` 通过 / `1` 有阻断错误 / `2` 项目打不开 / `70` 未实现。

## 当前状态

骨架阶段：**结构、签名与契约已固化，实现按里程碑推进**。每一条 `TODO(skeleton)`
都标了实现顺序，防止跳步导致 diff 噪声从第一步就混进来。

| 模块 | 状态 | 说明 |
|---|---|---|
| design（令牌 + 断点） | **完成** | 47 条令牌、4 档断点（Material 3 window size class），校验器据此判 token-ref |
| material_sdk | **完成** | 协议七种属性类型；`spec.yaml` 解析已实现 |
| ide_core 校验器 | **完成** | 叶子无布局权 / foldTo 必填 / id 唯一 / priority 范围 / 令牌存在 |
| ide_core base+delta 合成 | **完成** | `FideCodegen.resolve`：delta 无条件优先，两侧值都留给冲突面板 |
| ide_core codegen | 签名 | 生成顺序：单叶子 → 容器 → 断点 → delta |
| ide_core ast_writer | 签名 | analyzer 区间定位 + 写后语法自检；递归访问器待实现 |
| ide_core vm_bridge | 签名 | 属性面板只显示运行时真值，不从源码猜 |
| cli | **validate / blocks 可用** | build 留待 codegen |
| ide_app | 五面板外壳可运行 | 空态如实显示「未连接」，不摆假画布 |

## 设计决策记录

**为什么 base + delta 而不是 fork。** 大多数工具做「同步 / 独立」二态，实际需要
三态（auto / patch / orphan）。合成公式 `产物 = base + delta` 让「同步」成为默认
行为，真正需要人工介入的只剩冲突仲裁——且冲突面板必须同时展示两侧的值，
不许盲选。

**为什么双锚点。** `creationLocation`（Flutter debug 编译自带）精确但 release
不保留；`Semantics(identifier:)` 是生成时写入源码的稳定字符串，重构后仍有效。
点选优先用前者，写回用后者——文件被大规模重排后写回也不会打错地方。

**为什么锁 formatter 版本。** 方案说「diff 噪声的根因不是 formatter，是代码风格
不统一」，这只对了一半：`dart_style` 3.7 的 tall-style 与 2.x 输出不兼容，
同一份代码在两个版本下 diff 是整文件级别。三条格式纪律之外必须加第四条：
**锁定 formatter 版本并写进锁文件**，否则 CI 与本地互相覆盖。

**为什么 UI 层收在单一出口。** Flutter 3.50 已把 `package:flutter/material.dart`
标记为 deprecated（建议 `package:material_ui`）。骨架阶段保留前者（生态文档
全部按它写），但全部界面文件只从 `packages/ide_app/lib/app/ui.dart` 一处引入——
将来切换只改一行 export。这条 deprecated 提示不屏蔽：它预告了上游方向，假装
没这回事只会让切换更晚、更贵。

**为什么断点只认容器宽度。** `classify()` 的入参是 `LayoutBuilder` 的
`constraints.maxWidth`，不是屏幕宽度。组件只看自己被分到多宽，搬到侧栏、
搬到底部栏都自动对。参数名就叫 `containerWidth`，不给屏幕宽度留别名。

## 验收标准（贯穿全程的三条）

1. **删掉 IDE，项目还能跑** → 无私有 Schema；
2. **改一个值，git diff 只有一处** → 所有权单一（覆盖层刻意扁平化成
   `nodeId/breakpoint/path` 单键，就是为了这一条）；
3. **同一输入两次生成结果一致** → 运行时零 AI，确定性成立。

三条任一不过，就是在包装旧低代码。

## 版权与许可

Copyright (c) 2026 ntars and contributors

本项目按目录分层授权，**只使用 Apache License 2.0 与 MIT 两种宽松许可证**，
全文见 [LICENSE](LICENSE)（Apache-2.0）与 [LICENSE-MIT](LICENSE-MIT)（MIT），
分层说明见 [LICENSING.md](LICENSING.md)。

| 路径 | 许可 |
|---|---|
| `packages/ide_core/` `material_sdk/` `cli/` `design/` `blocks/` | **Apache-2.0** |
| `packages/ide_app/` `templates/` `docs/` `.github/` | **MIT** |

**为什么内核用 Apache-2.0**：比 MIT 多两样东西——明示专利授权（第 3 条）与
NOTICE 保留义务（第 4 条 d 项）。物料作者最在意专利风险，这一条把它拆掉；
两种许可都无传染性，第三方物料可以闭源。

**生成代码豁免**：用户通过 Flutter-IDE 生成的全部代码，版权归用户所有，
不受本项目协议约束。

**商标**：「Fide」名称与标识归 ntars 所有；代码许可只给代码权利，不给商标权。
衍生作品不得暗示其由 ntars 出品或获得背书，详见 [TRADEMARK.md](TRADEMARK.md)。

**禁止引入 copyleft 组件**（GPL / LGPL / AGPL / MPL）：宽松许可无法反向吸收
copyleft，一旦引入，整个项目将被要求以该 copyleft 许可分发。第三方组件披露
见 [NOTICE](NOTICE)。

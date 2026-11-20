[简体中文](README.md) | [English](README_EN.md)

# Flutter-IDE

**源码优先的 Flutter 可视化搭建 IDE：画布拖拽、属性面板改值，产出的永远是干净、可读、可脱离工具维护的 Dart 代码。**

![Status](https://img.shields.io/badge/status-skeleton-8957e5?style=flat-square)
[![Version](https://img.shields.io/badge/version-0.1.0-fb8500.svg?style=flat-square)](#)
[![GitHub license](https://img.shields.io/github/license/ntars/Flutter-IDE?style=flat-square)](./LICENSE)
[![Dart](https://img.shields.io/badge/Dart-3.14+-0175C2.svg?style=flat-square&logo=dart&logoColor=white)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-desktop-02569B.svg?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev/)

> **Not affiliated with or endorsed by Google.** `Flutter` 是 Google 的商标；本项目与其无关，「Flutter-IDE」只是仓库的技术标识，产品名与商标走独立注册（见 [TRADEMARK.md](TRADEMARK.md)）。

---

## 一、项目名称与定位

**名称**：Flutter-IDE（产品名 Fide）。仓库名保留技术标识，产品名与商标单独注册。

**一句话定位**：一个把「画布操作」与「可读源码」绑定的 Flutter 桌面 IDE——删掉它，项目照样 `flutter run`。

**仓库描述**：`源码优先的 Flutter 可视化搭建 IDE：画布拖拽与属性面板改值，产出可脱离工具维护的 Dart 代码 | Source-first visual IDE for Flutter: canvas drag, panel edits, and clean Dart you can maintain without the tool.`

**话题标签**（20 个，仅英文）：`flutter`、`flutter-desktop`、`dart`、`ide`、`visual-editor`、`gui-builder`、`code-generation`、`codegen`、`ast`、`design-tokens`、`layout-engine`、`material-design`、`responsive-design`、`accessibility`、`cross-platform`、`desktop-app`、`developer-tools`、`intent-driven`、`source-first`、`open-source`

| 项 | 内容 |
|---|---|
| 版本 | 0.1.0 |
| 状态 | 骨架阶段：结构、签名与契约已固化，实现按里程碑推进 |
| 仓库 | <https://github.com/ntars/Flutter-IDE> |
| 许可 | Apache-2.0 / MIT（按目录分层） |

---

## 二、项目简介

### 2.1 背景

可视化搭建工具的常见结局是「出码即断联」：工具生成的代码人看不懂、改不动，一旦离开工具就无法维护，项目被永久绑定在平台上。

### 2.2 要解决的问题

让可视化操作产出的代码**像人写的一样**：可以被接手、被 review、被 `git diff` 逐行理解。

### 2.3 核心思路

判定这个项目是否成立的唯一标准：

> 把 Flutter-IDE 删掉，项目还能不能正常 `flutter run`、正常被人接手开发？

能，项目就成立；不能，它就是又一个私有 Schema 平台。所以本仓库**没有任何只存在于工具内部、不在磁盘文件里的项目结构**——意图大纲、覆盖层、设计令牌全是进 git 的明文文件。

### 2.4 适用场景

- 需要快速搭建 Flutter 界面骨架，但不想被工具锁定；
- 团队希望设计令牌与断点策略有单一真源，而不是散落在各个页面；
- 需要 CI 里可校验的界面约束（叶子无布局权、令牌必须存在等）。

### 2.5 不适用场景

| 不做 | 理由 |
|---|---|
| 可视化逻辑编程 | 业务流程、状态管理、请求封装一律手写 Dart。可视化逻辑图的维护成本高于直接读代码 |
| 平台后端 | 不提供托管数据库、认证、云函数。绑定后端等于重演「出码断联」 |
| 运行时 AI | 任何需要在页面打开时调用模型的路径一律不做。AI 只在生成期介入，产物进 git |
| 100% 自动 | 信息架构迁移、密度档位必须由人声明。自动得越多，错得越静默 |

### 2.6 优势与局限

| 优势 | 依据 |
|---|---|
| 无私有 Schema | 意图、覆盖层、令牌均为磁盘明文，删除工具不影响构建 |
| 内核与界面分离 | `ide_core` 不依赖 Flutter，`dart test` 可单测、CI 可跑 |
| 一次改动一处 diff | 覆盖层扁平化为 `nodeId/breakpoint/path` 单键，所有权单一 |
| 确定性生成 | 运行时零 AI，同一输入两次生成结果一致 |

| 局限 | 影响范围 | 规避方式 |
|---|---|---|
| 骨架阶段 | 画布、写回、点选尚未实现 | 按路线图推进，README 如实标注签名状态 |
| 仅桌面端可用 | 无 Web / 移动端 IDE | 生成产物本身跨端，工具限桌面 |
| 物料库仅 3 类 | text / button / card | 第三方可按 `material_sdk` 写物料，不改引擎 |
| 无性能数据 | 未做基准测试 | 路线图补基准，不给估算数字 |

---

## 三、核心功能

| 功能 | 触发条件 | 结果 |
|---|---|---|
| 画布编辑 | 在画布上拖拽组件 | 修改意图大纲（intent），不直接改源码布局 |
| 属性编辑 | 在属性面板改值 | 写入覆盖层 delta，`nodeId/breakpoint/path` 单键定位 |
| 意图校验 | 保存或 CI 调用 `fide validate` | 五条硬规则：叶子无布局权、`foldTo` 必填、id 唯一、priority 范围、令牌存在 |
| 物料检查 | 调用 `fide blocks` | 列出物料库并从 `spec.yaml` 解析七种属性类型 |
| 代码生成 | 调用 codegen（签名阶段） | `产物 = base + delta`，冲突两侧值同时保留 |
| 同步率统计 | 打开同步率面板 | 按 auto / patch / orphan 三态统计 |
| 点选定位 | 在运行中的应用里点组件 | 优先用 `creationLocation`，写回用 `Semantics(identifier:)` |

---

## 四、核心特性

### 4.1 源码是唯一真源

设计器、属性面板、画布都只是源码的视图，不是持有者。任何工具内部状态都能从磁盘文件重建。

### 4.2 意图是一等公民

组件只说「我是什么、我多重要、窄屏时去哪」，不说「我在第几行第几列」。排布权归容器，身份权归叶子。

### 4.3 生成时决策，运行时不决策

人填意图 → 生成器产布局 → 校验器与 golden test 把关 → 人看 diff → commit。运行时零 AI、纯静态、完全可复现。

### 4.4 双锚点定位

`creationLocation` 精确但 release 不保留；`Semantics(identifier:)` 是写进源码的稳定字符串，重构后仍有效。点选与写回各用一种。

### 4.5 三态同步

多数工具只有「同步 / 独立」二态，这里需要三态：auto（跟随 base）、patch（人工覆盖）、orphan（源组件已删除，待处理）。

---

## 五、设计细节与工程取舍

```text
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

**为什么 base + delta 而不是 fork。** 合成公式 `产物 = base + delta` 让「同步」成为默认行为，真正需要人工介入的只剩冲突仲裁——且冲突面板必须同时展示两侧的值，不许盲选。

**为什么锁 formatter 版本。** `dart_style` 3.7 的 tall-style 与 2.x 输出不兼容，同一份代码在两个版本下 diff 是整文件级别。除三条格式纪律外必须锁定 formatter 版本并写进锁文件，否则 CI 与本地互相覆盖。

**为什么 UI 层收在单一出口。** Flutter 3.50 已把 `package:flutter/material.dart` 标记为 deprecated（建议 `package:material_ui`）。骨架阶段保留前者（生态文档全部按它写），但全部界面文件只从 `packages/ide_app/lib/app/ui.dart` 一处引入——将来切换只改一行 export。这条 deprecated 提示不屏蔽。

**为什么断点只认容器宽度。** `classify()` 的入参是 `LayoutBuilder` 的 `constraints.maxWidth`，不是屏幕宽度。组件只看自己被分到多宽，搬到侧栏、搬到底部栏都自动对。参数名就叫 `containerWidth`，不给屏幕宽度留别名。

**为什么内核不依赖 Flutter。** 内核能 `dart test`、能进 CI、桌面端崩了不影响构建。这个论断由 `packages/cli/` 证明——它能独立完成校验与物料检查。

---

## 六、技术栈与依赖清单

| 层 | 技术 | 版本约束 |
|---|---|---|
| 语言 | Dart | ^3.14.0（本机与 CI 基线） |
| 工作区 | Dart 原生 pub workspaces | 一份 `pubspec.lock`，`dart pub get` 一次解析 |
| 界面 | Flutter Desktop | 由 SDK 决定 |
| 解析与写回 | `package:analyzer` | 随 Dart SDK 约束 |
| 点选与热重载 | VM Service | 随 Flutter SDK 约束 |
| 测试 | `dart test` / golden test | 随 SDK 约束 |

不引入 melos：4 个包不需要版本发布脚本。完整第三方披露见 [NOTICE](NOTICE)。

---

## 七、安装与部署

### 7.1 环境要求

| 项 | 要求 |
|---|---|
| Flutter SDK | 3.32+（含 Dart 3.14+） |
| 操作系统 | macOS / Windows / Linux（桌面端） |
| 可选 | Xcode（macOS 构建）、Visual Studio（Windows 构建） |

### 7.2 安装

```sh
git clone https://github.com/ntars/Flutter-IDE.git
cd Flutter-IDE
dart pub get
```

### 7.3 验证

```sh
dart run packages/cli/bin/fide.dart validate --project templates/starter_app
```

退出码 `0` 即环境就绪。

### 7.4 升级与卸载

升级：`git pull && dart pub get`。卸载：删除目录，无系统级安装、无全局命令注册。

### 7.5 容器化

桌面 IDE 不做容器化；`packages/cli/` 可在任意含 Dart SDK 的容器镜像中运行，用于 CI 校验。

---

## 八、快速开始

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

预期结果：桌面外壳启动后显示五个面板；空态如实显示「未连接」，不摆假画布。

---

## 九、配置说明

| 配置项 | 位置 | 类型 | 默认值 | 作用 |
|---|---|---|---|---|
| 设计令牌 | `design/lib/tokens.dart` | Dart 常量 | 47 条 | 颜色、圆角、间距、字重 |
| 断点策略 | `design/`（断点表） | Dart 常量 | 4 档 | Material 3 window size class |
| 物料声明 | `blocks/<name>/spec.yaml` | YAML | — | 七种属性类型与默认值 |
| 意图大纲 | `<project>/intent/*.yaml` | YAML | — | 组件身份、优先级、折叠目标 |
| 覆盖层 | `<project>/overlay/*.json` | JSON | 空 | `nodeId/breakpoint/path` 单键 delta |

无运行时配置文件，无环境变量，无热更新开关：所有配置都是进 git 的明文文件，改配置即一次提交。

---

## 十、API 与模块说明

| 包 | 职责 | 公开入口 |
|---|---|---|
| `packages/ide_core` | 意图模型、codegen、AST 写回、校验、指标 | `FideCodegen.resolve`、validator 五规则 |
| `packages/material_sdk` | 物料协议与 `spec.yaml` 解析 | 七种属性类型 |
| `packages/ide_app` | Flutter Desktop 五面板外壳 | `packages/ide_app/lib/app/ui.dart`（唯一 UI 出口） |
| `packages/cli` | CI 入口，命令 `fide` | `validate` / `blocks` / `build`（待 codegen） |

CLI 退出码见第八章；`build` 子命令在 codegen 完成后可用，当前返回 `70`（未实现）。

---

## 十一、目录结构

```text
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
├── templates/            模板（MIT）：starter_app、admin_dashboard
└── docs/                 契约文档
```

---

## 十二、性能表现

**未做基准测试**，因此不给出帧率、生成耗时或内存数字。骨架阶段的已知事实：

| 项 | 现状 |
|---|---|
| 生成确定性 | 同一输入两次生成结果一致（设计目标，待 codegen 完成后纳入测试） |
| 校验性能 | 五条规则为纯静态检查，不涉及渲染 |
| 桌面外壳 | 五面板 + 示例数据，未加载真实项目 |

路线图包含基准测试项；在此之前任何性能数字都属推测，不写入文档。

---

## 十三、安全与隐私

- **全本地运行**：不联网、不上报、不调用任何模型接口；运行时零 AI 是设计约束，不是配置项。
- **无账号体系**：不收集任何用户身份信息。
- **文件访问范围**：仅读写用户打开的项目目录与工作区锁文件。
- **生成代码归属**：用户通过本工具生成的代码版权归用户，不受本项目协议约束。
- **漏洞上报**：见 [SECURITY.md](SECURITY.md)。

---

## 十四、兼容性说明

| 项 | 支持范围 | 说明 |
|---|---|---|
| Dart | ^3.14.0 | 工作区与全部子包统一基线 |
| Flutter | 3.32+ | `material.dart` 在 3.50 标记 deprecated，本项目经单一出口隔离 |
| 操作系统 | macOS / Windows / Linux | 桌面端；macOS 为当前主要开发环境 |
| Web / 移动端 | 不支持 | 产物本身跨端，工具仅桌面 |
| 模板项目 | `starter_app`、`admin_dashboard` | 随仓库提供 |

---

## 十五、已知问题与限制

### 15.1 当前实现状态

| 模块 | 状态 | 说明 |
|---|---|---|
| design（令牌 + 断点） | 完成 | 47 条令牌、4 档断点，校验器据此判 token-ref |
| material_sdk | 完成 | 协议七种属性类型；`spec.yaml` 解析已实现 |
| ide_core 校验器 | 完成 | 叶子无布局权 / foldTo 必填 / id 唯一 / priority 范围 / 令牌存在 |
| ide_core base+delta 合成 | 完成 | `FideCodegen.resolve`：delta 无条件优先，两侧值都留给冲突面板 |
| ide_core codegen | 签名 | 生成顺序：单叶子 → 容器 → 断点 → delta |
| ide_core ast_writer | 签名 | analyzer 区间定位 + 写后语法自检；递归访问器待实现 |
| ide_core vm_bridge | 签名 | 属性面板只显示运行时真值，不从源码猜 |
| cli | validate / blocks 可用 | build 留待 codegen |
| ide_app | 五面板外壳可运行 | 空态如实显示「未连接」，不摆假画布 |

### 15.2 未实现功能

| 功能 | 原因 | 计划状态 |
|---|---|---|
| 代码生成与 AST 写回 | 依赖 `ast_writer` 递归访问器 | 计划中 |
| 运行中点选 | 依赖 `vm_bridge` 完整实现 | 计划中 |
| 冲突面板仲裁 | 需 codegen 产出两侧值 | 计划中 |
| 信息架构迁移 | 必须由人声明，不做自动推断 | 未排期 |
| 基准测试 | 需 codegen 完成才有意义 | 计划中 |

每条 `TODO(skeleton)` 都标了实现顺序，防止跳步导致 diff 噪声从第一步就混进来。

---

## 十六、更新日志

遵循 Keep a Changelog 与语义化版本。

### [0.1.0] - 2026-11-18

- 新增：工作区骨架（`ide_core` / `material_sdk` / `ide_app` / `cli`），Dart pub workspaces 组织。
- 新增：47 条设计令牌与 4 档断点策略表。
- 新增：物料协议七种属性类型与 `spec.yaml` 解析。
- 新增：五条硬规则校验器与 base + delta 合成。
- 新增：`fide validate` / `fide blocks` 命令与退出码约定。

---

## 十七、后续路线图

| 计划项 | 目标版本 | 状态 |
|---|---|---|
| `ast_writer` 递归访问器与语法自检 | 0.2.0 | 计划中 |
| codegen：单叶子 → 容器 → 断点 → delta | 0.3.0 | 计划中 |
| `vm_bridge` 点选与属性真值读取 | 0.4.0 | 计划中 |
| 冲突面板与同步率面板接真实数据 | 0.5.0 | 计划中 |
| 基准测试与 golden test 全量覆盖 | 0.6.0 | 计划中 |

均为非承诺计划，按实际需要调整。

---

## 十八、参与贡献

- 开发环境：Flutter 3.32+ / Dart 3.14+，`dart pub get` 后即可开工。
- 分支模型：`main` 保持可构建；改动走 `feat/`、`fix/` 分支。
- 提交信息：`<type>(<scope>): <subject>`，scope 取包名（`core` / `sdk` / `app` / `cli` / `design`）。
- 贡献者须签署 DCO（Developer Certificate of Origin），提交时使用 `git commit -s`。
- 详细流程见 [CONTRIBUTING.md](CONTRIBUTING.md)。

---

## 十九、版权与许可

Copyright © 2026 ntars and contributors. Licensed under Apache-2.0 / MIT.

本项目按目录分层授权，只使用 Apache License 2.0 与 MIT 两种宽松许可证，全文见 [LICENSE](LICENSE)（Apache-2.0）与 [LICENSE-MIT](LICENSE-MIT)（MIT），分层说明见 [LICENSING.md](LICENSING.md)。

| 路径 | 许可 |
|---|---|
| `packages/ide_core/` `material_sdk/` `cli/` `design/` `blocks/` | Apache-2.0 |
| `packages/ide_app/` `templates/` `docs/` `.github/` | MIT |
| 根级 `README.md` `CONTRIBUTING.md` `SECURITY.md` `TRADEMARK.md` 等文档 | MIT |
| 根级 `pubspec.yaml` `analysis_options.yaml` 等工作区配置 | MIT |

**默认归属**：上表未列出的本项目自研文件，一律适用根 `LICENSE`（Apache-2.0）。逐路径路由与再分发须保留的文件清单见 [LICENSING.md](LICENSING.md)。

**为什么内核用 Apache-2.0**：比 MIT 多明示专利授权（第 3 条）与 NOTICE 保留义务（第 4 条 d 项）。物料作者最在意专利风险，这一条把它拆掉。

**生成代码豁免**：用户通过 Flutter-IDE 生成的全部代码，版权归用户所有，不受本项目协议约束。

**商标**：「Fide」名称与标识归 ntars 所有；代码许可只给代码权利，不给商标权。详见 [TRADEMARK.md](TRADEMARK.md)。

**禁止引入 copyleft 组件**（GPL / LGPL / AGPL / MPL）：宽松许可无法反向吸收 copyleft。第三方组件披露见 [NOTICE](NOTICE)。

---

## 二十、NOTICE 开源合规声明

第三方组件摘要：

| 组件 | 用途 | 许可 |
|---|---|---|
| `package:analyzer` | AST 解析与区间写回 | BSD-3-Clause |
| Flutter SDK / Dart SDK | 界面与运行时 | BSD-3-Clause |
| 其余开发依赖 | 测试与 lint | 见各包 `pubspec.yaml` |

完整清单与生成代码豁免条款见 [NOTICE](NOTICE)。

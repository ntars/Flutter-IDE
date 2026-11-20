# 分层许可说明

> 本文件是人类可读的分层路由表。`LICENSE` 是 Apache-2.0 全文，
> `LICENSE-MIT` 是 MIT 全文。GitHub 只按 `LICENSE` 识别仓库主许可，
> 因此显示为 Apache-2.0；MIT 覆盖的部分见下表。

本仓库按目录分层授权，只使用两种宽松许可证：**Apache License 2.0** 与 **MIT**。

Copyright (c) 2026 ntars and contributors

---

## 零、默认归属（先看这条）

**下表未列出的、由本项目编写的文件，一律适用根 [`LICENSE`](./LICENSE)，即 Apache-2.0。**

这条兜底规则是必须的。只列目录而不写默认值，克隆者面对根级 `pubspec.yaml`、
`pubspec.lock`、`analysis_options.yaml`、`.gitignore` 就无从判断归属，法律上等于
没有授权。需要相反结果的路径，必须显式写进下表——**不存在「靠猜」的路径**。

第三方依赖与用户生成代码不适用本兜底条款，见第二、四节。

## 一、分层映射

| 路径 | 许可 | 说明 |
|---|---|---|
| `packages/ide_core/` | **Apache-2.0** | 内核：意图模型、codegen、区间写回、VM 桥、校验器 |
| `packages/material_sdk/` | **Apache-2.0** | 物料协议与 SDK，第三方可扩展 |
| `packages/cli/` | **Apache-2.0** | 命令行，CI 可用 |
| `design/` | **Apache-2.0** | 设计令牌与断点策略表（产品的唯一真源） |
| `blocks/` | **Apache-2.0** | 官方物料库 |
| `packages/ide_app/` | **MIT** | 桌面 IDE 界面（Flutter Desktop 外壳） |
| `templates/` | **MIT** | 模板。用户拿去当生产起点，最少义务 |
| `docs/` | **MIT** | 文档 |
| `.github/` | **MIT** | CI 与组织级配置 |
| 根级 `README.md` `README_EN.md` `CONTRIBUTING.md` `SECURITY.md` `TRADEMARK.md` `LICENSING.md` `NOTICE` | **MIT** | 说明文档 |
| 根级 `pubspec.yaml` `pubspec.lock` `analysis_options.yaml` `.gitignore` | **MIT** | 工作区工程配置 |

**内核与界面为什么分开授权**：内核（Apache-2.0）比 MIT 多给两样东西——
明示专利授权（第 3 条）与 NOTICE 保留义务（第 4 条 d 项）。物料作者最在意
专利风险，这一条把它拆掉；同时两种许可都无传染性，第三方物料可以闭源。

**模板为什么用 MIT**：模板会被用户直接复制进生产项目。Apache-2.0 要求
保留 NOTICE，对「拿一份模板改改就上线」的场景是多余的义务。MIT 是最少摩擦的选择。

## 二、生成代码豁免（必须写清的一条）

> **用户通过 Fide 生成的全部代码，版权归用户所有，不受本项目协议约束。**

这条不写，没人敢用它写生产项目。它同时写在 README 首屏与 LICENSE 附加说明里。

## 三、商标

「Fide」名称、Logo 与界面设计归 ntars 所有。代码许可只授予**代码**权利，
不授予商标权，也不授予「暗示获得原作者背书」的权利。详见 [TRADEMARK.md](TRADEMARK.md)。

## 四、禁止引入 copyleft 组件

宽松许可可以吸收宽松许可，但**不能反向吸收 copyleft**。一个 GPL / LGPL / AGPL /
MPL 组件一旦引入，整个项目将被要求以该 copyleft 许可分发，Apache-2.0 与 MIT
的授权随之失效。引入新依赖前请核对 [NOTICE](NOTICE) 的兼容性。

## 五、贡献者的后手

当前用 DCO（`git commit -s`），不用 CLA，因为不做双许可。
**但如果未来要卖商业授权，需要在第一个外部 PR 之前切换到 CLA**——
第一个外部贡献进入后，这扇门就关上了。保留条款见 [CONTRIBUTING.md](CONTRIBUTING.md)。

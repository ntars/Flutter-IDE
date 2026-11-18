# 架构

> 本文档描述骨架阶段固化的分层契约。字段级细节见
> [intent-schema.md](intent-schema.md) 与 [block-protocol.md](block-protocol.md)。

## 分层与依赖方向

```
ide_app (MIT)
   ↓ 依赖
ide_core (Apache-2.0) ←—— cli (Apache-2.0)
   ↓            ↓
material_sdk   fide_design
   └————————————┘（均为 Apache-2.0，纯 Dart）
```

依赖只向下，不向上。三条由此推出的硬结论：

1. **`fide_design` 不能依赖 Flutter。** 否则 `ide_core` 与 `cli` 被拖下水，
   「内核可独立 CLI 跑」不再成立。这就是令牌是纯 Dart 常量的原因。
2. **codegen 不碰文件系统。** 它只产出字符串片段；写盘是 `ast_writer` 的事。
   这让生成结果可以逐字节断言——「同一输入两次生成结果一致」靠这条边界成立。
3. **`vm_bridge` 不知道 codegen 的存在。** 它只暴露「选中事件」与「热重载」，
   是内核里唯一与运行中进程打交道的层。越薄越好查。

## 数据流

```
design/intents/home.intent.yaml ──┐
                                  ├─→ FideCodegen.generate ─→ 片段
design/deltas/home.delta.yaml ────┘         ↑
blocks/*/spec.yaml ─ 物料协议 ──────────────┘
                                    FideValidator（error 即拒绝）
                                            ↓
                       ast_writer 区间写回 → dart analyze 自检 → 落盘
                                            ↓
                                  vm_bridge hot reload
```

## 覆盖层与冲突仲裁

```
产物 = 生成基线(base) + 覆盖层(delta)
```

- `base` 每次可重算、随时可丢；`delta` 永久保留、体积极小；
- delta 命中的属性生成器**永不静默覆盖**；未命中的自动接受新基线；
- 冲突必须同时展示 base 与 delta，不许盲选。

同步率是这套机制的体温计：`auto / patch / orphan` 三态占比。
`patch > 40%` 说明生成质量有系统性偏差；`orphan > 10%` 说明有人在绕过系统。
两个阈值都带回收动作（`FideDelta.clearNode`）——没有回收机制的系统
一定会烂在「没人敢改」。

## 关键实现路径

| 路径 | 阶段 | 核心 |
|---|---|---|
| 元素点选 | 一 | vm_bridge 订阅选中事件，取 creationLocation + identifier + 运行时真值 |
| 属性写回 | 一 | analyzer 定位 → 区间替换 → 写后语法自检 → 失败即放弃且不改文件 |
| 拖拽改位置 | 二 | **不实现为 Positioned**，而是改父容器 children 顺序后重生成 |
| 自适应 | 二 | LayoutBuilder 容器驱动；禁止组件读屏幕宽度 |
| AI 介入 | 二 | 只在生成期；输出过校验器 + golden test；产物进 git 可 revert |

## AI 介入的四条铁律

1. 模型只改叶子实现与容器 layout 实现，**不许改大纲结构**；
2. 输出必须是静态 Dart，不许引入运行时请求；
3. 同输入同输出：固定规则库版本 + 固定模板；
4. 生成物一律进 git，可 revert。

## 空态纪律

界面上三种「空」必须分开说，混起来会误导（沿自 Ondra 的实践）：

| 空 | 怎么说 |
|---|---|
| 这个环境看不到 | 「浏览器预览读不到本机数据库」 |
| 还没产生过 | 「还没有第一次生成」 |
| 读到 0 | 直接显示 `0`，不解释 |

宁可空着，也不摆一组看起来像真的示例条目。

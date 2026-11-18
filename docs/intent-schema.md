# 意图大纲 Schema

> 意图大纲是一份有层级、有顺序、有并列关系的声明，同时驱动五样产物：
> 导航 / 路由 / 无障碍语义树 / 面包屑 / 骨架屏。

## 顶层结构

```yaml
version: 1          # schema 版本，必填，将来靠它做迁移
page:
  id: home          # 页面 id，与路由分离
  route: /          # 路由，必须唯一
  priority: 1       # 导航排序权重，1 最靠前
  role: landing     # landing / list / detail / form / dashboard
  sections:         # 顶级容器节点列表
    - id: hero
      kind: container
      ...
```

文件位置：`design/intents/<pageId>.intent.yaml`（`FideProjectPaths.intents`）。
每页一份，**没有中心清单**——扫目录就是清单，磁盘是唯一真源。

## 节点字段

| 字段 | 类型 | 适用 | 必填 | 说明 |
|---|---|---|---|---|
| `id` | string | 全部 | 是 | 点分路径，如 `hero.title`；全局唯一；写回定位靠它 |
| `kind` | enum | 全部 | 是 | `container` / `leaf` |
| `layout` | map | 仅 container | 否 | 叶子上出现即 error |
| `widget` | string | 仅 leaf | 是 | 物料 id，如 `ntars.text` |
| `priority` | int | 全部 | 否（默认 2） | 1–3；决定窄屏折叠顺序与骨架屏排序 |
| `foldTo` | enum | 全部 | **是** | 见下；没有默认值 |
| `props` | map | leaf | 否 | 键为物料属性名 |
| `children` | list | container | 否 | **顺序 = 语义顺序 = 读屏顺序 = Tab 焦点顺序** |

## layout 子字段

```yaml
layout:
  dir: column            # row / column / wrap / grid
  gap: 16                # 逻辑像素（已由令牌折算）
  span:                  # 列数，不是百分比
    compact: 4           # compact 共 4 列 → 占满
    medium: 8
    expanded: 12
```

**span 的继承方向是单一的**：某档位未声明时，从更窄档位向上继承，
绝不从更宽档位向下取。窄屏信息更少，宽屏加列不会溢出；反过来把 12 列
继承给 4 列的 compact 就是溢出。

## foldTo 枚举

| 值 | 含义 |
|---|---|
| `overflow` | 收进「更多」菜单 |
| `icon` | 变图标（文字标签退化） |
| `tooltip` | 变悬停提示 |
| `collapse` | 变可展开区块 |
| `none` | 永不折叠（必须显式声明，这是个需要被记录的决定） |

## 校验规则

| 规则 | 级别 | 依据 |
|---|---|---|
| 叶子声明 `layout` | **error** | 叶子没有布局权；静默忽略比报错更难接受 |
| `foldTo` 缺失 | **error** | 折叠不等于删除，去哪必须说清 |
| 节点 `id` 重复 | **error** | 重复 id 会让写回改错节点，且语法完全正常 |
| `priority` 越界 | **error** | 越界值让折叠排序不可解释 |
| 容器无子节点 | warning | 合法中间态，但几乎总是误删 |
| token-ref 指向未注册令牌 | **error** | 令牌拼错不崩、只静默回退，是最难查的一类 |

CLI：`dart run packages/cli/bin/fide.dart validate --project .`
退出码 `0` 通过 / `1` 有 error / `2` 打不开项目。

## 覆盖层（delta）

文件位置：`design/deltas/<pageId>.delta.yaml`。只记差异，不复制整页：

```yaml
version: 1
page: home
overrides:
  hero.title:
    compact:
      props.style: display/small
  hero:
    expanded:
      layout.dir: row
```

- 属性路径形如 `props.<名>` 或 `layout.<字段>`；
- 覆盖必须绑断点：不绑断点的覆盖等于把局部微调放大成全端变更；
- delta 命中的属性，生成器永不静默覆盖（方案 §8.2 第 1 条）。

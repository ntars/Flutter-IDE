# 物料协议

> 协议的作用：让第三方能写物料而不改引擎。这是生态能不能长的分水岭。
> 每个物料 = 一个目录 + 一份 `spec.yaml`，放进 `blocks/` 即被发现，
> **不需要注册表、不需要改内核**。

## spec.yaml 全字段

```yaml
id: ntars.text            # 命名空间.名字；官方用 ntars.*，第三方用自家前缀
version: 1.0.0            # 语义版本；生成器按它判断是否需要重新生成
widget: Text              # 对应的 Dart Widget 类名，必须真实存在
slots: []                 # 插槽名；空 → 叶子物料，不接受子节点
props:
  <属性名>:
    type: string          # 见下表，共七种
    required: true
    group: content        # content / appearance / behavior
    default: ...          # 缺省值；codegen 不把它写进产物，让 Dart 用构造默认值
    min: 1                # 仅 int / double
    max: 20
    values: [a, b]        # 仅 enum
responsive:
  ownsLayout: false       # 该物料是否自己在内部处理布局（如 AppBar）
  minWidth: 80            # 窄于此宽度时应当折叠，而不是继续压缩
a11y:
  role: text              # 写进 Semantics 的角色
  identifierStrategy: auto  # identifier 取意图节点 id（骨架阶段唯一策略）
```

## 属性类型（只有七种）

| type | 值 | 面板渲染 |
|---|---|---|
| `string` | 文本 | 输入框 |
| `int` | 整数 | 数字输入（min/max 校验） |
| `double` | 浮点 | 数字输入 |
| `bool` | 布尔 | 开关 |
| `enum` | `values` 之一 | 下拉 |
| `token-ref` | 令牌名 | **令牌下拉**（不许手打裸值） |
| `block-ref` | 物料 id | 物料选择器 |

每多一种类型，codegen 就多一个分支。加新类型需要过 RFC，不随 PR 加。

## token-ref 与设计令牌

`token-ref` 属性的值必须是 `fide_design` 的 `FideTokens` 里已注册的键
（形如 `display/medium`、`space/4`、`accent/primary`）。校验器据此拦截
硬编码——令牌拼错不会崩，只会静默回退默认值，所以必须在生成前拦住。

## 物料分类的唯一定据

**没有插槽就是叶子，有插槽就是容器。** 不另设 `kind` 字段——两处事实
会互相矛盾，而矛盾的事实会让每个消费者都要选边。

## 如何贡献一个物料

1. 建 `blocks/<name>/spec.yaml`，字段按上文；
2. 实现 `FideEmitter` 接口（`widgetId` + `emitLeaf` + `emitContainer`）并注册；
3. 跑 `dart run packages/cli/bin/fide.dart blocks --project .` 确认被加载；
4. 提 PR：`NOTICE` 若无新增依赖则不用改；**输出必须是静态 Dart**，
   不许引入运行时请求（AI 四铁律之一，对物料同样生效）。

## 官方物料的边界

骨架阶段只有三个：`text` / `button` / `card`。选择它们是因为三者覆盖了
协议的全部形态——叶子必填字符串、枚举语义分量（`variant`）、容器插槽
（`card` 有 `child`）。第 4 个起的物料照抄结构即可，协议不再扩。

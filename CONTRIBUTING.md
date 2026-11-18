# 贡献指南

## DCO：一条签名，不要 CLA

本仓库用 **DCO（Developer Certificate of Origin）**，不用 CLA。
提交时加一行签名即可：

```sh
git commit -s -m "你的提交说明"
```

这条 `-s` 会在提交信息末尾加上 `Signed-off-by:`，声明你有权以当前许可证
提交这份代码。没有签名的 PR 无法合并——这是机械检查，不是形式主义：
它把「你有权提交」从一句口头承诺变成一条可审计的记录。

## 保留条款（未来可能切换到 CLA）

> **若未来需要提供商业授权，本项目会在第一个外部 PR 合入之前切换到 CLA。**
> 届时已按 DCO 贡献的代码不受影响，但新的贡献需要签署 CLA。

这一条写在这里是刻意的：切换窗口只在**第一个外部贡献之前**存在。第一个
外部 PR 合入后，这扇门就永久关上了——这也是本仓库在骨架阶段就公开征集
贡献的原因之一：让 DCO 的轻量窗口真实可用。

## 提交纪律

1. **一条 PR 只做一件事。** 混着来的 PR 会被要求拆开。
2. **`dart analyze` 零 error 零 warning。** info 级 const 提示也要求清零——
   生成物与手写物要过同一套检查，骨架先示范（方案 §7.2 的三条纪律）。
3. **内核改动必须带测试。** `packages/ide_core/test/` 下新增对应用例；
   界面改动带截图或说明。
4. **新依赖必须更新 NOTICE** 并确认非 copyleft（见 LICENSING.md 第四节）。
5. **不引入运行时 AI**。任何需要在页面打开时调用模型的路径一律不做
   （方案 §3.2 非目标）。AI 只在生成期介入，产物进 git。

## 分支与提交信息

- 主分支 `main`，功能分支 `feat/xxx`、修复 `fix/xxx`。
- 提交信息用祈使句，一行说清做了什么；超过一行时空一行再写为什么。

## 本地开发

```sh
dart pub get          # 一次解析全部包（pub workspaces）
dart analyze          # 静态检查
dart test             # 内核测试
dart run packages/cli/bin/fide.dart blocks --project .
dart run packages/cli/bin/fide.dart validate --project templates/starter_app
```

桌面界面（骨架阶段）：

```sh
cd packages/ide_app && flutter run -d macos
```

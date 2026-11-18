/// UI 引入的唯一出口。
///
/// **所有界面文件从本文件 import，不直接 import Material。** 理由：
///
/// 1. 骨架阶段选定 `package:flutter/material.dart`（生态文档与示例全部按它写，
///    新贡献者上手零认知成本）。但 Flutter 3.50 已把它标记为 deprecated，
///    建议改用 `package:material_ui/material_ui.dart`。两个方案各有利弊，
///    所以把切换点收在**这一个文件**里。
/// 2. 将来若要切到 `material_ui`：改本文件的 export 一行、在 pubspec 加一个
///    依赖，其余 8 个界面文件一个字都不用动。
/// 3. 顺带统一了「只用哪一套 API」这件事：不会出现某个文件混用两套的情况。
///
/// 现在保留 flutter/material，代价是每次 `dart analyze` 都会有一条
/// deprecated 提示。这条提示是真实且有用的（它预告了上游的移除方向），
/// 所以不屏蔽——屏蔽掉就等于假装没这回事。
library;

// ignore: deprecated_member_use
export 'package:flutter/material.dart';

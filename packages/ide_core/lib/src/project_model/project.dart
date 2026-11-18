/// 项目：一个真实 Flutter 项目的磁盘视图。
///
/// **源码是唯一真源**（方案 §4.1）。本层只负责「从哪里读、读成什么结构」，
/// 不持有任何磁盘文件里没有的东西。推论：不允许出现只存在于工具内部、
/// 不在磁盘文件里的项目结构——这条是判定「是 IDE 还是又一个私有 Schema 平台」
/// 的分界线（方案 §1）。
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import 'delta.dart';
import 'intent.dart';

/// 项目内的固定路径约定。
///
/// 这些路径是**契约**，不是约定俗成：物料与代码生成器都按它定位文件。
/// 写在一处而不是散落成字符串常量，是为了让「换目录结构」只改一个文件。
abstract final class FideProjectPaths {
  /// 意图大纲目录。每页一个 `.intent.yaml`。
  static const String intents = 'design/intents';

  /// 覆盖层目录。每页一个 `.delta.yaml`，与 intent 同名。
  static const String deltas = 'design/deltas';

  /// 生成产物目录。**这个目录整个可以被删掉重算**，不进 review 焦点。
  static const String generated = 'lib/generated';

  /// 物料库目录。
  static const String blocks = 'blocks';

  /// 场景目录的相对路径，供物料 spec.yaml 使用。
  static const String specFileName = 'spec.yaml';
}

/// 一个已打开的项目。
final class FideProject {
  FideProject._({required this.root, required this.name});

  /// 项目根目录的绝对路径。
  final String root;

  /// 项目名，取自 `pubspec.yaml` 的 `name` 字段。
  final String name;

  /// 打开一个项目。只做存在性检查，不解析任何内容——解析是各层自己的事。
  ///
  /// 返回 `null` 表示目录不存在或不是 Flutter 项目（缺 `pubspec.yaml`）。
  /// 这里不抛异常：打开失败是用户在界面上能看到的正常状态，不是程序错误。
  static FideProject? open(String rootPath) {
    final dir = Directory(rootPath);
    if (!dir.existsSync()) return null;

    final pubspec = File(p.join(rootPath, 'pubspec.yaml'));
    if (!pubspec.existsSync()) return null;

    return FideProject._(root: rootPath, name: p.basename(rootPath));
  }

  /// 读取某页的意图大纲。
  FideParseResult readIntent(String pageId) {
    final file = File(
      p.join(root, FideProjectPaths.intents, '$pageId.intent.yaml'),
    );
    if (!file.existsSync()) {
      return FideParseError([
        FideDiagnostic(
          severity: FideSeverity.error,
          message: '找不到意图文件：${p.relative(file.path, from: root)}',
          nodeId: null,
          hint: '先在 design/intents/ 下创建 $pageId.intent.yaml。',
        ),
      ]);
    }
    return FideIntent.parse(file.readAsStringSync());
  }

  /// 读取某页的覆盖层。文件不存在时返回空覆盖层而不是失败——
  /// 「没有微调过」是正常状态，不是错误。
  FideDelta readDelta(String pageId) {
    final file = File(
      p.join(root, FideProjectPaths.deltas, '$pageId.delta.yaml'),
    );
    if (!file.existsSync()) return FideDelta.empty(pageId);
    return FideDelta.parse(file.readAsStringSync());
  }

  /// 列出全部意图文件对应的页面 id。
  ///
  /// 扫目录而不是读一份清单：清单会和磁盘不同步，而磁盘是唯一真源。
  List<String> listPageIds() {
    final dir = Directory(p.join(root, FideProjectPaths.intents));
    if (!dir.existsSync()) return const [];
    return dir
        .listSync()
        .whereType<File>()
        .map((f) => p.basename(f.path))
        .where((name) => name.endsWith('.intent.yaml'))
        .map((name) => name.substring(0, name.length - '.intent.yaml'.length))
        .toList(growable: false)
      ..sort();
  }
}

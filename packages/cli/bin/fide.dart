// Fide CLI 入口。
//
// **存在理由**：证明内核真的与界面解耦（方案 §6.1 的「关键决策」）。如果
// 这个文件能跑，就说明「内核是纯 Dart 库、可完全脱离 IDE 用 CLI 调用」这句话
// 不是文档上的主张，而是可验证的事实。
//
// 骨架阶段实现了 `validate` 与 `blocks` 两条命令，`build` 与 `write` 留签名。
//
// 用法：
//   dart run packages/cli/bin/fide.dart validate --project .
//   dart run packages/cli/bin/fide.dart blocks --project .
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fide_core/fide_core.dart';
import 'package:fide_design/fide_design.dart';
import 'package:fide_material_sdk/fide_material_sdk.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> arguments) async {
  final runner =
      CommandRunner<int>('fide', 'Fide 命令行：校验意图大纲、检查物料库、生成代码。不启动图形界面。')
        ..addCommand(_ValidateCommand())
        ..addCommand(_BlocksCommand())
        ..addCommand(_BuildCommand());

  try {
    final code = await runner.run(arguments);
    exit(code ?? 0);
  } on UsageException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln();
    stderr.writeln(e.usage);
    exit(64); // EX_USAGE
  }
}

/// 全局参数：项目根目录。所有子命令都要它。
///
/// 写成 mixin 而不是基类：`Command` 是 `args` 包的类，mixin 不占继承位。
/// 注意 mixin 拿不到 `argResults`（那是 `Command` 的成员），所以每个命令
/// 自己取值——两条重复的 `addOption` 比一层 metaclass 抽象更容易读。
void _addProjectOption(ArgParser parser) {
  parser.addOption('project', abbr: 'p', help: '项目根目录。', defaultsTo: '.');
}

/// `validate`：跑校验器，按诊断严重度决定退出码。
///
/// 退出码约定（CI 依赖它，不能随意改）：
/// - 0 = 全部通过（可能有 warning）
/// - 1 = 存在阻断性 error
/// - 2 = 项目或文档打不开
class _ValidateCommand extends Command<int> {
  _ValidateCommand() {
    _addProjectOption(argParser);
    argParser.addOption('page', help: '只校验某一页。省略则校验全部页面。');
  }

  @override
  String get name => 'validate';

  @override
  String get description => '校验意图大纲（叶子布局权、foldTo 必填、id 唯一、令牌）。';

  @override
  Future<int> run() async {
    final root = '${argResults!['project']}';
    final project = FideProject.open(root);
    if (project == null) {
      stderr.writeln('不是有效的 Fide 项目：$root');
      stderr.writeln('需要存在 pubspec.yaml。');
      return 2;
    }

    final requested = argResults!['page'] as String?;
    final pages = requested != null ? [requested] : project.listPageIds();
    if (pages.isEmpty) {
      stdout.writeln('没有找到意图文件。');
      stdout.writeln('预期位置：${FideProjectPaths.intents}/<page>.intent.yaml');
      return 0;
    }

    final validator = FideValidator.standard();
    var hasError = false;

    for (final pageId in pages) {
      final result = project.readIntent(pageId);

      // 解析阶段的诊断。
      for (final d in result.diagnostics) {
        stdout.writeln('$pageId: $d');
        if (d.severity.blocks) hasError = true;
      }

      final intent = switch (result) {
        FideParseSuccess(:final intent) => intent,
        FideParseError() => null,
      };
      if (intent == null) continue;

      // 语义阶段的诊断。
      final diagnostics = validator.validate(intent.page);
      for (final d in diagnostics) {
        stdout.writeln('$pageId: $d');
        if (d.severity.blocks) hasError = true;
      }

      if (diagnostics.isEmpty) {
        stdout.writeln('$pageId: 通过（${intent.page.walk().length} 个节点）');
      }
    }

    return hasError ? 1 : 0;
  }
}

/// `blocks`：列出物料库里已注册的物料。
///
/// 这条命令是物料协议的体检：第三方把目录丢进 blocks/ 之后，用它确认
/// 自己的 spec 有没有被读进来。
class _BlocksCommand extends Command<int> {
  _BlocksCommand() {
    _addProjectOption(argParser);
  }

  @override
  String get name => 'blocks';

  @override
  String get description => '列出物料库中已加载的物料。';

  @override
  Future<int> run() async {
    final root = p.join('${argResults!['project']}', FideProjectPaths.blocks);
    final registry = FideBlockRegistry.load(root);

    if (registry.specs.isEmpty) {
      stdout.writeln('没有找到任何物料：$root');
      return 2;
    }

    stdout.writeln('已加载 ${registry.specs.length} 个物料：');
    for (final spec in registry.specs.values) {
      final kind = spec.isLeaf ? '叶子' : '容器';
      stdout.writeln('  ${spec.id}  ($kind, ${spec.widget} v${spec.version})');
      for (final prop in spec.props.values) {
        final required = prop.required ? ' 必填' : '';
        stdout.writeln(
          '    - ${prop.name}: ${prop.type.name}$required'
          ' [${prop.group.name}]',
        );
      }
    }

    // 顺带报一下令牌数量：物料能引用的 token-ref 全来自这张表。
    stdout.writeln();
    stdout.writeln(
      '设计令牌 ${FideTokens.all.length} 条，断点 '
      '${FideBreakpoints.all.length} 档：',
    );
    for (final bp in FideBreakpoints.all) {
      stdout.writeln('  ${bp.id}: ≥${bp.minWidth} → ${bp.cols} 列');
    }
    return 0;
  }
}

/// `build`：生成代码。骨架阶段只留签名与 TODO。
class _BuildCommand extends Command<int> {
  _BuildCommand() {
    _addProjectOption(argParser);
    argParser.addOption('page', help: '只生成某一页。');
  }

  @override
  String get name => 'build';

  @override
  String get description => '从意图大纲生成 Dart 代码（骨架阶段未实现）。';

  @override
  Future<int> run() async {
    // TODO(skeleton): 实现顺序与 codegen 一致——先单叶子、再容器、再断点、
    // 最后接 delta。这条命令是 CI 里的「确定性检查」入口：同一输入跑两次
    // 产物必须逐字节相同（方案 §15 贯穿全程的第 3 条测试）。
    stderr.writeln('build 尚未实现：骨架阶段只落地了 validate 与 blocks。');
    return 70; // EX_SOFTWARE
  }
}

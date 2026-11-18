/// 意图文档：一份 YAML 声明，驱动五样产物（方案 §5.1）。
///
/// 五样产物分别是：导航 / 路由 / 无障碍语义树 / 面包屑 / 骨架屏。它们都由
/// 同一棵树派生，不各写一份——这正是方案 §9 第 7 条「单声明派生五产物」的落点。
library;

import 'package:yaml/yaml.dart';

import 'node.dart';

/// 页面的结构角色。
///
/// 用途是让生成器知道「这一页在应用里承担什么」，从而决定骨架屏形态与
/// 导航层级。它不是视觉分类，不能拿来做样式。
enum FidePageRole {
  /// 落地页：首屏、营销、引导。
  landing,

  /// 列表页：一条清单 + 行间发丝线，不套卡。
  list,

  /// 详情页：单实体的完整信息。
  detail,

  /// 表单页：输入为主。
  form,

  /// 仪表盘：卡片化，与列表页刻意区分。
  dashboard;

  static FidePageRole? parse(String raw) {
    for (final r in values) {
      if (r.name == raw) return r;
    }
    return null;
  }
}

/// 一个页面。
final class FidePage {
  const FidePage({
    required this.id,
    required this.route,
    required this.priority,
    required this.role,
    required this.sections,
  });

  /// 页面 id，与路由分离：`home` 可以被挂在 `/` 或 `/home` 上。
  final String id;

  /// 路由路径，必须唯一。
  final String route;

  /// 导航排序权重，1 最靠前。
  ///
  /// 与 [FideNode.priority] 不是一回事：这个是页面之间，那个是节点之间。
  /// 共用一个名字是刻意的——它们在 UX 上的含义一致（越重要越靠前），
  /// 分成两个名字反而要解释「为什么同样的意思有两个字段」。
  final int priority;

  final FidePageRole role;

  /// 顶级容器节点，通常每个 section 一个。
  final List<FideNode> sections;

  /// 整页深度优先遍历。
  Iterable<FideNode> walk() sync* {
    for (final section in sections) {
      yield* section.walk();
    }
  }
}

/// 一份意图文档。
final class FideIntent {
  const FideIntent({required this.version, required this.page});

  /// schema 版本。将来加字段时靠它做迁移，不能省略。
  final int version;

  final FidePage page;

  /// 从 YAML 文本解析。
  ///
  /// 骨架阶段实现到「结构能读出来」为止，逐条 TODO 标出未做的部分。
  /// 这个方法的签名是本层契约：解析失败返回 [FideParseError] 而不是抛异常，
  /// 因为校验器要把「语法错」和「语义错」一起报给用户，抛异常会打断收集。
  static FideParseResult parse(String yamlSource) {
    // 解析覆盖：version / page 头、节点递归、layout、props、foldTo。
    // token-ref 的语义判定交给物料协议与校验器，解析层不猜。
    final diagnostics = <FideDiagnostic>[];
    final Object? doc;
    try {
      doc = loadYaml(yamlSource);
    } on YamlException catch (e) {
      return FideParseError([
        FideDiagnostic(
          severity: FideSeverity.error,
          message: 'YAML 语法错误：${e.message}',
          nodeId: null,
        ),
      ]);
    }

    if (doc is! YamlMap) {
      return const FideParseError([
        FideDiagnostic(
          severity: FideSeverity.error,
          message: '意图文档的根节点必须是映射（map）。',
          nodeId: null,
        ),
      ]);
    }

    final version = doc['version'];
    if (version is! int) {
      diagnostics.add(
        const FideDiagnostic(
          severity: FideSeverity.error,
          message: '缺少 version，或它不是整数。',
          nodeId: null,
        ),
      );
    }

    final pageMap = doc['page'];
    if (pageMap is! YamlMap) {
      diagnostics.add(
        const FideDiagnostic(
          severity: FideSeverity.error,
          message: '缺少 page 段。',
          nodeId: null,
        ),
      );
      return FideParseError(diagnostics);
    }

    final pageId = pageMap['id'];
    final route = pageMap['route'];
    if (pageId is! String || route is! String) {
      diagnostics.add(
        const FideDiagnostic(
          severity: FideSeverity.error,
          message: 'page.id 与 page.route 都必须是字符串。',
          nodeId: null,
        ),
      );
    }

    final role = FidePageRole.parse('${pageMap['role']}');
    if (role == null) {
      diagnostics.add(
        FideDiagnostic(
          severity: FideSeverity.error,
          message: 'page.role 缺失或不在枚举内：${pageMap['role']}。',
          nodeId: null,
        ),
      );
    }

    final priority = pageMap['priority'];
    final sectionsRaw = pageMap['sections'];
    final sections = <FideNode>[];
    if (sectionsRaw is YamlList) {
      for (final item in sectionsRaw) {
        final parsed = _parseNode(item, diagnostics);
        if (parsed != null) sections.add(parsed);
      }
    } else {
      diagnostics.add(
        const FideDiagnostic(
          severity: FideSeverity.error,
          message: 'page.sections 必须是列表。',
          nodeId: null,
        ),
      );
    }

    // 有 error 就不返回半成品：半成品会被 codegen 当真，产出的代码看似正常
    // 却缺了节点，比直接失败更难排查。
    if (diagnostics.any((d) => d.severity == FideSeverity.error)) {
      return FideParseError(diagnostics);
    }

    return FideParseSuccess(
      FideIntent(
        version: version! as int,
        page: FidePage(
          id: pageId! as String,
          route: route! as String,
          priority: priority is int ? priority : 1,
          role: role!,
          sections: List.unmodifiable(sections),
        ),
      ),
      diagnostics,
    );
  }

  /// 解析单个节点。递归部分留待实现。
  static FideNode? _parseNode(Object? raw, List<FideDiagnostic> diagnostics) {
    if (raw is! YamlMap) {
      diagnostics.add(
        const FideDiagnostic(
          severity: FideSeverity.error,
          message: '节点必须是映射。',
          nodeId: null,
        ),
      );
      return null;
    }

    final id = raw['id'];
    if (id is! String || id.isEmpty) {
      diagnostics.add(
        const FideDiagnostic(
          severity: FideSeverity.error,
          message: '每个节点都必须有非空 id。',
          nodeId: null,
        ),
      );
      return null;
    }

    final kindRaw = raw['kind'];
    final kind = kindRaw is String ? FideNodeKind.parse(kindRaw) : null;
    if (kind == null) {
      diagnostics.add(
        FideDiagnostic(
          severity: FideSeverity.error,
          message: '节点的 kind 必须是 container 或 leaf。',
          nodeId: id,
        ),
      );
      return null;
    }

    // foldTo：必填。缺失要报 error 而不是留空——留空会到校验器才报，
    // 报错信息也不如解析阶段准确（这里知道文件里的原始写法）。
    final foldToRaw = raw['foldTo'];
    final foldTo = foldToRaw is String ? FideFoldTo.parse(foldToRaw) : null;
    if (foldTo == null) {
      diagnostics.add(
        FideDiagnostic(
          severity: FideSeverity.error,
          message: '节点 $id 缺少 foldTo，或不在枚举内。',
          nodeId: id,
          hint: '填 overflow / icon / tooltip / collapse / none 之一。',
        ),
      );
    }

    // priority：可选，默认 2。
    final priorityRaw = raw['priority'];
    final priority = priorityRaw is int ? priorityRaw : 2;

    // widget：叶子必填。
    final widgetRaw = raw['widget'];
    final widget = widgetRaw is String ? widgetRaw : null;
    if (kind == FideNodeKind.leaf && widget == null) {
      diagnostics.add(
        FideDiagnostic(
          severity: FideSeverity.error,
          message: '叶子节点 $id 缺少 widget。',
          nodeId: id,
          hint: '填物料 id，如 ntars.text。',
        ),
      );
    }

    // layout：仅容器。叶子上出现由校验器报（规则名 leaf-has-no-layout），
    // 这里照单全收——解析层不重复执行校验层的职责。
    final layout = _parseLayout(raw['layout'], id, diagnostics);

    // props：原样保留。值是字面量还是 token-ref 由物料协议判定，
    // 解析层不猜——猜错一个就给校验器喂了假数据。
    final propsRaw = raw['props'];
    final props = <String, Object?>{};
    if (propsRaw is YamlMap) {
      for (final entry in propsRaw.entries) {
        if (entry.key is! String) continue;
        props[entry.key as String] = _plainValue(entry.value);
      }
    } else if (propsRaw != null) {
      diagnostics.add(
        FideDiagnostic(
          severity: FideSeverity.error,
          message: '节点 $id 的 props 必须是映射。',
          nodeId: id,
        ),
      );
    }

    // children：递归。顺序即语义顺序，解析时保持原序、不排序。
    final childrenRaw = raw['children'];
    final children = <FideNode>[];
    if (childrenRaw is YamlList) {
      for (final item in childrenRaw) {
        final parsed = _parseNode(item, diagnostics);
        if (parsed != null) children.add(parsed);
      }
    } else if (childrenRaw != null) {
      diagnostics.add(
        FideDiagnostic(
          severity: FideSeverity.error,
          message: '节点 $id 的 children 必须是列表。',
          nodeId: id,
        ),
      );
    }

    return FideNode(
      id: id,
      kind: kind,
      layout: layout,
      widget: widget,
      priority: priority,
      foldTo: foldTo,
      props: Map.unmodifiable(props),
      children: List.unmodifiable(children),
    );
  }

  /// 解析 layout 声明。未声明返回 `null`。
  static FideLayout? _parseLayout(
    Object? raw,
    String nodeId,
    List<FideDiagnostic> diagnostics,
  ) {
    if (raw == null) return null;
    if (raw is! YamlMap) {
      diagnostics.add(
        FideDiagnostic(
          severity: FideSeverity.error,
          message: '节点 $nodeId 的 layout 必须是映射。',
          nodeId: nodeId,
        ),
      );
      return null;
    }

    final dirRaw = raw['dir'];
    final dir = dirRaw is String ? FideLayoutDir.parse(dirRaw) : null;
    if (dir == null) {
      diagnostics.add(
        FideDiagnostic(
          severity: FideSeverity.error,
          message: '节点 $nodeId 的 layout.dir 必须是 row / column / wrap / grid。',
          nodeId: nodeId,
        ),
      );
    }

    final gapRaw = raw['gap'];
    final gap = gapRaw is num ? gapRaw.toDouble() : 0.0;

    // span：档位名 → 列数。列数必须是正整数。
    final spanRaw = raw['span'];
    final spanMap = <String, int>{};
    if (spanRaw is YamlMap) {
      for (final entry in spanRaw.entries) {
        final bpId = entry.key;
        final cols = entry.value;
        if (bpId is! String || cols is! int || cols <= 0) {
          diagnostics.add(
            FideDiagnostic(
              severity: FideSeverity.error,
              message: '节点 $nodeId 的 span 条目必须是「档位名: 正整数」。',
              nodeId: nodeId,
              hint: '档位名见断点策略表：compact / medium / expanded / large。',
            ),
          );
          continue;
        }
        spanMap[bpId] = cols;
      }
    }

    return FideLayout(
      dir: dir ?? FideLayoutDir.column,
      gap: gap,
      span: spanMap.isEmpty ? null : FideSpan(byBreakpoint: spanMap),
    );
  }

  /// 把 YAML 标量转成 Dart 原生值。
  ///
  /// yaml 包返回的是 YamlScalar / YamlMap / YamlList 包装，不转的话下游
  /// `is String` 全部失效。只处理标量与递归容器；YAML 的复杂键不支持。
  static Object? _plainValue(Object? raw) {
    if (raw is YamlScalar) return raw.value;
    if (raw is YamlMap) {
      return {
        for (final e in raw.entries)
          if (e.key is String) e.key as String: _plainValue(e.value),
      };
    }
    if (raw is YamlList) return raw.map(_plainValue).toList(growable: false);
    return raw;
  }
}

/// 解析结果。用封箱类型而不是 `intent? + error`，让调用方必须处理失败分支。
sealed class FideParseResult {
  const FideParseResult(this.diagnostics);

  /// 解析过程中收集的诊断信息。成功时也可能带 warning。
  final List<FideDiagnostic> diagnostics;
}

/// 解析成功。
final class FideParseSuccess extends FideParseResult {
  const FideParseSuccess(this.intent, super.diagnostics);

  final FideIntent intent;
}

/// 解析失败。诊断里至少有一条 error。
final class FideParseError extends FideParseResult {
  const FideParseError(super.diagnostics);
}

/// 诊断严重度。
enum FideSeverity {
  error,
  warning,
  info;

  /// 是否阻断后续步骤。warning 不阻断——它只是提示，产物仍然可用。
  bool get blocks => this == FideSeverity.error;
}

/// 一条诊断。
///
/// [nodeId] 为 `null` 表示问题在文档级（如 version 缺失），否则指向具体节点，
/// 好让 IDE 直接在大纲上标红。
final class FideDiagnostic {
  const FideDiagnostic({
    required this.severity,
    required this.message,
    required this.nodeId,
    this.hint,
  });

  final FideSeverity severity;

  /// 说清「哪里错了」。
  final String message;

  /// 说清「怎么改」。校验器的报错必须可执行，否则用户只能猜。
  final String? hint;

  final String? nodeId;

  @override
  String toString() {
    final where = nodeId ?? '(文档)';
    final how = hint == null ? '' : ' 建议：$hint';
    return '[${severity.name}] $where：$message$how';
  }
}

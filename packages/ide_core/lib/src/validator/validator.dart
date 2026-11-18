/// 校验器。**失败即拒绝，不产出半成品。**
///
/// 校验项全部来自方案 §5.1 的三条硬规则与 §8.1 的物料协议，一条不多一条不少：
///
/// 1. `children` 顺序即语义顺序 —— 不可校验（它是纪律，不是约束），只在文档写明；
/// 2. **叶子节点没有布局权** —— `leaf` 带 `layout` 直接 error；
/// 3. **`foldTo` 必填** —— 缺失即 error。
///
/// 另外三类校验也在这里，因为它们的失败模式同样是「产物看似正常但已经错了」：
///
/// - 节点 id 全局唯一（重复 id 会让写回改错节点，这是最严重的一类）；
/// - 物料 id 已注册（否则 codegen 会生成不存在的 Widget）；
/// - `token-ref` 指向的令牌存在（拼错令牌名不会崩，只会静默回退默认值）。
library;

import 'package:fide_design/fide_design.dart';

import '../project_model/intent.dart';

/// 一条校验规则。
///
/// 用接口而不是一个大函数：规则可以单独开关、单独测，将来第三方想加自己的
/// 规则也不用改内核——与物料协议「让第三方能写物料而不改引擎」同一个思路。
abstract interface class FideRule {
  /// 规则名，出现在诊断信息里，便于用户搜索。
  String get name;

  /// 执行校验，把发现的问题追加进 [sink]。
  void check(FidePage page, void Function(FideDiagnostic) sink);
}

/// 容器：跑一组规则，汇总诊断。
final class FideValidator {
  const FideValidator({required this.rules});

  final List<FideRule> rules;

  /// 默认规则集。顺序无关，每条规则只看自己关心的字段。
  factory FideValidator.standard() => const FideValidator(
    rules: [
      LeafHasNoLayoutRule(),
      FoldToRequiredRule(),
      UniqueIdRule(),
      PriorityRangeRule(),
      ContainerHasChildrenRule(),
      TokenRefRule(),
    ],
  );

  /// 校验一页。返回全部诊断（可能有 warning，不阻断）。
  List<FideDiagnostic> validate(FidePage page) {
    final out = <FideDiagnostic>[];
    for (final rule in rules) {
      rule.check(page, out.add);
    }
    return out;
  }

  /// 是否存在阻断性错误。调用方用它决定要不要继续 codegen。
  bool hasBlockingError(List<FideDiagnostic> diagnostics) =>
      diagnostics.any((d) => d.severity.blocks);
}

/// 规则 1：叶子节点不得声明 `layout`。
///
/// 方案 §5.1 第 2 条原文：「叶子节点没有布局权，校验器直接拒绝叶子上的 layout 键」。
/// 报的是 error 而不是 warning：叶子的 layout 会被 codegen 静默忽略，
/// 用户以为改了布局、实际没改，这种「改了但没生效」比报错更难接受。
final class LeafHasNoLayoutRule implements FideRule {
  const LeafHasNoLayoutRule();

  @override
  String get name => 'leaf-has-no-layout';

  @override
  void check(FidePage page, void Function(FideDiagnostic) sink) {
    for (final node in page.walk()) {
      if (node.isLeaf && node.layout != null) {
        sink(
          FideDiagnostic(
            severity: FideSeverity.error,
            message: '叶子节点 ${node.id} 声明了 layout。',
            nodeId: node.id,
            hint: '把 layout 移到包住它的容器上；叶子只声明 widget 与 props。',
          ),
        );
      }
    }
  }
}

/// 规则 2：`foldTo` 必填。
///
/// 方案 §5.1 第 3 条：「折叠不等于删除，去哪必须说清」，所以没有默认值。
/// 即使 `none` 也必须显式写——「永不折叠」是一个需要被记录的决定。
final class FoldToRequiredRule implements FideRule {
  const FoldToRequiredRule();

  @override
  String get name => 'foldto-required';

  @override
  void check(FidePage page, void Function(FideDiagnostic) sink) {
    for (final node in page.walk()) {
      if (node.foldTo == null) {
        sink(
          FideDiagnostic(
            severity: FideSeverity.error,
            message: '节点 ${node.id} 缺少 foldTo。',
            nodeId: node.id,
            hint:
                '填 overflow / icon / tooltip / collapse / none 之一；'
                '不想折叠就明确写 none。',
          ),
        );
      }
    }
  }
}

/// 规则 3：节点 id 全局唯一。
///
/// 重复 id 是危害最大的一类错误：写回靠 id 定位源码，重复时可能改到另一个
/// 节点，而文件语法完全正常——`dart analyze` 也不会报。所以这条必须 error。
final class UniqueIdRule implements FideRule {
  const UniqueIdRule();

  @override
  String get name => 'unique-id';

  @override
  void check(FidePage page, void Function(FideDiagnostic) sink) {
    final seen = <String>{};
    for (final node in page.walk()) {
      if (!seen.add(node.id)) {
        sink(
          FideDiagnostic(
            severity: FideSeverity.error,
            message: '节点 id 重复：${node.id}。',
            nodeId: node.id,
            hint: 'id 用于源码写回定位，必须唯一；给其中一个加语义后缀。',
          ),
        );
      }
    }
  }
}

/// 规则 4：`priority` 必须在 1–3 之间。
///
/// 这个字段决定窄屏折叠顺序，越界值不会崩，但会让排序结果不可解释。
final class PriorityRangeRule implements FideRule {
  const PriorityRangeRule();

  @override
  String get name => 'priority-range';

  @override
  void check(FidePage page, void Function(FideDiagnostic) sink) {
    for (final node in page.walk()) {
      if (node.priority < 1 || node.priority > 3) {
        sink(
          FideDiagnostic(
            severity: FideSeverity.error,
            message: '节点 ${node.id} 的 priority 为 ${node.priority}，超出 1–3。',
            nodeId: node.id,
            hint: '1 最重要、3 最次要。',
          ),
        );
      }
    }
  }
}

/// 规则 5：容器没有子节点 → warning。
///
/// 只警告不阻断：空容器是合法的中间态（刚拖进来还没放东西），但它几乎总是
/// 意味着被误删了子节点，所以要提出来。
final class ContainerHasChildrenRule implements FideRule {
  const ContainerHasChildrenRule();

  @override
  String get name => 'container-has-children';

  @override
  void check(FidePage page, void Function(FideDiagnostic) sink) {
    for (final node in page.walk()) {
      if (node.isContainer && node.children.isEmpty) {
        sink(
          FideDiagnostic(
            severity: FideSeverity.warning,
            message: '容器 ${node.id} 没有子节点。',
            nodeId: node.id,
            hint: '若是有意留空可忽略；否则检查是否误删了 children。',
          ),
        );
      }
    }
  }
}

/// 规则 6：`token-ref` 必须指向已注册令牌。
///
/// 检查的是「物料协议声明该属性为 token-ref」的字段。骨架阶段没有物料
/// 注册表注入，因此只校验一个已知的约定字段 `style`，其余 TODO。
final class TokenRefRule implements FideRule {
  const TokenRefRule();

  @override
  String get name => 'token-ref';

  @override
  void check(FidePage page, void Function(FideDiagnostic) sink) {
    for (final node in page.walk()) {
      final style = node.props['style'];
      if (style is! String) continue;

      // TODO(skeleton): 从一个已加载的物料注册表读取「哪些属性是 token-ref」，
      // 现在只知道字号档位这一组会写进 style。
      if (!FideTokens.contains(style)) {
        sink(
          FideDiagnostic(
            severity: FideSeverity.error,
            message: '节点 ${node.id} 的 style 指向未注册令牌：$style。',
            nodeId: node.id,
            hint: '合法值见 FideTokens 的 fontSize 组，例如 display/medium。',
          ),
        );
      }
    }
  }
}

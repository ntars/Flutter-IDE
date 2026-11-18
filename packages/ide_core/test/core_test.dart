// 内核冒烟测试：只测骨架阶段已经真正实现的逻辑。
//
// 测试范围刻意收窄——未实现的方法（codegen.generate、ast_writer.locate 等）
// 不测，它们会抛 UnimplementedError，测了就是假绿。每条 TODO 实现时补对应用例。
import 'package:fide_core/fide_core.dart';
import 'package:fide_design/fide_design.dart';
import 'package:test/test.dart';

void main() {
  group('校验器', () {
    test('foldTo 缺失报 error', () {
      final page = _page([_leaf('hero.title', foldTo: null)]);
      final diagnostics = FideValidator.standard().validate(page);
      expect(
        diagnostics.any(
          (d) => d.severity.blocks && d.message.contains('foldTo'),
        ),
        isTrue,
        reason: '「折叠不等于删除，去哪必须说清」——没有默认值。',
      );
    });

    test('叶子声明 layout 报 error', () {
      final page = _page([
        const FideNode(
          id: 'hero.title',
          kind: FideNodeKind.leaf,
          widget: 'ntars.text',
          foldTo: FideFoldTo.none,
          layout: FideLayout(dir: FideLayoutDir.column),
        ),
      ]);
      final diagnostics = FideValidator.standard().validate(page);
      expect(
        diagnostics.any((d) => d.severity.blocks),
        isTrue,
        reason: '叶子没有布局权（方案 §5.1 第 2 条）。',
      );
    });

    test('id 重复报 error', () {
      final page = _page([
        _leaf('dup', foldTo: FideFoldTo.none),
        _leaf('dup', foldTo: FideFoldTo.none),
      ]);
      final diagnostics = FideValidator.standard().validate(page);
      expect(
        diagnostics.any((d) => d.message.contains('id 重复')),
        isTrue,
        reason: '重复 id 会让写回改错节点，且语法完全正常。',
      );
    });

    test('合法文档零 error', () {
      final page = _page([
        FideNode(
          id: 'hero',
          kind: FideNodeKind.container,
          foldTo: FideFoldTo.none,
          layout: const FideLayout(dir: FideLayoutDir.column, gap: 16),
          children: [
            _leaf('hero.title', foldTo: FideFoldTo.none),
            _leaf('hero.meta', foldTo: FideFoldTo.overflow, priority: 3),
          ],
        ),
      ]);
      final diagnostics = FideValidator.standard().validate(page);
      expect(diagnostics.where((d) => d.severity.blocks), isEmpty);
    });
  });

  group('base + delta 合成', () {
    test('delta 命中即胜出', () {
      const delta = FideDelta(
        version: 1,
        page: 'home',
        overrides: {
          'hero.title/compact/props.style': FideOverride(
            nodeId: 'hero.title',
            breakpoint: 'compact',
            path: 'props.style',
            value: 'display/small',
          ),
        },
      );

      final resolved = FideCodegen.resolve(
        nodeId: 'hero.title',
        breakpoint: 'compact',
        path: 'props.style',
        base: 'display/medium',
        delta: delta,
      );

      expect(resolved.effective, 'display/small');
      expect(resolved.origin, FideValueOrigin.patch);
      expect(resolved.hasConflict, isTrue);
    });

    test('未命中走 base', () {
      final resolved = FideCodegen.resolve(
        nodeId: 'hero.title',
        breakpoint: 'expanded',
        path: 'props.style',
        base: 'display/medium',
        delta: FideDelta.empty('home'),
      );

      expect(resolved.effective, 'display/medium');
      expect(resolved.origin, FideValueOrigin.auto);
      expect(resolved.hasConflict, isFalse);
    });
  });

  group('断点策略表', () {
    test('按容器宽度归类，数值取自 Material 3', () {
      expect(FideBreakpoints.classify(0).id, 'compact');
      expect(FideBreakpoints.classify(599.9).id, 'compact');
      expect(FideBreakpoints.classify(600).id, 'medium');
      expect(FideBreakpoints.classify(840).id, 'expanded');
      expect(FideBreakpoints.classify(1200).id, 'large');
    });

    test('span 只向更窄档位继承', () {
      const span = FideSpan(byBreakpoint: {'compact': 4, 'expanded': 12});
      // compact 直接命中。
      expect(span.spanOf('compact'), 4);
      // medium 未声明 → 继承 compact（更窄），不继承 expanded。
      expect(span.spanOf('medium'), 4);
      expect(span.spanOf('expanded'), 12);
    });
  });

  group('设计令牌', () {
    test('display/medium 已注册，拼错的键不存在', () {
      expect(FideTokens.contains('display/medium'), isTrue);
      expect(
        FideTokens.contains('Display/Medium'),
        isFalse,
        reason: '不做大小写模糊匹配——给拼写错误开后门',
      );
      expect(FideTokens.lookup('display/medium')!.value, 32);
    });
  });

  group('意图解析', () {
    test('合法文档解析成功', () {
      const source = '''
version: 1
page:
  id: home
  route: /
  priority: 1
  role: landing
  sections:
    - id: hero
      kind: container
      foldTo: none
''';
      final result = FideIntent.parse(source);
      result as FideParseSuccess;
      expect(result.intent.page.id, 'home');
      expect(result.intent.page.sections.single.id, 'hero');
      expect(result.intent.page.sections.single.foldTo, FideFoldTo.none);
    });

    test('foldTo 缺失在解析阶段就报 error', () {
      const source = '''
version: 1
page:
  id: home
  route: /
  role: landing
  sections:
    - id: hero
      kind: container
''';
      final result = FideIntent.parse(source);
      expect(result, isA<FideParseError>());
    });

    test('语法错误返回 FideParseError 而不是抛异常', () {
      final result = FideIntent.parse('version: [broken');
      expect(result, isA<FideParseError>());
    });
  });
}

FidePage _page(List<FideNode> sections) => FidePage(
  id: 'test',
  route: '/test',
  priority: 1,
  role: FidePageRole.landing,
  sections: sections,
);

FideNode _leaf(String id, {required FideFoldTo? foldTo, int priority = 2}) =>
    FideNode(
      id: id,
      kind: FideNodeKind.leaf,
      widget: 'ntars.text',
      priority: priority,
      foldTo: foldTo,
    );

/// 物料加载器：把 `blocks/` 下的 `spec.yaml` 读成 [FideBlockSpec]。
///
/// 加载策略是**扫目录、不做中心清单**。理由：清单会和磁盘不同步，而磁盘是
/// 唯一真源（方案 §4.1）。第三方把物料目录丢进 `blocks/` 就能被发现，
/// 不需要改任何注册表——这是「第三方能写物料而不改引擎」的具体实现。
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'block_spec.dart';

/// 一个已加载的物料库。
final class FideBlockRegistry {
  const FideBlockRegistry(this.specs);

  /// 物料 id → 声明。
  final Map<String, FideBlockSpec> specs;

  /// 按 id 取物料。未注册返回 `null`，由校验器报「物料未注册」。
  FideBlockSpec? byId(String id) => specs[id];

  /// 是否已注册某物料。
  bool contains(String id) => specs.containsKey(id);

  /// 全部叶子物料，供物料面板列出可拖拽项。
  List<FideBlockSpec> get leaves =>
      specs.values.where((s) => s.isLeaf).toList(growable: false);

  /// 全部容器物料。
  List<FideBlockSpec> get containers =>
      specs.values.where((s) => !s.isLeaf).toList(growable: false);

  /// 加载一个 `blocks/` 目录。
  ///
  /// 单份 spec 解析失败不会中断整批加载：收集失败项，其余的照常可用。
  /// 这样第三方写坏一个物料不会让整个 IDE 打不开——那是最糟糕的失败形态。
  static FideBlockRegistry load(String blocksRoot) {
    final root = Directory(blocksRoot);
    if (!root.existsSync()) return const FideBlockRegistry({});

    final specs = <String, FideBlockSpec>{};
    // 只扫一层：物料目录结构固定为 `blocks/<name>/spec.yaml`，
    // 不做递归，避免把 `example/` 之类的附属目录当成物料。
    for (final entry in root.listSync().whereType<Directory>()) {
      final specFile = File(p.join(entry.path, 'spec.yaml'));
      if (!specFile.existsSync()) continue;

      final spec = parseSpec(specFile.readAsStringSync());
      if (spec != null) specs[spec.id] = spec;
    }
    return FideBlockRegistry(Map.unmodifiable(specs));
  }

  /// 解析一份 spec.yaml。失败返回 `null`。
  ///
  /// 返回 `null` 而不是抛异常：一个物料写坏不该阻止其他物料加载。
  static FideBlockSpec? parseSpec(String yamlSource) {
    final Object? doc;
    try {
      doc = loadYaml(yamlSource);
    } on YamlException {
      return null;
    }
    if (doc is! YamlMap) return null;

    final id = doc['id'];
    final widget = doc['widget'];
    if (id is! String || widget is! String) return null;

    // 属性表。
    final props = <String, FidePropSpec>{};
    final propsRaw = doc['props'];
    if (propsRaw is YamlMap) {
      for (final entry in propsRaw.entries) {
        final name = entry.key;
        final body = entry.value;
        if (name is! String || body is! YamlMap) continue;

        final typeRaw = body['type'];
        final type = typeRaw is String ? FidePropType.parse(typeRaw) : null;
        if (type == null) continue;

        final valuesRaw = body['values'];
        props[name] = FidePropSpec(
          name: name,
          type: type,
          required: body['required'] == true,
          group:
              FidePropGroup.parse('${body['group']}') ?? FidePropGroup.content,
          defaultValue: body['default'],
          min: body['min'] is num ? body['min'] as num : null,
          max: body['max'] is num ? body['max'] as num : null,
          values: valuesRaw is YamlList
              ? valuesRaw.map((v) => '$v').toList(growable: false)
              : const [],
        );
      }
    }

    // 插槽。
    final slotsRaw = doc['slots'];
    final slots = slotsRaw is YamlList
        ? slotsRaw.map((s) => '$s').toList(growable: false)
        : const <String>[];

    // 响应式。
    final responsiveRaw = doc['responsive'];
    final responsive = responsiveRaw is YamlMap
        ? FideResponsiveSpec(
            ownsLayout: responsiveRaw['ownsLayout'] == true,
            minWidth: responsiveRaw['minWidth'] is num
                ? (responsiveRaw['minWidth'] as num).toDouble()
                : 0,
          )
        : const FideResponsiveSpec(ownsLayout: false, minWidth: 0);

    // 无障碍。
    final a11yRaw = doc['a11y'];
    final a11y = a11yRaw is YamlMap
        ? FideA11ySpec(
            role: '${a11yRaw['role'] ?? 'unknown'}',
            identifierStrategy: '${a11yRaw['identifierStrategy'] ?? 'auto'}',
          )
        : const FideA11ySpec(role: 'unknown', identifierStrategy: 'auto');

    return FideBlockSpec(
      id: id,
      version: '${doc['version'] ?? '0.0.0'}',
      widget: widget,
      slots: slots,
      props: Map.unmodifiable(props),
      responsive: responsive,
      a11y: a11y,
    );
  }
}

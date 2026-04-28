import 'plan_side.dart';

class PlanViewNode {
  const PlanViewNode({required this.id, required this.x, required this.y});

  final String id;
  final double x;
  final double y;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
    };
  }

  factory PlanViewNode.fromJson(Map<String, dynamic> json) {
    return PlanViewNode(
      id: (json['id'] as String?) ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PlanViewEdge {
  const PlanViewEdge._internal({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    required this.lengthMm,
    required this.sideType,
    this.eavesMm,
    this.ridgeMm,
    this.overhangMm,
  });

  factory PlanViewEdge({
    required String id,
    required String fromNodeId,
    required String toNodeId,
    required int lengthMm,
    required PlanSideType sideType,
    int? eavesMm,
    int? ridgeMm,
    int? overhangMm,
    // Backward compatibility for old constructor callers.
    int? eavesHeightMm,
    int? ridgeHeightMm,
  }) {
    return PlanViewEdge._internal(
      id: id,
      fromNodeId: fromNodeId,
      toNodeId: toNodeId,
      lengthMm: lengthMm,
      sideType: sideType,
      eavesMm: eavesMm ?? eavesHeightMm,
      ridgeMm: ridgeMm ?? ridgeHeightMm,
      overhangMm: overhangMm,
    );
  }

  final String id;
  final String fromNodeId;
  final String toNodeId;
  final int lengthMm;
  final PlanSideType sideType;
  final int? eavesMm;
  final int? ridgeMm;
  final int? overhangMm;

  int? get eavesHeightMm => eavesMm;
  int? get ridgeHeightMm => ridgeMm;

  PlanViewEdge copyWith({
    String? id,
    String? fromNodeId,
    String? toNodeId,
    int? lengthMm,
    PlanSideType? sideType,
    Object? eavesMm = _unset,
    Object? ridgeMm = _unset,
    Object? overhangMm = _unset,
    // Backward compatibility aliases.
    Object? eavesHeightMm = _unset,
    Object? ridgeHeightMm = _unset,
  }) {
    final resolvedEaves = eavesMm != _unset ? eavesMm : eavesHeightMm;
    final resolvedRidge = ridgeMm != _unset ? ridgeMm : ridgeHeightMm;
    return PlanViewEdge(
      id: id ?? this.id,
      fromNodeId: fromNodeId ?? this.fromNodeId,
      toNodeId: toNodeId ?? this.toNodeId,
      lengthMm: lengthMm ?? this.lengthMm,
      sideType: sideType ?? this.sideType,
      eavesMm: resolvedEaves == _unset ? this.eavesMm : resolvedEaves as int?,
      ridgeMm: resolvedRidge == _unset ? this.ridgeMm : resolvedRidge as int?,
      overhangMm: overhangMm == _unset ? this.overhangMm : overhangMm as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromNodeId': fromNodeId,
      'toNodeId': toNodeId,
      'lengthMm': lengthMm,
      'sideType': sideType.jsonValue,
      'eavesMm': eavesMm,
      'ridgeMm': ridgeMm,
      'overhangMm': overhangMm,
      // Backward compatibility with existing local project data.
      'eavesHeightMm': eavesMm,
      'ridgeHeightMm': ridgeMm,
    };
  }

  factory PlanViewEdge.fromJson(Map<String, dynamic> json) {
    return PlanViewEdge(
      id: (json['id'] as String?) ?? '',
      fromNodeId: (json['fromNodeId'] as String?) ?? '',
      toNodeId: (json['toNodeId'] as String?) ?? '',
      lengthMm: (json['lengthMm'] as num?)?.toInt() ?? 0,
      sideType: planSideTypeFromJsonValue(json['sideType'] as String?),
      eavesMm: ((json['eavesMm'] ?? json['eavesHeightMm']) as num?)?.toInt(),
      ridgeMm: ((json['ridgeMm'] ?? json['ridgeHeightMm']) as num?)?.toInt(),
      overhangMm: (json['overhangMm'] as num?)?.toInt(),
    );
  }
}

class PlanViewData {
  const PlanViewData({
    required this.enabled,
    required this.nodes,
    required this.edges,
  });

  final bool enabled;
  final List<PlanViewNode> nodes;
  final List<PlanViewEdge> edges;

  List<PlanSide> get sides {
    return edges
        .map(
          (edge) => PlanSide(
            sideId: edge.id,
            label: edge.id,
            lengthM: edge.lengthMm / 1000,
            sideType: edge.sideType,
          ),
        )
        .toList(growable: false);
  }

  factory PlanViewData.empty() {
    return const PlanViewData(enabled: false, nodes: [], edges: []);
  }

  PlanViewData copyWith({
    bool? enabled,
    List<PlanViewNode>? nodes,
    List<PlanViewEdge>? edges,
  }) {
    return PlanViewData(
      enabled: enabled ?? this.enabled,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'nodes': nodes.map((node) => node.toJson()).toList(growable: false),
      'edges': edges.map((edge) => edge.toJson()).toList(growable: false),
    };
  }

  factory PlanViewData.fromJson(Map<String, dynamic> json) {
    List<T> readList<T>(
      Object? source,
      T Function(Map<String, dynamic> value) parse,
    ) {
      if (source is! List) return <T>[];
      return source
          .whereType<Map>()
          .map((value) => parse(Map<String, dynamic>.from(value)))
          .toList(growable: false);
    }

    return PlanViewData(
      enabled: (json['enabled'] as bool?) ?? false,
      nodes: readList(json['nodes'], PlanViewNode.fromJson),
      edges: readList(json['edges'], PlanViewEdge.fromJson),
    );
  }
}

const _unset = Object();

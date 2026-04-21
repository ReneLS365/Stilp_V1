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
  const PlanViewEdge({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    required this.lengthMm,
    required this.sideType,
    this.eavesHeightMm,
    this.ridgeHeightMm,
  });

  final String id;
  final String fromNodeId;
  final String toNodeId;
  final int lengthMm;
  final PlanSideType sideType;
  final int? eavesHeightMm;
  final int? ridgeHeightMm;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromNodeId': fromNodeId,
      'toNodeId': toNodeId,
      'lengthMm': lengthMm,
      'sideType': sideType.jsonValue,
      'eavesHeightMm': eavesHeightMm,
      'ridgeHeightMm': ridgeHeightMm,
    };
  }

  factory PlanViewEdge.fromJson(Map<String, dynamic> json) {
    return PlanViewEdge(
      id: (json['id'] as String?) ?? '',
      fromNodeId: (json['fromNodeId'] as String?) ?? '',
      toNodeId: (json['toNodeId'] as String?) ?? '',
      lengthMm: (json['lengthMm'] as num?)?.toInt() ?? 0,
      sideType: planSideTypeFromJsonValue(json['sideType'] as String?),
      eavesHeightMm: (json['eavesHeightMm'] as num?)?.toInt(),
      ridgeHeightMm: (json['ridgeHeightMm'] as num?)?.toInt(),
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

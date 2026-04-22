import 'facade_marker.dart';
import 'facade_section.dart';
import 'facade_storey.dart';
import 'plan_side.dart';
import 'plan_view_data.dart';

class FacadeDocument {
  const FacadeDocument({
    required this.sideId,
    required this.label,
    required this.planEdgeId,
    required this.sideOrder,
    required this.edgeLengthMm,
    required this.sideType,
    required this.eavesHeightMm,
    required this.ridgeHeightMm,
    required this.standingHeightM,
    required this.topZoneM,
    required this.sections,
    required this.storeys,
    required this.markers,
  });

  final String sideId;
  final String label;
  final String planEdgeId;
  final int sideOrder;
  final int edgeLengthMm;
  final PlanSideType sideType;
  final int? eavesHeightMm;
  final int? ridgeHeightMm;
  final double? standingHeightM;
  final double topZoneM;
  final List<FacadeSection> sections;
  final List<FacadeStorey> storeys;
  final List<FacadeMarker> markers;

  factory FacadeDocument.emptyForSide({
    required String sideId,
    required String label,
    double topZoneM = 1,
  }) {
    return FacadeDocument(
      sideId: sideId,
      label: label,
      planEdgeId: sideId,
      sideOrder: 0,
      edgeLengthMm: 0,
      sideType: PlanSideType.andet,
      eavesHeightMm: null,
      ridgeHeightMm: null,
      standingHeightM: null,
      topZoneM: topZoneM,
      sections: const [],
      storeys: const [],
      markers: const [],
    );
  }

  factory FacadeDocument.fromPlanEdge({
    required PlanViewEdge edge,
    required int sideOrder,
    required String label,
    FacadeDocument? existing,
  }) {
    final base = existing ?? FacadeDocument.emptyForSide(sideId: edge.id, label: label);
    return base.copyWith(
      sideId: edge.id,
      label: label,
      planEdgeId: edge.id,
      sideOrder: sideOrder,
      edgeLengthMm: edge.lengthMm,
      sideType: edge.sideType,
      eavesHeightMm: edge.eavesHeightMm,
      ridgeHeightMm: edge.ridgeHeightMm,
    );
  }

  FacadeDocument copyWith({
    String? sideId,
    String? label,
    String? planEdgeId,
    int? sideOrder,
    int? edgeLengthMm,
    PlanSideType? sideType,
    Object? eavesHeightMm = _unset,
    Object? ridgeHeightMm = _unset,
    double? standingHeightM,
    double? topZoneM,
    List<FacadeSection>? sections,
    List<FacadeStorey>? storeys,
    List<FacadeMarker>? markers,
    bool clearStandingHeightM = false,
  }) {
    return FacadeDocument(
      sideId: sideId ?? this.sideId,
      label: label ?? this.label,
      planEdgeId: planEdgeId ?? this.planEdgeId,
      sideOrder: sideOrder ?? this.sideOrder,
      edgeLengthMm: edgeLengthMm ?? this.edgeLengthMm,
      sideType: sideType ?? this.sideType,
      eavesHeightMm: eavesHeightMm == _unset ? this.eavesHeightMm : eavesHeightMm as int?,
      ridgeHeightMm: ridgeHeightMm == _unset ? this.ridgeHeightMm : ridgeHeightMm as int?,
      standingHeightM: clearStandingHeightM
          ? null
          : (standingHeightM ?? this.standingHeightM),
      topZoneM: topZoneM ?? this.topZoneM,
      sections: sections ?? this.sections,
      storeys: storeys ?? this.storeys,
      markers: markers ?? this.markers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sideId': sideId,
      'label': label,
      'planEdgeId': planEdgeId,
      'sideOrder': sideOrder,
      'edgeLengthMm': edgeLengthMm,
      'sideType': sideType.jsonValue,
      'eavesHeightMm': eavesHeightMm,
      'ridgeHeightMm': ridgeHeightMm,
      'standingHeightM': standingHeightM,
      'topZoneM': topZoneM,
      'sections': sections.map((section) => section.toJson()).toList(growable: false),
      'storeys': storeys.map((storey) => storey.toJson()).toList(growable: false),
      'markers': markers.map((marker) => marker.toJson()).toList(growable: false),
    };
  }

  factory FacadeDocument.fromJson(Map<String, dynamic> json) {
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

    final sideId = (json['sideId'] as String?) ?? '';

    return FacadeDocument(
      sideId: sideId,
      label: (json['label'] as String?) ?? '',
      planEdgeId: (json['planEdgeId'] as String?) ?? sideId,
      sideOrder: (json['sideOrder'] as num?)?.toInt() ?? 0,
      edgeLengthMm: (json['edgeLengthMm'] as num?)?.toInt() ?? 0,
      sideType: planSideTypeFromJsonValue(json['sideType'] as String?),
      eavesHeightMm: (json['eavesHeightMm'] as num?)?.toInt(),
      ridgeHeightMm: (json['ridgeHeightMm'] as num?)?.toInt(),
      standingHeightM: (json['standingHeightM'] as num?)?.toDouble(),
      topZoneM: (json['topZoneM'] as num?)?.toDouble() ?? 1,
      sections: readList(json['sections'], FacadeSection.fromJson),
      storeys: readList(json['storeys'], FacadeStorey.fromJson),
      markers: readList(json['markers'], FacadeMarker.fromJson),
    );
  }
}

const _unset = Object();

import 'facade_marker.dart';
import 'facade_section.dart';
import 'facade_storey.dart';

class FacadeDocument {
  const FacadeDocument({
    required this.sideId,
    required this.label,
    required this.standingHeightM,
    required this.topZoneM,
    required this.sections,
    required this.storeys,
    required this.markers,
  });

  final String sideId;
  final String label;
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
      standingHeightM: null,
      topZoneM: topZoneM,
      sections: const [],
      storeys: const [],
      markers: const [],
    );
  }

  FacadeDocument copyWith({
    String? sideId,
    String? label,
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

    return FacadeDocument(
      sideId: (json['sideId'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      standingHeightM: (json['standingHeightM'] as num?)?.toDouble(),
      topZoneM: (json['topZoneM'] as num?)?.toDouble() ?? 1,
      sections: readList(json['sections'], FacadeSection.fromJson),
      storeys: readList(json['storeys'], FacadeStorey.fromJson),
      markers: readList(json['markers'], FacadeMarker.fromJson),
    );
  }
}

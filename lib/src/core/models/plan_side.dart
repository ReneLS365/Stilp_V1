enum PlanSideType {
  wall,
  opening,
  free,
}

class PlanSide {
  const PlanSide({
    required this.sideId,
    required this.label,
    required this.lengthM,
    required this.sideType,
    this.notes,
  });

  final String sideId;
  final String label;
  final double lengthM;
  final PlanSideType sideType;
  final String? notes;

  PlanSide copyWith({
    String? sideId,
    String? label,
    double? lengthM,
    PlanSideType? sideType,
    String? notes,
    bool clearNotes = false,
  }) {
    return PlanSide(
      sideId: sideId ?? this.sideId,
      label: label ?? this.label,
      lengthM: lengthM ?? this.lengthM,
      sideType: sideType ?? this.sideType,
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sideId': sideId,
      'label': label,
      'lengthM': lengthM,
      'sideType': sideType.name,
      'notes': notes,
    };
  }

  factory PlanSide.fromJson(Map<String, dynamic> json) {
    final rawType = json['sideType'] as String?;
    return PlanSide(
      sideId: (json['sideId'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      lengthM: (json['lengthM'] as num?)?.toDouble() ?? 0,
      sideType: PlanSideType.values.firstWhere(
        (value) => value.name == rawType,
        orElse: () => PlanSideType.wall,
      ),
      notes: json['notes'] as String?,
    );
  }
}

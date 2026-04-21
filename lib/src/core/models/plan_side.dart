enum PlanSideType {
  langside,
  gavl,
  andet,
}

extension PlanSideTypeJson on PlanSideType {
  String get jsonValue {
    switch (this) {
      case PlanSideType.langside:
        return 'langside';
      case PlanSideType.gavl:
        return 'gavl';
      case PlanSideType.andet:
        return 'andet';
    }
  }
}

PlanSideType planSideTypeFromJsonValue(String? rawType) {
  switch (rawType) {
    case 'langside':
      return PlanSideType.langside;
    case 'gavl':
      return PlanSideType.gavl;
    case 'andet':
      return PlanSideType.andet;
    // Backward compatibility for pre-lock temporary values.
    case 'wall':
      return PlanSideType.langside;
    case 'opening':
      return PlanSideType.gavl;
    case 'free':
      return PlanSideType.andet;
    default:
      return PlanSideType.andet;
  }
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
      'sideType': sideType.jsonValue,
      'notes': notes,
    };
  }

  factory PlanSide.fromJson(Map<String, dynamic> json) {
    return PlanSide(
      sideId: (json['sideId'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      lengthM: (json['lengthM'] as num?)?.toDouble() ?? 0,
      sideType: planSideTypeFromJsonValue(json['sideType'] as String?),
      notes: json['notes'] as String?,
    );
  }
}

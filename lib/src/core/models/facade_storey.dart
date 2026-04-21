enum FacadeStoreyKind {
  main,
  topZone,
}

class FacadeStorey {
  const FacadeStorey({
    required this.id,
    required this.heightM,
    required this.kind,
  });

  final String id;
  final double heightM;
  final FacadeStoreyKind kind;

  FacadeStorey copyWith({String? id, double? heightM, FacadeStoreyKind? kind}) {
    return FacadeStorey(
      id: id ?? this.id,
      heightM: heightM ?? this.heightM,
      kind: kind ?? this.kind,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'heightM': heightM,
      'kind': kind.name,
    };
  }

  factory FacadeStorey.fromJson(Map<String, dynamic> json) {
    final rawKind = json['kind'] as String?;
    return FacadeStorey(
      id: (json['id'] as String?) ?? '',
      heightM: (json['heightM'] as num?)?.toDouble() ?? 0,
      kind: FacadeStoreyKind.values.firstWhere(
        (value) => value.name == rawKind,
        orElse: () => FacadeStoreyKind.main,
      ),
    );
  }
}

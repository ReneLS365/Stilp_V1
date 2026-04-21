enum FacadeMarkerType {
  console,
  diagonal,
  ladderDeck,
  opening,
  textNote,
}

class FacadeMarker {
  const FacadeMarker({
    required this.id,
    required this.type,
    this.sectionId,
    this.storeyId,
    this.xM,
    this.yM,
    this.text,
  });

  final String id;
  final FacadeMarkerType type;
  final String? sectionId;
  final String? storeyId;
  final double? xM;
  final double? yM;
  final String? text;

  FacadeMarker copyWith({
    String? id,
    FacadeMarkerType? type,
    String? sectionId,
    String? storeyId,
    double? xM,
    double? yM,
    String? text,
    bool clearSectionId = false,
    bool clearStoreyId = false,
    bool clearXM = false,
    bool clearYM = false,
    bool clearText = false,
  }) {
    return FacadeMarker(
      id: id ?? this.id,
      type: type ?? this.type,
      sectionId: clearSectionId ? null : (sectionId ?? this.sectionId),
      storeyId: clearStoreyId ? null : (storeyId ?? this.storeyId),
      xM: clearXM ? null : (xM ?? this.xM),
      yM: clearYM ? null : (yM ?? this.yM),
      text: clearText ? null : (text ?? this.text),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'sectionId': sectionId,
      'storeyId': storeyId,
      'xM': xM,
      'yM': yM,
      'text': text,
    };
  }

  factory FacadeMarker.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String?;
    return FacadeMarker(
      id: (json['id'] as String?) ?? '',
      type: FacadeMarkerType.values.firstWhere(
        (value) => value.name == rawType,
        orElse: () => FacadeMarkerType.textNote,
      ),
      sectionId: json['sectionId'] as String?,
      storeyId: json['storeyId'] as String?,
      xM: (json['xM'] as num?)?.toDouble(),
      yM: (json['yM'] as num?)?.toDouble(),
      text: json['text'] as String?,
    );
  }
}

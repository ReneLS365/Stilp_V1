enum FacadeMarkerType {
  console,
  diagonal,
  ladderDeck,
  opening,
  textNote,
}

extension FacadeMarkerTypeJson on FacadeMarkerType {
  String get jsonValue {
    switch (this) {
      case FacadeMarkerType.console:
        return 'console';
      case FacadeMarkerType.diagonal:
        return 'diagonal';
      case FacadeMarkerType.ladderDeck:
        return 'ladder_deck';
      case FacadeMarkerType.opening:
        return 'opening';
      case FacadeMarkerType.textNote:
        return 'text_note';
    }
  }
}

FacadeMarkerType facadeMarkerTypeFromJsonValue(String? rawType) {
  switch (rawType) {
    case 'console':
      return FacadeMarkerType.console;
    case 'diagonal':
      return FacadeMarkerType.diagonal;
    case 'ladder_deck':
    case 'ladderDeck':
      return FacadeMarkerType.ladderDeck;
    case 'opening':
      return FacadeMarkerType.opening;
    case 'text_note':
    case 'textNote':
      return FacadeMarkerType.textNote;
    default:
      return FacadeMarkerType.textNote;
  }
}

class FacadeMarker {
  const FacadeMarker({
    required this.id,
    required this.type,
    required this.sectionIndex,
    required this.storeyIndex,
    this.text,
    this.meta,
  });

  final String id;
  final FacadeMarkerType type;
  final int sectionIndex;
  final int storeyIndex;
  final String? text;
  final Map<String, dynamic>? meta;

  FacadeMarker copyWith({
    String? id,
    FacadeMarkerType? type,
    int? sectionIndex,
    int? storeyIndex,
    String? text,
    Map<String, dynamic>? meta,
    bool clearText = false,
    bool clearMeta = false,
  }) {
    return FacadeMarker(
      id: id ?? this.id,
      type: type ?? this.type,
      sectionIndex: sectionIndex ?? this.sectionIndex,
      storeyIndex: storeyIndex ?? this.storeyIndex,
      text: clearText ? null : (text ?? this.text),
      meta: clearMeta ? null : (meta ?? this.meta),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.jsonValue,
      'sectionIndex': sectionIndex,
      'storeyIndex': storeyIndex,
      'text': text,
      'meta': meta,
    };
  }

  factory FacadeMarker.fromJson(Map<String, dynamic> json) {
    return FacadeMarker(
      id: (json['id'] as String?) ?? '',
      type: facadeMarkerTypeFromJsonValue(json['type'] as String?),
      sectionIndex: (json['sectionIndex'] as num?)?.toInt() ?? 0,
      storeyIndex: (json['storeyIndex'] as num?)?.toInt() ?? 0,
      text: json['text'] as String?,
      meta: (json['meta'] as Map?)?.map(
        (key, value) => MapEntry('$key', value),
      ),
    );
  }
}

class FacadeSection {
  const FacadeSection({required this.id, required this.widthM});

  final String id;
  final double widthM;

  FacadeSection copyWith({String? id, double? widthM}) {
    return FacadeSection(id: id ?? this.id, widthM: widthM ?? this.widthM);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'widthM': widthM,
    };
  }

  factory FacadeSection.fromJson(Map<String, dynamic> json) {
    return FacadeSection(
      id: (json['id'] as String?) ?? '',
      widthM: (json['widthM'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ManualPackingListItem {
  const ManualPackingListItem({
    required this.id,
    required this.text,
    this.quantity,
    this.unit,
  });

  final String id;
  final String text;
  final double? quantity;
  final String? unit;

  ManualPackingListItem copyWith({
    String? id,
    String? text,
    double? quantity,
    String? unit,
    bool clearQuantity = false,
    bool clearUnit = false,
  }) {
    return ManualPackingListItem(
      id: id ?? this.id,
      text: text ?? this.text,
      quantity: clearQuantity ? null : (quantity ?? this.quantity),
      unit: clearUnit ? null : (unit ?? this.unit),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'quantity': quantity,
      'unit': unit,
    };
  }

  factory ManualPackingListItem.fromJson(Map<String, dynamic> json) {
    return ManualPackingListItem(
      id: (json['id'] as String?) ?? '',
      text: (json['text'] as String?) ?? '',
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
    );
  }
}

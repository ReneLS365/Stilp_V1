import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/core/models/manual_packing_list_item.dart';

void main() {
  test('serializes and parses text quantity and unit', () {
    const item = ManualPackingListItem(
      id: 'item-1',
      text: 'Stilladsrammer',
      quantity: 40,
      unit: 'stk',
    );

    final json = item.toJson();
    final restored = ManualPackingListItem.fromJson(json);

    expect(restored.id, 'item-1');
    expect(restored.text, 'Stilladsrammer');
    expect(restored.quantity, 40);
    expect(restored.unit, 'stk');
  });

  test('supports null quantity and unit round-trip', () {
    const item = ManualPackingListItem(
      id: 'item-2',
      text: 'Ekstra rækværk',
    );

    final restored = ManualPackingListItem.fromJson(item.toJson());

    expect(restored.quantity, isNull);
    expect(restored.unit, isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/features/plan_view/height_input_parser.dart';

void main() {
  group('parseHeightInputMm', () {
    test('parses integer millimetres', () {
      final result = parseHeightInputMm('3200');

      expect(result.isValid, isTrue);
      expect(result.valueMm, 3200);
    });

    test('treats empty input as explicit clear', () {
      final result = parseHeightInputMm('  ');

      expect(result.isValid, isTrue);
      expect(result.valueMm, isNull);
    });

    test('rejects non-empty invalid input', () {
      final invalidComma = parseHeightInputMm('3,200');
      final invalidUnit = parseHeightInputMm('3200mm');
      final invalidWord = parseHeightInputMm('abc');

      expect(invalidComma.isValid, isFalse);
      expect(invalidUnit.isValid, isFalse);
      expect(invalidWord.isValid, isFalse);
    });
  });
}

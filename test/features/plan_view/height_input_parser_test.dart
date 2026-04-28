import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/features/plan_view/height_input_parser.dart';

void main() {
  group('parseHeightInputMm', () {
    test('parses decimal meter with comma', () {
      final result = parseHeightInputMm('10,20');

      expect(result.isValid, isTrue);
      expect(result.valueMm, 10200);
    });

    test('parses decimal meter with dot', () {
      final result = parseHeightInputMm('10.20');

      expect(result.isValid, isTrue);
      expect(result.valueMm, 10200);
    });

    test('parses decimal meter with unit suffix and spacing', () {
      final result = parseHeightInputMm('10,20 m');

      expect(result.isValid, isTrue);
      expect(result.valueMm, 10200);
    });

    test('parses short decimal meter value', () {
      final result = parseHeightInputMm('0,60');

      expect(result.isValid, isTrue);
      expect(result.valueMm, 600);
    });

    test('treats empty input as explicit clear', () {
      final result = parseHeightInputMm('  ');

      expect(result.isValid, isTrue);
      expect(result.valueMm, isNull);
    });

    test('rejects non-empty invalid input', () {
      final invalidNegative = parseHeightInputMm('-1');
      final invalidWord = parseHeightInputMm('abc');
      final invalidMixed = parseHeightInputMm('10,2,0');

      expect(invalidNegative.isValid, isFalse);
      expect(invalidWord.isValid, isFalse);
      expect(invalidMixed.isValid, isFalse);
    });
  });

  group('formatMetersInput', () {
    test('formats values to meters with comma and suffix', () {
      expect(formatMetersInput(10200), '10,20 m');
      expect(formatMetersInput(600), '0,60 m');
    });
  });
}

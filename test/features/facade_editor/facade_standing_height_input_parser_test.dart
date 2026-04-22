import 'package:flutter_test/flutter_test.dart';
import 'package:stilp_v1/src/features/facade_editor/facade_standing_height_input_parser.dart';

void main() {
  group('parseFacadeStandingHeightInputM', () {
    test('parses positive metre values', () {
      final result = parseFacadeStandingHeightInputM('3.2');

      expect(result.isValid, isTrue);
      expect(result.isClear, isFalse);
      expect(result.valueM, closeTo(3.2, 0.0001));
    });

    test('treats empty input as explicit clear', () {
      final result = parseFacadeStandingHeightInputM('   ');

      expect(result.isValid, isTrue);
      expect(result.isClear, isTrue);
      expect(result.valueM, isNull);
    });

    test('rejects invalid non-empty input', () {
      final invalidComma = parseFacadeStandingHeightInputM('3,2m');
      final invalidUnit = parseFacadeStandingHeightInputM('3200mm');
      final invalidWord = parseFacadeStandingHeightInputM('abc');

      expect(invalidComma.isValid, isFalse);
      expect(invalidUnit.isValid, isFalse);
      expect(invalidWord.isValid, isFalse);
    });
  });
}

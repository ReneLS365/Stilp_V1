class HeightInputParseResult {
  const HeightInputParseResult._({
    required this.isValid,
    required this.valueMm,
  });

  const HeightInputParseResult.valid(int? valueMm)
      : this._(
          isValid: true,
          valueMm: valueMm,
        );

  const HeightInputParseResult.invalid()
      : this._(
          isValid: false,
          valueMm: null,
        );

  final bool isValid;
  final int? valueMm;
}

HeightInputParseResult parseHeightInputMm(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return const HeightInputParseResult.valid(null);
  }

  final normalized = trimmed.replaceAll(RegExp(r'\s+'), '');
  final match = RegExp(r'^(\d+(?:[.,]\d+)?)m?$').firstMatch(normalized);
  if (match == null) {
    return const HeightInputParseResult.invalid();
  }

  final meters = double.tryParse(match.group(1)!.replaceAll(',', '.'));
  if (meters == null || meters.isNaN || meters.isInfinite || meters < 0) {
    return const HeightInputParseResult.invalid();
  }

  return HeightInputParseResult.valid((meters * 1000).round());
}

String formatMetersInput(int? valueMm) {
  if (valueMm == null) {
    return '';
  }

  final meters = (valueMm / 1000).toStringAsFixed(2).replaceAll('.', ',');
  return '$meters m';
}

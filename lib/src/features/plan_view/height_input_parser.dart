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

  final parsed = int.tryParse(trimmed);
  if (parsed == null || parsed < 0) {
    return const HeightInputParseResult.invalid();
  }

  return HeightInputParseResult.valid(parsed);
}

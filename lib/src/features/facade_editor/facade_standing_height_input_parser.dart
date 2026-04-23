class FacadeStandingHeightParseResult {
  const FacadeStandingHeightParseResult._({
    required this.isValid,
    required this.valueM,
    required this.isClear,
  });

  const FacadeStandingHeightParseResult.valid(double valueM)
      : this._(
          isValid: true,
          valueM: valueM,
          isClear: false,
        );

  const FacadeStandingHeightParseResult.clear()
      : this._(
          isValid: true,
          valueM: null,
          isClear: true,
        );

  const FacadeStandingHeightParseResult.invalid()
      : this._(
          isValid: false,
          valueM: null,
          isClear: false,
        );

  final bool isValid;
  final double? valueM;
  final bool isClear;
}

FacadeStandingHeightParseResult parseFacadeStandingHeightInputM(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return const FacadeStandingHeightParseResult.clear();
  }

  final parsed = double.tryParse(trimmed);
  if (parsed == null || !parsed.isFinite || parsed <= 0) {
    return const FacadeStandingHeightParseResult.invalid();
  }

  return FacadeStandingHeightParseResult.valid(parsed);
}

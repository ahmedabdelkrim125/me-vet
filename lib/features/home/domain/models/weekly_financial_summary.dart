class WeeklyFinancialSummary {
  final double currentWeekCollections;
  final double previousWeekCollections;

  const WeeklyFinancialSummary({
    required this.currentWeekCollections,
    required this.previousWeekCollections,
  });

  double get collectionsTrendPercent {
    if (previousWeekCollections <= 0) {
      return currentWeekCollections > 0 ? 100 : 0;
    }
    return ((currentWeekCollections - previousWeekCollections) /
            previousWeekCollections) *
        100;
  }

  static const empty = WeeklyFinancialSummary(
    currentWeekCollections: 0,
    previousWeekCollections: 0,
  );
}

class StatisticsFailure implements Exception {
  const StatisticsFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

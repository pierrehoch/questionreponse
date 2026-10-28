class ResponseFailure implements Exception {
  const ResponseFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

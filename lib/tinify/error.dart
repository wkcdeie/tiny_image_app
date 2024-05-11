class ApiError extends Error {
  final String message;
  final String error;

  ApiError(this.message, this.error);

  @override
  String toString() {
    return '$error-$message';
  }
}

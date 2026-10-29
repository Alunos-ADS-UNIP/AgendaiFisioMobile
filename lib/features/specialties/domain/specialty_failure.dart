enum SpecialtyFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  network,
  invalidResponse,
  unexpected,
}

class SpecialtyException implements Exception {
  const SpecialtyException(this.failure, this.message);

  final SpecialtyFailure failure;
  final String message;

  int? get statusCode => switch (failure) {
    SpecialtyFailure.badRequest => 400,
    SpecialtyFailure.unauthorized => 401,
    SpecialtyFailure.forbidden => 403,
    SpecialtyFailure.notFound => 404,
    SpecialtyFailure.conflict => 409,
    _ => null,
  };

  @override
  String toString() => 'SpecialtyException($failure): $message';
}

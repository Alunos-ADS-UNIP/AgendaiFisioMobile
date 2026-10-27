/// Tipos de falha da disponibilidade (mesmo padrão de appointment_failure).
enum AvailabilityFailure {
  /// Backend ainda não possui a rota/contrato desta funcionalidade.
  unavailable,
  network,
  unauthorized,
  invalidData,
  unknown,
}

class AvailabilityException implements Exception {
  const AvailabilityException(this.failure, [this.message]);

  final AvailabilityFailure failure;
  final String? message;

  @override
  String toString() => 'AvailabilityException($failure, $message)';
}

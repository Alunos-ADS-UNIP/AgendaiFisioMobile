/// Motivos pelos quais o histórico não pôde ser carregado.
enum HistoryFailure {
  /// 403 ou 404: tratados igualmente para não revelar se o paciente existe.
  accessDenied,

  /// 401: a sessão deve ser encerrada pelo fluxo global de autenticação.
  sessionExpired,

  /// Sem conexão ou falha de transporte.
  network,

  /// Resposta inesperada da API.
  unexpected,
}

class HistoryException implements Exception {
  const HistoryException(this.failure);

  final HistoryFailure failure;

  @override
  String toString() => 'HistoryException($failure)';
}

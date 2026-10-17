import 'appointment_history_entry.dart';

/// Acesso ao histórico de consultas. Falhas são lançadas como HistoryException.
abstract interface class HistoryRepository {
  /// Histórico do paciente logado. Usa somente a rota /me; nunca recebe ID.
  Future<AppointmentHistoryPage> fetchMyHistory({
    required int page,
    required int pageSize,
  });

  /// Histórico visto pelo profissional. O `patientId` deve vir de um fluxo
  /// autorizado; a API responde 404 quando não há vínculo.
  Future<AppointmentHistoryPage> fetchPatientHistory({
    required String patientId,
    required int page,
    required int pageSize,
  });
}

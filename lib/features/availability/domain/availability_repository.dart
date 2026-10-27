import 'availability_failure.dart';
import 'availability_models.dart';

/// Contrato de acesso à disponibilidade.
///
/// NÃO existe rota no backend ainda: esta interface não conhece URLs nem
/// payloads. A implementação HTTP só será escrita quando o backend publicar o
/// contrato (rotas de grade e horários livres, fuso, duração, sobreposição).
/// Implementações devem lançar [AvailabilityException].
abstract interface class AvailabilityRepository {
  /// Lê a grade semanal do fisioterapeuta autenticado.
  Future<WeeklySchedule> fetchWeeklySchedule();

  /// Salva a grade semanal. Só pode ser considerado "integrado" quando
  /// persistir no backend de verdade.
  Future<void> saveWeeklySchedule(WeeklySchedule schedule);

  /// Horários da [date] calculados com a grade e os agendamentos existentes.
  Future<List<AvailableSlot>> fetchSlots({
    required String professionalId,
    required DateTime date,
  });
}

/// Implementação usada enquanto o backend não tem contrato: sempre indica
/// "indisponível", para a UI mostrar estado honesto em vez de dados falsos.
class UnavailableAvailabilityRepository implements AvailabilityRepository {
  const UnavailableAvailabilityRepository();

  static const _error =
      AvailabilityException(AvailabilityFailure.unavailable);

  @override
  Future<WeeklySchedule> fetchWeeklySchedule() => Future.error(_error);

  @override
  Future<void> saveWeeklySchedule(WeeklySchedule schedule) =>
      Future.error(_error);

  @override
  Future<List<AvailableSlot>> fetchSlots({
    required String professionalId,
    required DateTime date,
  }) =>
      Future.error(_error);
}

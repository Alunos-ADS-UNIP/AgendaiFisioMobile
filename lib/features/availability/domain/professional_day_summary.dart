import '../../../core/models/appointment_status.dart';
import '../../appointments/domain/appointment.dart';

/// Resumo do dia do fisioterapeuta, calculado a partir da lista de
/// agendamentos (GET /api/agendamento). Sem HTTP: só regra de apresentação.
///
/// As datas de [Appointment.dateTime] já chegam em horário local.
class ProfessionalDaySummary {
  const ProfessionalDaySummary({
    required this.todayCount,
    required this.upcoming,
  });

  /// Consultas de hoje, exceto canceladas.
  final int todayCount;

  /// Próximas consultas (agendadas ou confirmadas), da mais próxima à mais
  /// distante, limitadas a [limit].
  final List<Appointment> upcoming;

  factory ProfessionalDaySummary.from(
    List<Appointment> appointments, {
    required DateTime now,
    int limit = 5,
  }) {
    bool isToday(DateTime d) =>
        d.year == now.year && d.month == now.month && d.day == now.day;

    final todayCount = appointments
        .where((a) => isToday(a.dateTime))
        .where((a) => a.status != AppointmentStatus.cancelled)
        .length;

    final upcoming =
        appointments
            .where((a) => a.dateTime.isAfter(now))
            .where(
              (a) =>
                  a.status == AppointmentStatus.scheduled ||
                  a.status == AppointmentStatus.confirmed,
            )
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return ProfessionalDaySummary(
      todayCount: todayCount,
      upcoming: List.unmodifiable(upcoming.take(limit)),
    );
  }
}

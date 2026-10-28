import '../../appointments/domain/appointment_failure.dart';
import '../domain/availability_failure.dart';
import '../domain/availability_models.dart';
import '../domain/availability_repository.dart';

/// Agendamento técnico "Bloqueado" que ocupa um horário fora da grade.
class ScheduleBlock {
  const ScheduleBlock({required this.id, required this.dateTime});

  final String id;

  /// Data/hora local do horário bloqueado.
  final DateTime dateTime;
}

/// Operações de bloqueio expostas pela API de agendamentos
/// (POST /api/agendamento com token de profissional, GET filtrando
/// status "Bloqueado" e PATCH /cancelar). Lança [AppointmentException].
abstract interface class ScheduleBlockGateway {
  Future<List<ScheduleBlock>> fetchScheduleBlocks(String professionalId);

  Future<void> createScheduleBlock({
    required String professionalId,
    required DateTime dateTime,
  });

  Future<void> cancelScheduleBlock(String id);
}

/// Grade semanal guardada como agendamentos falsos.
///
/// O backend não tem rota para a grade, então cada horário de 30 min fora dos
/// turnos ativos, dentro da janela do seletor (06:00–22:00) e das próximas
/// [horizonDays], vira um agendamento "Bloqueado". Assim o backend recusa
/// (409) qualquer paciente que tente reservar esse horário.
///
/// Salvar compara com os bloqueios existentes: cria os que faltam e cancela
/// os que voltaram a ficar dentro da grade. Ler reconstrói os turnos de cada
/// dia da semana a partir dos bloqueios da próxima data daquele dia.
class AppointmentBlockAvailabilityRepository implements AvailabilityRepository {
  AppointmentBlockAvailabilityRepository({
    required this.gateway,
    required this.professionalId,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ScheduleBlockGateway gateway;
  final String professionalId;
  final DateTime Function() _clock;

  /// Mesma janela e intervalo do TimeSlotPickerSheet.
  static const firstSlotMinutes = 6 * 60;
  static const lastSlotMinutes = 22 * 60;
  static const slotMinutes = 30;

  /// Quantos dias à frente recebem bloqueios a cada salvamento.
  static const horizonDays = 14;

  /// Requisições simultâneas ao salvar.
  static const _parallelRequests = 6;

  static List<int> get _daySlots => [
    for (var m = firstSlotMinutes; m <= lastSlotMinutes; m += slotMinutes) m,
  ];

  @override
  Future<WeeklySchedule> fetchWeeklySchedule() async {
    final blocks = await _futureBlocks();
    // Sem nenhum bloqueio a grade nunca foi configurada.
    if (blocks.isEmpty) return WeeklySchedule.empty();

    final blocked = {for (final b in blocks) _key(b.dateTime)};
    final tomorrow = _dateOnly(_clock()).add(const Duration(days: 1));
    return WeeklySchedule(
      days: [
        for (var i = 0; i < 7; i++)
          _dayFromBlocks(tomorrow.add(Duration(days: i)), blocked),
      ],
    );
  }

  DayAvailability _dayFromBlocks(DateTime date, Set<String> blocked) {
    final shifts = <TimeRange>[];
    int? start;
    int? previous;
    for (final minutes in _daySlots) {
      final free = !blocked.contains(_key(_at(date, minutes)));
      if (free) {
        start ??= minutes;
        previous = minutes;
      } else if (start != null) {
        shifts.add(_range(start, previous! + slotMinutes));
        start = null;
      }
    }
    if (start != null) shifts.add(_range(start, previous! + slotMinutes));
    return DayAvailability(
      day: WeekDay.fromDate(date),
      enabled: shifts.isNotEmpty,
      shifts: shifts,
    );
  }

  @override
  Future<void> saveWeeklySchedule(WeeklySchedule schedule) async {
    final now = _clock();
    final existing = {for (final b in await _futureBlocks()) _key(b.dateTime): b};

    final wanted = <String, DateTime>{};
    final today = _dateOnly(now);
    for (var i = 0; i < horizonDays; i++) {
      final date = today.add(Duration(days: i));
      final day = schedule.dayOf(WeekDay.fromDate(date));
      for (final minutes in _daySlots) {
        final slot = _at(date, minutes);
        if (!slot.isAfter(now)) continue;
        if (_isInsideShifts(day, minutes)) continue;
        wanted[_key(slot)] = slot;
      }
    }

    final toCreate = [
      for (final entry in wanted.entries)
        if (!existing.containsKey(entry.key)) entry.value,
    ];
    final toCancel = [
      for (final entry in existing.entries)
        if (!wanted.containsKey(entry.key)) entry.value.id,
    ];

    await _guard(() async {
      await _inBatches(toCancel, gateway.cancelScheduleBlock);
      await _inBatches(
        toCreate,
        (slot) => gateway.createScheduleBlock(
          professionalId: professionalId,
          dateTime: slot,
        ),
      );
    });
  }

  @override
  Future<List<AvailableSlot>> fetchSlots({
    required String professionalId,
    required DateTime date,
  }) =>
      Future.error(const AvailabilityException(AvailabilityFailure.unavailable));

  Future<List<ScheduleBlock>> _futureBlocks() async {
    final now = _clock();
    final blocks = await _guard(
      () => gateway.fetchScheduleBlocks(professionalId),
    );
    return blocks.where((b) => b.dateTime.isAfter(now)).toList();
  }

  static bool _isInsideShifts(DayAvailability day, int minutes) =>
      day.enabled &&
      day.shifts.any(
        (s) => s.start.totalMinutes <= minutes && minutes < s.end.totalMinutes,
      );

  static Future<void> _inBatches<T>(
    List<T> items,
    Future<void> Function(T item) action,
  ) async {
    for (var i = 0; i < items.length; i += _parallelRequests) {
      final end = (i + _parallelRequests).clamp(0, items.length);
      await Future.wait(items.sublist(i, end).map(action));
    }
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on AppointmentException catch (error) {
      throw AvailabilityException(switch (error.failure) {
        AppointmentFailure.network => AvailabilityFailure.network,
        AppointmentFailure.unauthorized => AvailabilityFailure.unauthorized,
        AppointmentFailure.invalid => AvailabilityFailure.invalidData,
        _ => AvailabilityFailure.unknown,
      });
    }
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime _at(DateTime date, int minutes) =>
      DateTime(date.year, date.month, date.day, minutes ~/ 60, minutes % 60);

  static String _key(DateTime value) =>
      '${value.year}-${value.month}-${value.day} ${value.hour}:${value.minute}';

  static TimeRange _range(int start, int end) => TimeRange(
    start: TimeOfDayValue(start ~/ 60, start % 60),
    end: end >= 24 * 60
        ? const TimeOfDayValue(23, 59)
        : TimeOfDayValue(end ~/ 60, end % 60),
  );
}

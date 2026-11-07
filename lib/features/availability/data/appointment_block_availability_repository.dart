import '../../appointments/domain/appointment_failure.dart';
import '../domain/availability_failure.dart';
import '../domain/availability_models.dart';
import '../domain/availability_repository.dart';

/// Bloqueio de agenda do profissional (rotas /api/agenda/bloqueios).
class ScheduleBlock {
  const ScheduleBlock({
    required this.id,
    required this.start,
    required this.end,
    this.isFullDay = false,
  });

  final String id;

  /// Início e fim locais do período bloqueado (fim exclusivo).
  final DateTime start;
  final DateTime end;

  /// Bloqueio do dia inteiro; caso contrário, de uma hora.
  final bool isFullDay;

  bool covers(DateTime moment) =>
      !moment.isBefore(start) && moment.isBefore(end);
}

/// Operações das rotas de bloqueio do profissional logado. Lança
/// [AppointmentException]. As criações devolvem false quando o horário ou o dia
/// já está ocupado (409), por exemplo por uma consulta marcada.
abstract interface class ScheduleBlockGateway {
  Future<List<ScheduleBlock>> fetchScheduleBlocks({
    required DateTime from,
    required DateTime to,
  });

  /// Bloqueia uma hora que começa em [start] (sempre em hora cheia).
  Future<bool> createHourBlock(DateTime start);

  /// Bloqueia o dia inteiro de [date].
  Future<bool> createDayBlock(DateTime date);

  Future<void> deleteScheduleBlock(String id);

  /// Início das consultas marcadas (não canceladas) do profissional logado.
  /// Essas horas não aceitam bloqueio, então não dizem se o dia tem grade.
  Future<List<DateTime>> fetchBookedHours({
    required DateTime from,
    required DateTime to,
  });
}

/// Grade semanal guardada como bloqueios de agenda.
///
/// Nas próximas [horizonDays], um dia desativado vira um bloqueio de dia
/// inteiro, e num dia com turnos cada hora fora deles (de [firstHour] a
/// [lastHour]) vira um bloqueio de uma hora. As consultas são sempre em hora
/// cheia, então a grade também é.
///
/// Salvar compara com os bloqueios existentes: cria os que faltam e remove os
/// que voltaram a ficar dentro da grade. Ler reconstrói os turnos de cada dia
/// da semana a partir dos bloqueios da próxima data daquele dia.
class AppointmentBlockAvailabilityRepository implements AvailabilityRepository {
  AppointmentBlockAvailabilityRepository({
    required this.gateway,
    required this.professionalId,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ScheduleBlockGateway gateway;
  final String professionalId;
  final DateTime Function() _clock;

  /// Primeira e última hora em que uma consulta pode começar.
  static const firstHour = 6;
  static const lastHour = 21;

  /// Quantos dias à frente recebem bloqueios a cada salvamento.
  static const horizonDays = 14;

  /// Requisições simultâneas ao salvar.
  static const _parallelRequests = 6;

  static List<int> get _hours => [
    for (var h = firstHour; h <= lastHour; h++) h,
  ];

  @override
  Future<WeeklySchedule> fetchWeeklySchedule() async {
    final blocks = await _horizonBlocks();
    // Sem nenhum bloqueio a grade nunca foi configurada.
    if (blocks.isEmpty) return WeeklySchedule.empty();

    final tomorrow = _dateOnly(_clock()).add(const Duration(days: 1));
    final booked = await _bookedHours(
      tomorrow,
      tomorrow.add(const Duration(days: 7)),
    );
    return WeeklySchedule(
      days: [
        for (var i = 0; i < 7; i++)
          _dayFromBlocks(tomorrow.add(Duration(days: i)), blocks, booked),
      ],
    );
  }

  /// Sem a lista de consultas, a grade ainda é lida só pelos bloqueios.
  Future<Set<DateTime>> _bookedHours(DateTime from, DateTime to) async {
    try {
      final starts = await gateway.fetchBookedHours(from: from, to: to);
      return {for (final s in starts) _at(s, s.hour)};
    } catch (_) {
      return const {};
    }
  }

  /// Uma hora com consulta não pode ser bloqueada: conta como parte do turno
  /// ao redor, mas sozinha não faz o dia aparecer como dia de atendimento.
  DayAvailability _dayFromBlocks(
    DateTime date,
    List<ScheduleBlock> blocks,
    Set<DateTime> booked,
  ) {
    bool isBlocked(int hour) => blocks.any((b) => b.covers(_at(date, hour)));
    bool isBooked(int hour) => booked.contains(_at(date, hour));
    // Cada sequência de horas sem bloqueio vira um turno, desde que tenha ao
    // menos uma hora sem consulta.
    final shifts = <TimeRange>[];
    int? start;
    var hasOpenHour = false;
    void close(int end) {
      if (start != null && hasOpenHour) shifts.add(_range(start!, end));
      start = null;
      hasOpenHour = false;
    }

    for (final hour in _hours) {
      if (isBlocked(hour)) {
        close(hour);
        continue;
      }
      start ??= hour;
      if (!isBooked(hour)) hasOpenHour = true;
    }
    close(lastHour + 1);
    return DayAvailability(
      day: WeekDay.fromDate(date),
      enabled: shifts.isNotEmpty,
      shifts: shifts,
    );
  }

  @override
  Future<void> saveWeeklySchedule(WeeklySchedule schedule) async {
    final now = _clock();
    final today = _dateOnly(now);
    final blocks = await _horizonBlocks();

    await _guard(() async {
      for (var i = 0; i < horizonDays; i++) {
        final date = today.add(Duration(days: i));
        final day = schedule.dayOf(WeekDay.fromDate(date));
        final ofDate = blocks.where((b) => _dateOnly(b.start) == date).toList();
        await _saveDate(date, day, ofDate, now);
      }
    });
  }

  Future<void> _saveDate(
    DateTime date,
    DayAvailability day,
    List<ScheduleBlock> existing,
    DateTime now,
  ) async {
    final dayBlocks = existing.where((b) => b.isFullDay).toList();
    final hourBlocks = {
      for (final b in existing.where((b) => !b.isFullDay)) b.start.hour: b,
    };
    final futureHours = [
      for (final hour in _hours)
        if (_at(date, hour).isAfter(now)) hour,
    ];

    // Dia sem atendimento: um bloqueio só, para o dia inteiro.
    if (!day.enabled || day.shifts.isEmpty) {
      if (dayBlocks.isNotEmpty) return;
      if (await gateway.createDayBlock(date)) {
        await _inBatches(
          hourBlocks.values.toList(),
          (b) => gateway.deleteScheduleBlock(b.id),
        );
        return;
      }
      // O dia tem consulta marcada: bloqueia só as horas que ainda estão livres.
      await _inBatches([
        for (final hour in futureHours)
          if (!hourBlocks.containsKey(hour)) hour,
      ], (hour) => gateway.createHourBlock(_at(date, hour)));
      return;
    }

    // Dia com turnos: uma hora bloqueada para cada hora fora deles.
    await _inBatches(dayBlocks, (b) => gateway.deleteScheduleBlock(b.id));
    final wanted = {
      for (final hour in futureHours)
        if (!_isInsideShifts(day, hour)) hour,
    };
    await _inBatches([
      for (final entry in hourBlocks.entries)
        if (!wanted.contains(entry.key) && entry.value.start.isAfter(now))
          entry.value,
    ], (b) => gateway.deleteScheduleBlock(b.id));
    await _inBatches([
      for (final hour in wanted)
        if (!hourBlocks.containsKey(hour)) hour,
    ], (hour) => gateway.createHourBlock(_at(date, hour)));
  }

  @override
  Future<List<AvailableSlot>> fetchSlots({
    required String professionalId,
    required DateTime date,
  }) => Future.error(
    const AvailabilityException(AvailabilityFailure.unavailable),
  );

  /// Bloqueios de hoje até o fim do horizonte.
  Future<List<ScheduleBlock>> _horizonBlocks() {
    final today = _dateOnly(_clock());
    return _guard(
      () => gateway.fetchScheduleBlocks(
        from: today,
        to: today.add(const Duration(days: horizonDays + 1)),
      ),
    );
  }

  static bool _isInsideShifts(DayAvailability day, int hour) => day.shifts.any(
    (s) => s.start.totalMinutes <= hour * 60 && hour * 60 < s.end.totalMinutes,
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

  static DateTime _at(DateTime date, int hour) =>
      DateTime(date.year, date.month, date.day, hour);

  static TimeRange _range(int startHour, int endHour) => TimeRange(
    start: TimeOfDayValue(startHour, 0),
    end: endHour >= 24
        ? const TimeOfDayValue(23, 59)
        : TimeOfDayValue(endHour, 0),
  );
}

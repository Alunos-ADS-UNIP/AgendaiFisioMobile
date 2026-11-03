import 'package:agendaifisiomobile/features/availability/data/appointment_block_availability_repository.dart';
import 'package:agendaifisiomobile/features/availability/domain/availability_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGateway implements ScheduleBlockGateway {
  final blocks = <ScheduleBlock>[];
  final createdHours = <DateTime>[];
  final createdDays = <DateTime>[];
  final deleted = <String>[];

  /// Dias em que o servidor recusa o bloqueio do dia inteiro (há consulta).
  final busyDays = <DateTime>{};
  var _nextId = 0;

  @override
  Future<List<ScheduleBlock>> fetchScheduleBlocks({
    required DateTime from,
    required DateTime to,
  }) async => [
    for (final b in blocks)
      if (!b.start.isBefore(from) && b.start.isBefore(to)) b,
  ];

  @override
  Future<bool> createHourBlock(DateTime start) async {
    createdHours.add(start);
    blocks.add(
      ScheduleBlock(
        id: 'h${_nextId++}',
        start: start,
        end: start.add(const Duration(hours: 1)),
      ),
    );
    return true;
  }

  @override
  Future<bool> createDayBlock(DateTime date) async {
    if (busyDays.contains(date)) return false;
    createdDays.add(date);
    blocks.add(
      ScheduleBlock(
        id: 'd${_nextId++}',
        start: date,
        end: date.add(const Duration(days: 1)),
        isFullDay: true,
      ),
    );
    return true;
  }

  @override
  Future<void> deleteScheduleBlock(String id) async {
    deleted.add(id);
    blocks.removeWhere((b) => b.id == id);
  }
}

void main() {
  // Segunda-feira, 05:00: todos os horários do dia ainda estão no futuro.
  final now = DateTime(2026, 11, 2, 5);
  const morning = TimeRange(
    start: TimeOfDayValue(8, 0),
    end: TimeOfDayValue(12, 0),
  );

  WeeklySchedule onlyMondayMorning() => WeeklySchedule(
    days: const [
      DayAvailability(day: WeekDay.monday, enabled: true, shifts: [morning]),
    ],
  );

  late _FakeGateway gateway;
  late AppointmentBlockAvailabilityRepository repository;

  setUp(() {
    gateway = _FakeGateway();
    repository = AppointmentBlockAvailabilityRepository(
      gateway: gateway,
      professionalId: 'prof-1',
      clock: () => now,
    );
  });

  test('sem bloqueios a grade volta vazia', () async {
    final schedule = await repository.fetchWeeklySchedule();
    expect(schedule.hasAnyActiveDay, isFalse);
  });

  test(
    'bloqueia as horas cheias fora da grade e o dia inteiro sem atendimento',
    () async {
      await repository.saveWeeklySchedule(onlyMondayMorning());

      final monday = gateway.createdHours.where((d) => d.day == 2).toList();
      expect(monday, contains(DateTime(2026, 11, 2, 7)));
      expect(monday, contains(DateTime(2026, 11, 2, 12)));
      expect(monday, isNot(contains(DateTime(2026, 11, 2, 8))));
      expect(monday, isNot(contains(DateTime(2026, 11, 2, 11))));
      // 06:00–07:00 e 12:00–21:00: 2 + 10 horas.
      expect(monday, hasLength(12));
      expect(monday.every((d) => d.minute == 0), isTrue);
      // Terça desativada: um bloqueio de dia inteiro, sem horas soltas.
      expect(gateway.createdDays, contains(DateTime(2026, 11, 3)));
      expect(gateway.createdHours.where((d) => d.day == 3), isEmpty);
    },
  );

  test('lê de volta a grade salva', () async {
    await repository.saveWeeklySchedule(onlyMondayMorning());

    final schedule = await repository.fetchWeeklySchedule();
    final monday = schedule.dayOf(WeekDay.monday);
    expect(monday.enabled, isTrue);
    expect(monday.shifts, [morning]);
    expect(schedule.dayOf(WeekDay.tuesday).enabled, isFalse);
  });

  test(
    'ao ampliar a grade remove só os bloqueios que voltaram a valer',
    () async {
      await repository.saveWeeklySchedule(onlyMondayMorning());
      gateway.createdHours.clear();
      gateway.createdDays.clear();

      await repository.saveWeeklySchedule(
        WeeklySchedule(
          days: const [
            DayAvailability(
              day: WeekDay.monday,
              enabled: true,
              shifts: [
                TimeRange(
                  start: TimeOfDayValue(8, 0),
                  end: TimeOfDayValue(13, 0),
                ),
              ],
            ),
          ],
        ),
      );

      // 12:00 das duas segundas-feiras do horizonte.
      expect(gateway.deleted, hasLength(2));
      expect(gateway.createdHours, isEmpty);
      expect(gateway.createdDays, isEmpty);
    },
  );

  test('não bloqueia horas que já passaram', () async {
    final late = AppointmentBlockAvailabilityRepository(
      gateway: gateway,
      professionalId: 'prof-1',
      clock: () => DateTime(2026, 11, 2, 20, 10),
    );
    await late.saveWeeklySchedule(onlyMondayMorning());

    final today = gateway.createdHours.where((d) => d.day == 2).toList();
    expect(today, [DateTime(2026, 11, 2, 21)]);
  });

  test('dia com consulta marcada bloqueia só as horas livres', () async {
    gateway.busyDays.add(DateTime(2026, 11, 3));

    await repository.saveWeeklySchedule(onlyMondayMorning());

    expect(gateway.createdDays, isNot(contains(DateTime(2026, 11, 3))));
    // 06:00 a 21:00: 16 horas cheias.
    expect(gateway.createdHours.where((d) => d.day == 3), hasLength(16));
  });
}

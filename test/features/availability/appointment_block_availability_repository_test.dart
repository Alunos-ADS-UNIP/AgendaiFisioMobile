import 'package:agendaifisiomobile/features/availability/data/appointment_block_availability_repository.dart';
import 'package:agendaifisiomobile/features/availability/domain/availability_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGateway implements ScheduleBlockGateway {
  final blocks = <ScheduleBlock>[];
  final created = <DateTime>[];
  final cancelled = <String>[];
  var _nextId = 0;

  @override
  Future<List<ScheduleBlock>> fetchScheduleBlocks(String professionalId) async =>
      List.of(blocks);

  @override
  Future<void> createScheduleBlock({
    required String professionalId,
    required DateTime dateTime,
  }) async {
    created.add(dateTime);
    blocks.add(ScheduleBlock(id: 'b${_nextId++}', dateTime: dateTime));
  }

  @override
  Future<void> cancelScheduleBlock(String id) async {
    cancelled.add(id);
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

  test('bloqueia os horários fora da grade e nada dentro dela', () async {
    await repository.saveWeeklySchedule(onlyMondayMorning());

    final monday = gateway.created.where((d) => d.day == now.day).toList();
    expect(monday, contains(DateTime(2026, 11, 2, 7, 30)));
    expect(monday, contains(DateTime(2026, 11, 2, 12, 0)));
    expect(monday, isNot(contains(DateTime(2026, 11, 2, 8, 0))));
    expect(monday, isNot(contains(DateTime(2026, 11, 2, 11, 30))));
    // Terça desativada: todos os 33 horários entre 06:00 e 22:00.
    expect(gateway.created.where((d) => d.day == 3), hasLength(33));
  });

  test('lê de volta a grade salva', () async {
    await repository.saveWeeklySchedule(onlyMondayMorning());

    final schedule = await repository.fetchWeeklySchedule();
    final monday = schedule.dayOf(WeekDay.monday);
    expect(monday.enabled, isTrue);
    expect(monday.shifts, [morning]);
    expect(schedule.dayOf(WeekDay.tuesday).enabled, isFalse);
  });

  test('ao ampliar a grade cancela só os bloqueios que voltaram a valer', () async {
    await repository.saveWeeklySchedule(onlyMondayMorning());
    gateway.created.clear();

    await repository.saveWeeklySchedule(
      WeeklySchedule(
        days: const [
          DayAvailability(
            day: WeekDay.monday,
            enabled: true,
            shifts: [
              TimeRange(start: TimeOfDayValue(8, 0), end: TimeOfDayValue(13, 0)),
            ],
          ),
        ],
      ),
    );

    // 12:00 e 12:30 das duas segundas-feiras do horizonte.
    expect(gateway.cancelled, hasLength(4));
    expect(gateway.created, isEmpty);
  });

  test('não bloqueia horários que já passaram', () async {
    final late = AppointmentBlockAvailabilityRepository(
      gateway: gateway,
      professionalId: 'prof-1',
      clock: () => DateTime(2026, 11, 2, 20, 10),
    );
    await late.saveWeeklySchedule(WeeklySchedule.empty());

    final today = gateway.created.where((d) => d.day == 2).toList();
    expect(today, [
      DateTime(2026, 11, 2, 20, 30),
      DateTime(2026, 11, 2, 21, 0),
      DateTime(2026, 11, 2, 21, 30),
      DateTime(2026, 11, 2, 22, 0),
    ]);
  });
}

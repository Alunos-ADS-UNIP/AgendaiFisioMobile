import 'package:agendaifisiomobile/features/appointments/domain/appointment.dart';
import 'package:agendaifisiomobile/features/appointments/domain/appointment_filters.dart';
import 'package:agendaifisiomobile/features/appointments/domain/appointment_repository.dart';
import 'package:agendaifisiomobile/features/appointments/domain/professional.dart';
import 'package:agendaifisiomobile/features/appointments/domain/specialty.dart';
import 'package:agendaifisiomobile/features/appointments/presentation/pages/new_appointment_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Consultas já marcadas por outros pacientes, como a rota de
/// indisponibilidade devolve: uma hora por consulta.
class _BookedRepository
    implements AppointmentRepository, ProfessionalUnavailabilitySource {
  _BookedRepository(this.booked);

  final List<DateTime> booked;

  @override
  Future<List<UnavailablePeriod>> fetchUnavailability({
    required String professionalId,
    required DateTime from,
    required DateTime to,
  }) async => [
    for (final start in booked)
      if (!start.isBefore(from) && start.isBefore(to))
        UnavailablePeriod(
          start: start,
          end: start.add(const Duration(hours: 1)),
        ),
  ];

  @override
  Future<Professional> fetchProfessional(String id) async => Professional(
    id: id,
    name: 'Dra. Marina Lopes',
    specialtyId: 's1',
    specialtyName: 'Ortopedia',
  );

  @override
  Future<List<Specialty>> fetchSpecialties() async => const [];

  @override
  Future<List<Appointment>> fetchAppointments({
    AppointmentFilters filters = const AppointmentFilters(),
  }) async => const [];

  @override
  Future<Appointment> fetchAppointment(String id) => throw UnimplementedError();

  @override
  Future<Appointment> createAppointment({
    required String professionalId,
    required DateTime dateTime,
    String? observations,
  }) => throw UnimplementedError();

  @override
  Future<Appointment> cancelAppointment(String id) =>
      throw UnimplementedError();

  @override
  Future<List<Professional>> fetchProfessionals({
    String? specialtyId,
    bool? active,
    int page = 1,
    int pageSize = 20,
  }) async => const [];
}

void main() {
  final now = DateTime.now();
  final fullDay = DateTime(now.year, now.month + 1, 10);
  final partialDay = DateTime(now.year, now.month + 1, 12);
  final booked = [
    // Todas as horas de 06:00 a 21:00 já agendadas por pacientes.
    for (var h = 6; h <= 21; h++)
      DateTime(fullDay.year, fullDay.month, fullDay.day, h),
    DateTime(partialDay.year, partialDay.month, partialDay.day, 10),
  ];

  Finder dayCell(DateTime d) =>
      find.byKey(ValueKey('dia-${d.year}-${d.month}-${d.day}'));

  testWidgets('dias e horários agendados por pacientes ficam indisponíveis', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: NewAppointmentPage(
          repository: _BookedRepository(booked),
          initialProfessionalId: 'p1',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.pumpAndSettle();

    // Dia lotado: opaco e sem resposta ao toque.
    final fullInk = tester.widget<InkWell>(dayCell(fullDay));
    expect(fullInk.onTap, isNull);

    // Dia com uma consulta: selecionável, mas a hora marcada fica opaca.
    final partialInk = tester.widget<InkWell>(dayCell(partialDay));
    expect(partialInk.onTap, isNotNull);
    await tester.tap(dayCell(partialDay));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Selecionar horário'));
    await tester.tap(find.text('Selecionar horário'));
    await tester.pumpAndSettle();

    double opacityOf(String label) => tester
        .widget<Opacity>(
          find.ancestor(of: find.text(label), matching: find.byType(Opacity)),
        )
        .opacity;
    expect(opacityOf('10:00'), lessThan(1));
    expect(opacityOf('11:00'), 1);

    await tester.tap(find.text('10:00'));
    await tester.pump();
    expect(find.text('Selecionado: 10:00'), findsNothing);
  });
}

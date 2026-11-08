import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agendaifisiomobile/core/models/appointment_status.dart';
import 'package:agendaifisiomobile/features/appointments/domain/appointment.dart';
import 'package:agendaifisiomobile/features/appointments/domain/appointment_filters.dart';
import 'package:agendaifisiomobile/features/appointments/domain/appointment_repository.dart';
import 'package:agendaifisiomobile/features/appointments/domain/professional.dart';
import 'package:agendaifisiomobile/features/appointments/domain/specialty.dart';
import 'package:agendaifisiomobile/features/appointments/presentation/pages/appointments_page.dart';
import 'package:agendaifisiomobile/features/appointments/presentation/pages/patient_home_page.dart';

void main() {
  final nextAppointment = Appointment(
    id: 'appointment-1',
    professionalId: 'professional-1',
    professionalName: 'Dra. Marina Lopes',
    specialtyName: 'Fisioterapia esportiva',
    dateTime: DateTime.now().add(const Duration(days: 2)),
    status: AppointmentStatus.confirmed,
  );

  testWidgets('home mostra próxima consulta sem atalhos do paciente', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PatientHomePage(
          repository: _FakeRepository([nextAppointment]),
          patientName: 'Ana',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Olá, Ana!'), findsOneWidget);
    expect(find.text('Próximas consultas'), findsOneWidget);
    expect(find.text('Dra. Marina Lopes'), findsOneWidget);
    expect(find.text('Agendar consulta'), findsNothing);
    expect(find.text('Minha agenda'), findsNothing);
    expect(find.text('Histórico de consultas'), findsNothing);
  });

  testWidgets(
    'agenda distingue a lista e mostra detalhes ao selecionar um item',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppointmentsPage(
            repository: _FakeRepository([nextAppointment]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dra. Marina Lopes'), findsOneWidget);
      expect(find.text('Fisioterapia esportiva'), findsOneWidget);
      await tester.tap(find.text('Dra. Marina Lopes'));
      await tester.pumpAndSettle();

      expect(find.text('Detalhes'), findsOneWidget);
      expect(find.text('Sintomas'), findsNothing);
      expect(find.text('CREFITO'), findsOneWidget);
    },
  );

  testWidgets('paciente confirma e cancela o próprio agendamento', (
    tester,
  ) async {
    final item = Appointment(
      id: 'appointment-to-cancel',
      professionalId: 'professional-1',
      professionalName: 'Dra. Marina Lopes',
      specialtyName: 'Fisioterapia esportiva',
      dateTime: DateTime.now().add(const Duration(days: 2)),
      status: AppointmentStatus.confirmed,
    );
    final repository = _FakeRepository([item]);
    await tester.pumpWidget(
      MaterialApp(home: AppointmentsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dra. Marina Lopes'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Cancelar agendamento'), findsOneWidget);

    await tester.tap(find.text('Cancelar agendamento'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelar agendamento?'), findsOneWidget);
    expect(repository.cancelledIds, isEmpty);

    await tester.tap(find.text('Sim, cancelar'));
    await tester.pumpAndSettle();
    expect(repository.cancelledIds, ['appointment-to-cancel']);
    expect(find.text('Cancelado'), findsOneWidget);
    expect(find.text('Cancelar agendamento'), findsNothing);
    expect(find.text('Agendamento cancelado com sucesso.'), findsOneWidget);
  });

  testWidgets('terapeuta também visualiza a ação de cancelamento', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppointmentsPage(
          repository: _FakeRepository([nextAppointment]),
          professionalView: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dra. Marina Lopes'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Cancelar agendamento'), findsOneWidget);
  });

  testWidgets('home mostra vazio quando não há consultas futuras', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: PatientHomePage(repository: _FakeRepository(const []))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma consulta encontrada.'), findsOneWidget);
  });

  testWidgets('home ignora consulta futura cancelada', (tester) async {
    final cancelled = Appointment(
      id: 'cancelled',
      professionalId: 'professional-cancelled',
      professionalName: 'Profissional cancelado',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      status: AppointmentStatus.cancelled,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PatientHomePage(
          repository: _FakeRepository([cancelled, nextAppointment]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dra. Marina Lopes'), findsOneWidget);
    expect(find.text('Profissional cancelado'), findsNothing);
  });
}

class _FakeRepository implements AppointmentRepository {
  _FakeRepository(this.items);
  final List<Appointment> items;
  final List<String> cancelledIds = [];

  @override
  Future<List<Appointment>> fetchAppointments({
    AppointmentFilters filters = const AppointmentFilters(),
  }) async => filters.apply(items);

  @override
  Future<Appointment> fetchAppointment(String id) async =>
      items.firstWhere((item) => item.id == id);

  @override
  Future<Appointment> createAppointment({
    required String professionalId,
    required DateTime dateTime,
    String? observations,
  }) async => items.first;

  @override
  Future<Appointment> cancelAppointment(String id) async {
    final index = items.indexWhere((item) => item.id == id);
    final cancelled = items[index].copyWith(
      status: AppointmentStatus.cancelled,
    );
    items[index] = cancelled;
    cancelledIds.add(id);
    return cancelled;
  }

  @override
  Future<List<Professional>> fetchProfessionals({
    String? specialtyId,
    bool? active,
    int page = 1,
    int pageSize = 20,
  }) async => const [];

  @override
  Future<Professional> fetchProfessional(String id) async =>
      throw UnimplementedError();

  @override
  Future<List<Specialty>> fetchSpecialties() async => const [];
}

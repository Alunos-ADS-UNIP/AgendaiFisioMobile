import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:agendaifisiomobile/core/models/appointment_status.dart';
import 'package:agendaifisiomobile/features/appointments/domain/appointment.dart';
import 'package:agendaifisiomobile/features/appointments/domain/appointment_filters.dart';
import 'package:agendaifisiomobile/features/appointments/domain/appointment_repository.dart';
import 'package:agendaifisiomobile/features/appointments/domain/professional.dart';
import 'package:agendaifisiomobile/features/appointments/domain/specialty.dart';
import 'package:agendaifisiomobile/features/appointments/presentation/controllers/appointments_controller.dart';

void main() {
  final items = [
    _item(
      'one',
      DateTime(2026, 11, 12, 10),
      'pro-1',
      AppointmentStatus.confirmed,
    ),
    _item(
      'two',
      DateTime(2026, 11, 12, 11),
      'pro-2',
      AppointmentStatus.completed,
    ),
    _item(
      'three',
      DateTime(2026, 11, 13, 10),
      'pro-1',
      AppointmentStatus.confirmed,
    ),
  ];

  test('filtros de dia, profissional e status são combinados', () async {
    final repository = _FakeRepository(items);
    final controller = AppointmentsController(repository: repository);

    await controller.load(
      filters: AppointmentFilters(
        day: DateTime(2026, 11, 12),
        professionalId: 'pro-1',
        status: AppointmentStatus.confirmed,
      ),
    );

    expect(controller.items.map((item) => item.id), ['one']);
    expect(repository.lastFilters?.professionalId, 'pro-1');
  });

  test('paginação incremental separa páginas e pode voltar', () async {
    final controller = AppointmentsController(
      repository: _FakeRepository(items),
      pageSize: 2,
    );

    await controller.load();
    expect(controller.items.map((item) => item.id), ['one', 'two']);
    expect(controller.totalPages, 2);
    controller.goToPage(2);
    expect(controller.items.map((item) => item.id), ['three']);
    controller.goToPage(1);
    expect(controller.items.map((item) => item.id), ['one', 'two']);
  });

  test('resposta antiga de uma busca substituída é descartada', () async {
    final firstRequest = Completer<List<Appointment>>();
    var calls = 0;
    final repository = _FakeRepository(
      items,
      onFetch: () {
        calls++;
        return calls == 1 ? firstRequest.future : Future.value([items.last]);
      },
    );
    final controller = AppointmentsController(repository: repository);

    final first = controller.load();
    await controller.load(
      filters: const AppointmentFilters(status: AppointmentStatus.confirmed),
    );
    firstRequest.complete(items);
    await first;

    expect(controller.items.map((item) => item.id), ['three']);
  });
}

Appointment _item(
  String id,
  DateTime date,
  String professional,
  AppointmentStatus status,
) => Appointment(
  id: id,
  professionalId: professional,
  professionalName: 'Profissional $professional',
  dateTime: date,
  status: status,
);

class _FakeRepository implements AppointmentRepository {
  _FakeRepository(this.items, {this.onFetch});
  final List<Appointment> items;
  final Future<List<Appointment>> Function()? onFetch;
  AppointmentFilters? lastFilters;

  @override
  Future<List<Appointment>> fetchAppointments({
    AppointmentFilters filters = const AppointmentFilters(),
  }) {
    lastFilters = filters;
    return onFetch?.call() ?? Future.value(items);
  }

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

import '../core/models/appointment_status.dart';
import '../features/appointments/domain/appointment.dart';
import '../features/appointments/domain/appointment_failure.dart';
import '../features/appointments/domain/appointment_filters.dart';
import '../features/appointments/domain/appointment_repository.dart';
import '../features/appointments/domain/professional.dart';
import '../features/appointments/domain/specialty.dart';

/// Dados locais exclusivos da prévia visual; nenhuma chamada é feita à API.
class AppointmentPreviewRepository implements AppointmentRepository {
  AppointmentPreviewRepository() {
    final today = DateTime.now();
    _items.addAll([
      Appointment(
        id: 'preview-1',
        professionalId: 'marina',
        professionalName: 'Dra. Marina Lopes',
        specialtyName: 'Fisioterapia esportiva',
        dateTime: DateTime(today.year, today.month, today.day + 2, 14, 30),
        status: AppointmentStatus.confirmed,
        observations: 'Consulta de acompanhamento. Trazer exames anteriores.',
      ),
      Appointment(
        id: 'preview-2',
        professionalId: 'rafael',
        professionalName: 'Dr. Rafael Costa',
        specialtyName: 'Fisioterapia ortopédica',
        dateTime: DateTime(today.year, today.month, today.day + 5, 9),
        status: AppointmentStatus.scheduled,
      ),
    ]);
  }

  final List<Appointment> _items = [];
  static const _specialties = [
    Specialty(id: 'esportiva', name: 'Fisioterapia esportiva'),
    Specialty(id: 'ortopedica', name: 'Fisioterapia ortopédica'),
  ];
  static const _professionals = [
    Professional(
      id: 'marina',
      name: 'Dra. Marina Lopes',
      specialtyId: 'esportiva',
      specialtyName: 'Fisioterapia esportiva',
      crefito: 'CREFITO demonstrativo',
    ),
    Professional(
      id: 'rafael',
      name: 'Dr. Rafael Costa',
      specialtyId: 'ortopedica',
      specialtyName: 'Fisioterapia ortopédica',
      crefito: 'CREFITO demonstrativo',
    ),
  ];

  @override
  Future<List<Appointment>> fetchAppointments({
    AppointmentFilters filters = const AppointmentFilters(),
  }) async => filters.apply(_items);

  @override
  Future<Appointment> fetchAppointment(String id) async =>
      _items.firstWhere((item) => item.id == id);

  @override
  Future<Appointment> createAppointment({
    required String professionalId,
    required DateTime dateTime,
    String? observations,
  }) async {
    if (_items.any(
      (item) =>
          item.professionalId == professionalId &&
          item.dateTime.isAtSameMomentAs(dateTime),
    )) {
      throw const AppointmentException(AppointmentFailure.conflict);
    }
    final professional = await fetchProfessional(professionalId);
    final item = Appointment(
      id: 'preview-${DateTime.now().microsecondsSinceEpoch}',
      professionalId: professionalId,
      professionalName: professional.name,
      specialtyName: professional.specialtyName,
      dateTime: dateTime.toLocal(),
      status: AppointmentStatus.scheduled,
      observations: observations,
    );
    _items.add(item);
    _items.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return item;
  }

  @override
  Future<List<Professional>> fetchProfessionals({
    String? specialtyId,
    bool? active,
    int page = 1,
    int pageSize = 20,
  }) async => _professionals
      .where(
        (item) =>
            (specialtyId == null || item.specialtyId == specialtyId) &&
            (active == null || item.isActive == active),
      )
      .skip((page - 1) * pageSize)
      .take(pageSize)
      .toList();

  @override
  Future<Professional> fetchProfessional(String id) async =>
      _professionals.firstWhere((item) => item.id == id);

  @override
  Future<List<Specialty>> fetchSpecialties() async => _specialties;
}

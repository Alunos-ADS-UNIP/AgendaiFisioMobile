import 'appointment.dart';
import 'appointment_filters.dart';
import 'professional.dart';
import 'specialty.dart';

abstract interface class AppointmentRepository {
  Future<List<Appointment>> fetchAppointments({AppointmentFilters filters});
  Future<Appointment> fetchAppointment(String id);
  Future<Appointment> createAppointment({
    required String professionalId,
    required DateTime dateTime,
    String? observations,
  });
  Future<List<Professional>> fetchProfessionals({
    String? specialtyId,
    bool? active,
    int page = 1,
    int pageSize = 20,
  });
  Future<Professional> fetchProfessional(String id);
  Future<List<Specialty>> fetchSpecialties();
}

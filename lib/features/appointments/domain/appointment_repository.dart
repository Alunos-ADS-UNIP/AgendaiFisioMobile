import 'appointment.dart';
import 'appointment_filters.dart';
import 'professional.dart';
import 'specialty.dart';

/// Implementado por repositórios que conseguem conferir o cadastro do paciente
/// logado. Devolve os nomes dos campos obrigatórios que ainda faltam; lista
/// vazia significa cadastro completo.
abstract interface class PatientProfileChecker {
  Future<List<String>> missingPatientProfileFields();
}

/// Implementado por repositórios que conseguem ler o e-mail de contato de um
/// fisioterapeuta (a lista de profissionais não traz esse dado).
abstract interface class ProfessionalContactDirectory {
  Future<String> fetchProfessionalEmail(String professionalId);
}

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

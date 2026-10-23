import '../../../core/models/appointment_status.dart';

class Appointment {
  const Appointment({
    required this.id,
    required this.professionalId,
    required this.professionalName,
    required this.dateTime,
    required this.status,
    this.specialtyName = '',
    this.observations,
    this.patientName = '',
  });

  final String id;
  final String professionalId;
  final String professionalName;

  /// Always represented in the device's local timezone in the UI layer.
  final DateTime dateTime;
  final AppointmentStatus status;
  final String specialtyName;
  final String? observations;

  /// Nome do paciente (pacienteNome da API). Vazio quando a API não envia.
  final String patientName;
}

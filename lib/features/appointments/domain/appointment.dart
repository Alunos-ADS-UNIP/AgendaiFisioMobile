import '../../../core/models/appointment_status.dart';

/// Dados de contato e de cadastro de uma das partes da consulta.
class ContactInfo {
  const ContactInfo({
    this.email = '',
    this.cidade = '',
    this.estado = '',
    this.dataNascimento,
  });

  final String email;
  final String cidade;
  final String estado;
  final DateTime? dataNascimento;

  /// Idade completa em [now]; null quando a data de nascimento não foi enviada.
  int? ageOn(DateTime now) {
    final birth = dataNascimento;
    if (birth == null) return null;
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }
}

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
    this.patientId = '',
    this.patientInfo = const ContactInfo(),
    this.professionalInfo = const ContactInfo(),
    this.professionalCrefito = '',
    this.professionalBio = '',
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

  /// Id do paciente (pacienteId da API), usado para buscar o cadastro dele.
  final String patientId;

  /// Contato e cadastro do paciente. Só vêm preenchidos no detalhe.
  final ContactInfo patientInfo;

  /// Contato e cadastro do fisioterapeuta. Só vêm preenchidos no detalhe.
  final ContactInfo professionalInfo;
  final String professionalCrefito;
  final String professionalBio;

  Appointment copyWith({
    String? professionalName,
    String? specialtyName,
    ContactInfo? patientInfo,
    ContactInfo? professionalInfo,
    String? professionalCrefito,
    String? professionalBio,
  }) => Appointment(
    id: id,
    professionalId: professionalId,
    professionalName: professionalName ?? this.professionalName,
    dateTime: dateTime,
    status: status,
    specialtyName: specialtyName ?? this.specialtyName,
    observations: observations,
    patientName: patientName,
    patientId: patientId,
    patientInfo: patientInfo ?? this.patientInfo,
    professionalInfo: professionalInfo ?? this.professionalInfo,
    professionalCrefito: professionalCrefito ?? this.professionalCrefito,
    professionalBio: professionalBio ?? this.professionalBio,
  );
}

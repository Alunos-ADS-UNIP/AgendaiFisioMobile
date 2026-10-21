import '../../domain/professional_profile.dart';

class ProfessionalRegisterRequest {
  const ProfessionalRegisterRequest({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'senha': password,
    'tipoUsuario': 'Profissional',
  };
}

/// Contrato de ProfissionalUpdateDTO. `ativo` preserva o valor consultado no
/// detalhe público; especialidade tem uma rota separada e não entra aqui.
class ProfessionalUpdateRequest {
  const ProfessionalUpdateRequest({
    required this.name,
    required this.cpf,
    required this.crefito,
    required this.phone,
    required this.birthDate,
    required this.bio,
    required this.isActive,
  });

  final String name;
  final String cpf;
  final String crefito;
  final String phone;
  final DateTime birthDate;
  final String bio;
  final bool isActive;

  Map<String, dynamic> toJson() => {
    'nomeCompleto': name.trim(),
    'cpf': cpf.replaceAll(RegExp(r'\D'), ''),
    'crefito': crefito.trim(),
    'telefone': phone.replaceAll(RegExp(r'\D'), ''),
    'dataNascimento':
        '${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
    'bio': bio.trim(),
    'ativo': isActive,
  };
}

class AuthenticatedProfessionalDto {
  const AuthenticatedProfessionalDto({
    required this.profileId,
    required this.email,
  });

  factory AuthenticatedProfessionalDto.fromJson(Map<String, dynamic> json) {
    if (json['tipoUsuario']?.toString().toLowerCase() != 'profissional' ||
        (json['perfilId']?.toString().isNotEmpty ?? false) == false) {
      throw const ProfessionalAccessException();
    }
    return AuthenticatedProfessionalDto(
      profileId: json['perfilId'].toString(),
      email: json['email']?.toString() ?? '',
    );
  }

  final String profileId;
  final String email;
}

class ProfessionalAccessException implements Exception {
  const ProfessionalAccessException();
}

ProfessionalProfile professionalProfileFromJson(
  String expectedId,
  String sessionEmail,
  Map<String, dynamic> json,
) {
  if (json['id']?.toString().toLowerCase() != expectedId.toLowerCase() ||
      json['ativo'] is! bool) {
    throw const FormatException('Detalhe profissional inválido.');
  }
  final specialty = json['especialidade'];
  final specialtyName = specialty is Map
      ? specialty['nome']?.toString() ?? ''
      : '';
  return ProfessionalProfile(
    id: expectedId,
    name: json['nomeCompleto']?.toString() ?? '',
    email: sessionEmail,
    crefito: json['crefito']?.toString() ?? '',
    phone: json['telefone']?.toString() ?? '',
    bio: json['bio']?.toString() ?? '',
    specialtyName: specialtyName,
    isActive: json['ativo'] == true,
  );
}

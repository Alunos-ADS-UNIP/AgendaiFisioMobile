/// Dados que a API permite consultar sobre o perfil do profissional logado.
/// CPF e nascimento não são devolvidos pelo detalhe público.
class ProfessionalProfile {
  const ProfessionalProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.crefito,
    required this.phone,
    required this.bio,
    required this.specialtyName,
    required this.isActive,
  });

  final String id;
  final String name;
  final String email;
  final String crefito;
  final String phone;
  final String bio;
  final String specialtyName;
  final bool isActive;

  bool get isPendingCompletion => name.trim() == 'Cadastro Pendente';

  ProfessionalProfile copyWith({
    String? name,
    String? crefito,
    String? phone,
    String? bio,
  }) => ProfessionalProfile(
    id: id,
    name: name ?? this.name,
    email: email,
    crefito: crefito ?? this.crefito,
    phone: phone ?? this.phone,
    bio: bio ?? this.bio,
    specialtyName: specialtyName,
    isActive: isActive,
  );
}

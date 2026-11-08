import '../../../core/domain/professional_address.dart';

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
    this.photoUrl,
    this.specialtyId,
    required this.specialtyName,
    required this.isActive,
    this.address,
  });

  final String id;
  final String name;
  final String email;
  final String crefito;
  final String phone;
  final String bio;
  final String? photoUrl;
  final String? specialtyId;
  final String specialtyName;
  final bool isActive;
  final ProfessionalAddress? address;

  bool get isPendingCompletion =>
      name.trim() == 'Cadastro Pendente' || address?.isComplete != true;

  ProfessionalProfile copyWith({
    String? name,
    String? crefito,
    String? phone,
    String? bio,
    String? specialtyId,
    String? specialtyName,
    ProfessionalAddress? address,
  }) => ProfessionalProfile(
    id: id,
    name: name ?? this.name,
    email: email,
    crefito: crefito ?? this.crefito,
    phone: phone ?? this.phone,
    bio: bio ?? this.bio,
    specialtyId: specialtyId ?? this.specialtyId,
    specialtyName: specialtyName ?? this.specialtyName,
    photoUrl: photoUrl,
    isActive: isActive,
    address: address ?? this.address,
  );

  ProfessionalProfile withPhotoUrl(String? value) => ProfessionalProfile(
    id: id,
    name: name,
    email: email,
    crefito: crefito,
    phone: phone,
    bio: bio,
    photoUrl: value,
    specialtyId: specialtyId,
    specialtyName: specialtyName,
    isActive: isActive,
    address: address,
  );
}

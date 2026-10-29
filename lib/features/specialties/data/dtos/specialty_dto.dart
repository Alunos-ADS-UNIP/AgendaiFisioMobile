import '../../domain/entities/specialty.dart';

class SpecialtyDto {
  const SpecialtyDto({required this.id, required this.name});

  final String id;
  final String name;

  factory SpecialtyDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['nome'];
    if (id is! String || name is! String) {
      throw const FormatException('Resposta de especialidade inválida.');
    }
    return SpecialtyDto(id: id, name: name);
  }

  Specialty toEntity() => Specialty(id: id, name: name);
}

class SpecialtyCreateDto {
  const SpecialtyCreateDto(this.name);

  final String name;

  Map<String, dynamic> toJson() => {'nome': name};
}

class ProfessionalSpecialtyUpdateDto {
  const ProfessionalSpecialtyUpdateDto(this.specialtyId);

  final String specialtyId;

  Map<String, dynamic> toJson() => {'especialidadeId': specialtyId};
}

import 'package:flutter_test/flutter_test.dart';

import 'package:agendaifisiomobile/features/specialties/data/dtos/specialty_dto.dart';

void main() {
  test('desserializa especialidade preservando GUID e acentos', () {
    final dto = SpecialtyDto.fromJson({
      'id': '00000000-0000-0000-0000-000000000015',
      'nome': 'Aquática',
    });

    expect(dto.id, '00000000-0000-0000-0000-000000000015');
    expect(dto.toEntity().name, 'Aquática');
  });

  test('serializa vínculo usando somente especialidadeId', () {
    final json = const ProfessionalSpecialtyUpdateDto('guid').toJson();

    expect(json, {'especialidadeId': 'guid'});
    expect(json.containsKey('profissionalId'), isFalse);
    expect(json.containsKey('usuarioId'), isFalse);
  });

  test('serializa criação com nome', () {
    expect(const SpecialtyCreateDto('Fisioterapia Esportiva').toJson(), {
      'nome': 'Fisioterapia Esportiva',
    });
  });
}

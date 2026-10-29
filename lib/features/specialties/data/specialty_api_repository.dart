import 'dart:async';

import '../domain/entities/specialty.dart';
import '../domain/repositories/specialty_repository.dart';
import '../domain/specialty_failure.dart';
import '../domain/specialty_name_normalizer.dart';
import 'dtos/specialty_dto.dart';
import 'specialty_api_client.dart';

class SpecialtyApiRepository implements SpecialtyRepository {
  const SpecialtyApiRepository(this._client);

  static const catalogPath = '/api/especialidade';
  static const professionalSpecialtyPath = '/api/profissional/especialidade';

  final SpecialtyHttpClient _client;

  @override
  Future<List<Specialty>> list() async {
    final response = await _request(
      () => _client.get(catalogPath, authenticated: false),
    );
    _requireStatus(response, expected: const {200});
    final body = response.body;
    if (body is! List<dynamic>) {
      throw const SpecialtyException(
        SpecialtyFailure.invalidResponse,
        'A resposta do catálogo é inválida.',
      );
    }

    final unique = <String, Specialty>{};
    final seenIds = <String>{};
    final seenNames = <String>{};
    for (final item in body) {
      if (item is! Map<String, dynamic>) {
        throw const SpecialtyException(
          SpecialtyFailure.invalidResponse,
          'A resposta do catálogo é inválida.',
        );
      }
      final specialty = SpecialtyDto.fromJson(item).toEntity();
      final key = normalizeSpecialtyName(specialty.name);
      if (seenIds.add(specialty.id) && seenNames.add(key)) {
        unique[specialty.id] = specialty;
      }
    }
    return unique.values.toList(growable: false);
  }

  @override
  Future<Specialty> getById(String id) async {
    final response = await _request(
      () => _client.get(
        '$catalogPath/${Uri.encodeComponent(id)}',
        authenticated: false,
      ),
    );
    _requireStatus(response, expected: const {200});
    final body = response.body;
    if (body is! Map<String, dynamic>) {
      throw const SpecialtyException(
        SpecialtyFailure.invalidResponse,
        'A resposta da especialidade é inválida.',
      );
    }
    try {
      return SpecialtyDto.fromJson(body).toEntity();
    } on FormatException {
      throw const SpecialtyException(
        SpecialtyFailure.invalidResponse,
        'A resposta da especialidade é inválida.',
      );
    }
  }

  @override
  Future<Specialty> create(String name) async {
    final response = await _request(
      () => _client.post(
        catalogPath,
        SpecialtyCreateDto(name).toJson(),
        authenticated: true,
      ),
    );
    _requireStatus(response, expected: const {201});
    final body = response.body;
    if (body is! Map<String, dynamic>) {
      throw const SpecialtyException(
        SpecialtyFailure.invalidResponse,
        'A resposta da criação é inválida.',
      );
    }
    try {
      return SpecialtyDto.fromJson(body).toEntity();
    } on FormatException {
      throw const SpecialtyException(
        SpecialtyFailure.invalidResponse,
        'A resposta da criação é inválida.',
      );
    }
  }

  @override
  Future<void> updateProfessionalSpecialty(String specialtyId) async {
    final response = await _request(
      () => _client.put(
        professionalSpecialtyPath,
        ProfessionalSpecialtyUpdateDto(specialtyId).toJson(),
        authenticated: true,
      ),
    );
    _requireStatus(response, expected: const {200, 204});
  }

  Future<SpecialtyHttpResponse> _request(
    Future<SpecialtyHttpResponse> Function() request,
  ) async {
    try {
      return await request();
    } on SpecialtyException {
      rethrow;
    } on TimeoutException {
      throw const SpecialtyException(
        SpecialtyFailure.network,
        'A conexão demorou demais. Tente novamente.',
      );
    } catch (_) {
      throw const SpecialtyException(
        SpecialtyFailure.network,
        'Não foi possível conectar ao servidor.',
      );
    }
  }

  void _requireStatus(
    SpecialtyHttpResponse response, {
    required Set<int> expected,
  }) {
    if (expected.contains(response.statusCode)) return;
    throw SpecialtyException(
      _failureForStatus(response.statusCode),
      _messageForStatus(response.statusCode),
    );
  }

  SpecialtyFailure _failureForStatus(int statusCode) => switch (statusCode) {
    400 => SpecialtyFailure.badRequest,
    401 => SpecialtyFailure.unauthorized,
    403 => SpecialtyFailure.forbidden,
    404 => SpecialtyFailure.notFound,
    409 => SpecialtyFailure.conflict,
    _ => SpecialtyFailure.unexpected,
  };

  String _messageForStatus(int statusCode) => switch (statusCode) {
    400 => 'Requisição inválida.',
    401 => 'Sua sessão expirou. Entre novamente.',
    403 => 'Você não tem permissão para realizar esta ação.',
    404 => 'Especialidade não encontrada.',
    409 => 'Conflito: esta especialidade já existe.',
    _ => 'O servidor não conseguiu concluir a operação.',
  };
}

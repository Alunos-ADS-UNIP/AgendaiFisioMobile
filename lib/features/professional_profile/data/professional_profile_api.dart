import '../../../core/network/api_client.dart';
import '../domain/professional_profile.dart';
import 'dtos/professional_profile_dtos.dart';

/// Usa /auth/me para obter o perfilId confiável da sessão. O detalhe por ID
/// fornece apenas os campos públicos; CPF e nascimento vêm só de
/// /api/profissional/me, que responde apenas ao próprio profissional.
class ProfessionalProfileApi {
  const ProfessionalProfileApi(this._client);

  final ApiClient _client;

  Future<ProfessionalProfile> fetchOwnProfile() async {
    final session = await _readProfessionalSession();
    final detail = await _client.get(
      '/api/profissional/${Uri.encodeComponent(session.profileId)}',
    );
    return professionalProfileFromJson(
      session.profileId,
      session.email,
      detail,
    );
  }

  /// CPF (só dígitos) e data de nascimento do próprio profissional logado.
  /// Devolve null se o servidor não tiver a rota ou não responder.
  Future<({String cpf, DateTime? birthDate})?> fetchOwnPrivateData() async {
    try {
      final json = await _client.get('/api/profissional/me');
      final cpf = (json['cpf'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
      final birthDate = DateTime.tryParse(
        (json['dataNascimento'] ?? '').toString(),
      );
      return (cpf: cpf, birthDate: birthDate);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateOwnProfile(ProfessionalUpdateRequest request) async {
    await _readProfessionalSession();
    await _client.put('/api/profissional/completar-perfil', request.toJson());
  }

  Future<String> updateOwnPhoto({
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) async {
    final json = await _client.putMultipart(
      '/api/profissional/me/foto',
      fieldName: 'arquivo',
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
    final url = json['fotoPerfilUrl']?.toString().trim() ?? '';
    if (url.isEmpty) {
      throw const FormatException('A API não devolveu a URL da foto.');
    }
    return url;
  }

  Future<void> removeOwnPhoto() => _client.delete('/api/profissional/me/foto');

  /// Escolhe ou troca a especialidade do profissional logado.
  /// PUT /api/profissional/especialidade com {"especialidadeId": "..."}.
  Future<void> updateOwnSpecialty(String specialtyId) async {
    await _client.put('/api/profissional/especialidade', {
      'especialidadeId': specialtyId,
    });
  }

  Future<void> register(ProfessionalRegisterRequest request) async {
    await _client.post(
      '/api/auth/register',
      request.toJson(),
      authenticated: false,
    );
  }

  Future<AuthenticatedProfessionalDto> _readProfessionalSession() async {
    final json = await _client.get('/api/auth/me');
    return AuthenticatedProfessionalDto.fromJson(json);
  }
}

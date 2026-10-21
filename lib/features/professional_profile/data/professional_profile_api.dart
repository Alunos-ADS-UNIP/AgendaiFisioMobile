import '../../../core/network/api_client.dart';
import '../domain/professional_profile.dart';
import 'dtos/professional_profile_dtos.dart';

/// Usa /auth/me para obter o perfilId confiável da sessão. O detalhe por ID
/// fornece apenas os campos públicos; nunca é fonte de CPF ou nascimento.
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

  Future<void> updateOwnProfile(ProfessionalUpdateRequest request) async {
    await _readProfessionalSession();
    await _client.put('/api/profissional/completar-perfil', request.toJson());
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

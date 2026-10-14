import '../../../core/network/api_client.dart';
import 'dtos/patient_dtos.dart';

/// Chamadas HTTP da feature de paciente. Nenhuma tela chama [ApiClient]
/// diretamente — tudo passa por aqui.
class PatientApi {
  const PatientApi(this._client);

  final ApiClient _client;

  /// POST /api/auth/register com tipoUsuario "Paciente".
  /// Não autenticado — é assim que uma conta nasce.
  Future<void> register(PatientRegisterRequest request) {
    return _client.post('/api/auth/register', request.toJson(), authenticated: false);
  }

  /// GET /api/paciente/me — perfil do paciente logado.
  Future<PatientProfileResponse> getMe() async {
    final json = await _client.get('/api/paciente/me');
    return PatientProfileResponse.fromJson(json);
  }

  /// PUT /api/paciente/completar-perfil — cria ou corrige os dados do
  /// próprio paciente logado. Nunca envia pacienteId: o backend identifica
  /// o paciente pelo usuarioId do token.
  Future<void> completarPerfil(PatientUpdateRequest request) {
    return _client.put('/api/paciente/completar-perfil', request.toJson());
  }
}

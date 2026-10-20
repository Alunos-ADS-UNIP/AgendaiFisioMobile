import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/patient_api.dart';
import '../../domain/patient.dart';

enum PatientProfileStatus { loading, content, error }

/// Controller da tela de visualização do perfil (`patient_profile_page.dart`).
/// Só lida com o GET /api/paciente/me e os três estados principais da tela.
class PatientProfileController extends ChangeNotifier {
  PatientProfileController(this._api);

  final PatientApi _api;

  PatientProfileStatus _status = PatientProfileStatus.loading;
  PatientProfileStatus get status => _status;

  Patient? _patient;
  Patient? get patient => _patient;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isSessionExpired => _sessionExpired;
  bool _sessionExpired = false;

  Future<void> load() async {
    _status = PatientProfileStatus.loading;
    _sessionExpired = false;
    notifyListeners();

    try {
      final response = await _api.getMe();
      _patient = response.toDomain();
      _status = PatientProfileStatus.content;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _sessionExpired = e.isUnauthorized;
      _status = PatientProfileStatus.error;
    } catch (_) {
      _errorMessage =
          'Não foi possível conectar ao servidor. Verifique sua conexão.';
      _status = PatientProfileStatus.error;
    }

    notifyListeners();
  }
}

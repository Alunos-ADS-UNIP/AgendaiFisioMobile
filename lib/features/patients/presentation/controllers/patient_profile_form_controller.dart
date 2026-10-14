import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/dtos/patient_dtos.dart';
import '../../data/patient_api.dart';

/// Controller do formulário de edição/completar perfil
/// (`patient_profile_form_page.dart`). Guarda o estado de envio e os erros
/// de campo que vieram da API, para exibir embaixo de cada [AppTextField].
class PatientProfileFormController extends ChangeNotifier {
  PatientProfileFormController(this._api);

  final PatientApi _api;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  Map<String, String> _fieldErrors = {};
  Map<String, String> get fieldErrors => _fieldErrors;

  String? _generalError;
  String? get generalError => _generalError;

  /// Retorna true em caso de sucesso, para a página decidir a navegação.
  Future<bool> submit(PatientUpdateRequest request) async {
    _isSubmitting = true;
    _fieldErrors = {};
    _generalError = null;
    notifyListeners();

    try {
      await _api.completarPerfil(request);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isSubmitting = false;
      if (e.isValidation) {
        _fieldErrors = e.fieldErrors!;
      } else {
        _generalError = e.message;
      }
      notifyListeners();
      return false;
    } catch (_) {
      _isSubmitting = false;
      _generalError = 'Não foi possível conectar ao servidor. Verifique sua conexão.';
      notifyListeners();
      return false;
    }
  }

  /// Mensagem de erro de um campo específico, pelo nome usado no
  /// [PatientUpdateRequest.toJson] (ex: "nomeCompleto", "cpf"). O ASP.NET
  /// costuma devolver a chave capitalizada (ex: "NomeCompleto"), então
  /// conferimos as duas formas.
  String? errorFor(String field) {
    return _fieldErrors[field] ??
        _fieldErrors[field[0].toUpperCase() + field.substring(1)];
  }
}

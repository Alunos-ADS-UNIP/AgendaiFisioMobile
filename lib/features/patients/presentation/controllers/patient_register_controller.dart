import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/dtos/patient_dtos.dart';
import '../../data/patient_api.dart';

/// Controller da tela de cadastro (`patient_register_page.dart`).
class PatientRegisterController extends ChangeNotifier {
  PatientRegisterController(this._api);

  final PatientApi _api;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _generalError;
  String? get generalError => _generalError;

  /// true quando o backend recusou por e-mail já cadastrado — permite
  /// mostrar uma mensagem/ação diferente ("já tem conta? entrar") em vez de
  /// um erro genérico.
  bool _emailJaCadastrado = false;
  bool get emailJaCadastrado => _emailJaCadastrado;

  Future<bool> submit({required String email, required String senha}) async {
    _isSubmitting = true;
    _generalError = null;
    _emailJaCadastrado = false;
    notifyListeners();

    try {
      await _api.register(PatientRegisterRequest(email: email, senha: senha));
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isSubmitting = false;
      _emailJaCadastrado = e.message.toLowerCase().contains('e-mail');
      _generalError = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _isSubmitting = false;
      _generalError =
          'Não foi possível conectar ao servidor. Verifique sua conexão.';
      notifyListeners();
      return false;
    }
  }
}

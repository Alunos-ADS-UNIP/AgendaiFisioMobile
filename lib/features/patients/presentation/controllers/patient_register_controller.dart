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

  Map<String, String> _fieldErrors = const {};
  Map<String, String> get fieldErrors => Map.unmodifiable(_fieldErrors);
  String? fieldError(String field) => _fieldErrors[field];

  /// true quando o backend recusou por e-mail já cadastrado — permite
  /// mostrar uma mensagem/ação diferente ("já tem conta? entrar") em vez de
  /// um erro genérico.
  bool _emailJaCadastrado = false;
  bool get emailJaCadastrado => _emailJaCadastrado;

  Future<bool> submit({
    required String email,
    required String senha,
    required bool aceiteLgpd,
    required DateTime dataNascimento,
    required bool consentimentoResponsavelLegal,
    String? nomeResponsavelLegal,
  }) async {
    _isSubmitting = true;
    _generalError = null;
    _fieldErrors = const {};
    _emailJaCadastrado = false;
    notifyListeners();

    try {
      await _api.register(
        PatientRegisterRequest(
          email: email,
          senha: senha,
          aceiteLgpd: aceiteLgpd,
          dataNascimento: dataNascimento,
          consentimentoResponsavelLegal: consentimentoResponsavelLegal,
          nomeResponsavelLegal: nomeResponsavelLegal,
        ),
      );
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isSubmitting = false;
      final emailDetail = e.fieldErrors?.entries
          .where((entry) => entry.key.split('.').last.toLowerCase() == 'email')
          .map((entry) => entry.value)
          .join(' ');
      final lowerMessage = '${e.message} ${emailDetail ?? ''}'.toLowerCase();
      _emailJaCadastrado =
          (e.statusCode == 409 ||
              lowerMessage.contains('já cadastrad') ||
              lowerMessage.contains('em uso')) &&
          (lowerMessage.contains('e-mail') || lowerMessage.contains('email'));
      _fieldErrors = _registrationFieldErrors(e);
      _generalError = _fieldErrors.isEmpty
          ? e.message
          : 'Revise os campos destacados abaixo e tente novamente.';
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

  void clearFieldError(String field) {
    if (field == 'email') _emailJaCadastrado = false;
    if (!_fieldErrors.containsKey(field)) return;
    _fieldErrors = Map.of(_fieldErrors)..remove(field);
    if (_fieldErrors.isEmpty &&
        _generalError ==
            'Revise os campos destacados abaixo e tente novamente.') {
      _generalError = null;
    }
    notifyListeners();
  }

  Map<String, String> _registrationFieldErrors(ApiException exception) {
    final result = <String, String>{};
    final aliases = <String, String>{
      'email': 'email',
      'senha': 'senha',
      'password': 'senha',
      'datanascimento': 'dataNascimento',
      'nomeresponsavellegal': 'nomeResponsavelLegal',
      'consentimentoresponsavellegal': 'consentimentoResponsavelLegal',
      'aceitelgpd': 'aceiteLgpd',
    };

    exception.fieldErrors?.forEach((key, value) {
      final normalized = key.split('.').last.toLowerCase();
      final field = aliases[normalized];
      if (field != null) result[field] = value;
    });

    if (result.isNotEmpty) return result;

    final message = exception.message;
    final lower = message.toLowerCase();
    if (lower.contains('e-mail') || lower.contains('email')) {
      result['email'] = message;
    } else if (lower.contains('senha')) {
      result['senha'] = message;
    } else if (lower.contains('data de nascimento')) {
      result['dataNascimento'] = message;
    } else if (lower.contains('responsável legal') ||
        lower.contains('responsavel legal')) {
      result['nomeResponsavelLegal'] = message;
      result['consentimentoResponsavelLegal'] =
          'Confirme a autorização do responsável legal.';
    } else if (lower.contains('termos') || lower.contains('lgpd')) {
      result['aceiteLgpd'] = message;
    }

    return result;
  }
}

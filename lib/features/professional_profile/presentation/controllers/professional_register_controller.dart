import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/dtos/professional_profile_dtos.dart';
import '../../data/professional_profile_api.dart';

class ProfessionalRegisterController extends ChangeNotifier {
  ProfessionalRegisterController(this._api);

  final ProfessionalProfileApi _api;
  bool _isSubmitting = false;
  String? _error;
  bool _disposed = false;

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  Map<String, String> _fieldErrors = const {};
  Map<String, String> get fieldErrors => Map.unmodifiable(_fieldErrors);
  String? fieldError(String field) => _fieldErrors[field];

  Future<bool> submit({
    required String email,
    required String password,
    required bool aceiteLgpd,
  }) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _error = null;
    _fieldErrors = const {};
    notifyListeners();
    try {
      await _api.register(
        ProfessionalRegisterRequest(
          email: email,
          password: password,
          aceiteLgpd: aceiteLgpd,
        ),
      );
      return !_disposed;
    } on ApiException catch (error) {
      if (!_disposed) {
        _fieldErrors = _registrationFieldErrors(error);
        _error = _fieldErrors.isEmpty
            ? error.message
            : 'Revise os campos destacados abaixo e tente novamente.';
      }
      return false;
    } catch (_) {
      if (!_disposed) {
        _error = 'Não foi possível criar a conta. Confira sua conexão.';
      }
      return false;
    } finally {
      _isSubmitting = false;
      if (!_disposed) notifyListeners();
    }
  }

  void clearFieldError(String field) {
    if (!_fieldErrors.containsKey(field)) return;
    _fieldErrors = Map.of(_fieldErrors)..remove(field);
    if (_fieldErrors.isEmpty &&
        _error == 'Revise os campos destacados abaixo e tente novamente.') {
      _error = null;
    }
    if (!_disposed) notifyListeners();
  }

  Map<String, String> _registrationFieldErrors(ApiException exception) {
    final result = <String, String>{};
    final aliases = <String, String>{
      'email': 'email',
      'senha': 'senha',
      'password': 'senha',
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
    } else if (lower.contains('termos') || lower.contains('lgpd')) {
      result['aceiteLgpd'] = message;
    }
    return result;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

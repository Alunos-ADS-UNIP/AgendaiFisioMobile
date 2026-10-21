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

  Future<bool> submit({required String email, required String password}) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await _api.register(
        ProfessionalRegisterRequest(email: email, password: password),
      );
      return !_disposed;
    } on ApiException catch (error) {
      if (!_disposed) _error = error.message;
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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

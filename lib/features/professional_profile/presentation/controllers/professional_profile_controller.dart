import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/dtos/professional_profile_dtos.dart';
import '../../data/professional_profile_api.dart';
import '../../domain/professional_profile.dart';

enum ProfessionalProfileStatus { loading, content, forbidden, error }

/// Mantém dados privados enviados apenas durante a sessão atual. Como não há
/// GET /api/profissional/me privado, CPF e nascimento nunca são inventados a
/// partir do detalhe público.
class ProfessionalProfileController extends ChangeNotifier {
  ProfessionalProfileController(this._api);

  final ProfessionalProfileApi _api;
  ProfessionalProfileStatus _status = ProfessionalProfileStatus.loading;
  ProfessionalProfile? _profile;
  String? _cpfInSession;
  DateTime? _birthDateInSession;
  String? _loadError;
  String? _submitError;
  Map<String, String> _fieldErrors = {};
  bool _isSubmitting = false;
  bool _sessionExpired = false;
  int _generation = 0;

  ProfessionalProfileStatus get status => _status;
  ProfessionalProfile? get profile => _profile;
  String? get cpfInSession => _cpfInSession;
  DateTime? get birthDateInSession => _birthDateInSession;
  String? get loadError => _loadError;
  String? get submitError => _submitError;
  bool get isSubmitting => _isSubmitting;
  bool get isSessionExpired => _sessionExpired;
  bool get canEdit =>
      _status == ProfessionalProfileStatus.content && _profile != null;

  String? errorFor(String field) {
    final wanted = field.toLowerCase();
    for (final entry in _fieldErrors.entries) {
      if (entry.key.toLowerCase() == wanted) return entry.value;
    }
    return null;
  }

  Future<void> load() async {
    final generation = ++_generation;
    _status = ProfessionalProfileStatus.loading;
    _loadError = null;
    _sessionExpired = false;
    notifyListeners();
    try {
      final loaded = await _api.fetchOwnProfile();
      if (generation != _generation) return;
      if (_profile?.id != loaded.id) {
        _cpfInSession = null;
        _birthDateInSession = null;
      }
      _profile = loaded;
      _status = ProfessionalProfileStatus.content;
    } on ProfessionalAccessException {
      if (generation != _generation) return;
      _profile = null;
      _cpfInSession = null;
      _birthDateInSession = null;
      _status = ProfessionalProfileStatus.forbidden;
    } on ApiException catch (error) {
      if (generation != _generation) return;
      _profile = null;
      _sessionExpired = error.isUnauthorized;
      if (error.isUnauthorized) {
        _cpfInSession = null;
        _birthDateInSession = null;
      }
      _loadError = error.message;
      _status = ProfessionalProfileStatus.error;
    } catch (_) {
      if (generation != _generation) return;
      _profile = null;
      _loadError = 'Não foi possível carregar o perfil. Confira sua conexão.';
      _status = ProfessionalProfileStatus.error;
    }
    if (generation == _generation) notifyListeners();
  }

  Future<bool> submit(ProfessionalUpdateRequest request) async {
    if (!canEdit || _isSubmitting) return false;
    final generation = _generation;
    final current = _profile!;
    _isSubmitting = true;
    _submitError = null;
    _fieldErrors = {};
    notifyListeners();
    try {
      // O valor de ativo vem do GET da sessão atual, nunca do formulário.
      final safeRequest = ProfessionalUpdateRequest(
        name: request.name,
        cpf: request.cpf,
        crefito: request.crefito,
        phone: request.phone,
        birthDate: request.birthDate,
        bio: request.bio,
        isActive: current.isActive,
      );
      await _api.updateOwnProfile(safeRequest);
      if (generation != _generation || _profile?.id != current.id) return false;
      _profile = current.copyWith(
        name: safeRequest.name.trim(),
        crefito: safeRequest.crefito.trim(),
        phone: safeRequest.phone.replaceAll(RegExp(r'\D'), ''),
        bio: safeRequest.bio.trim(),
      );
      _cpfInSession = safeRequest.cpf.replaceAll(RegExp(r'\D'), '');
      _birthDateInSession = safeRequest.birthDate;
      return true;
    } on ProfessionalAccessException {
      if (generation != _generation) return false;
      _profile = null;
      _cpfInSession = null;
      _birthDateInSession = null;
      _status = ProfessionalProfileStatus.forbidden;
      _submitError = 'Esta área é exclusiva para profissionais.';
      return false;
    } on ApiException catch (error) {
      if (generation != _generation) return false;
      _sessionExpired = error.isUnauthorized;
      if (error.isUnauthorized) {
        _profile = null;
        _cpfInSession = null;
        _birthDateInSession = null;
        _status = ProfessionalProfileStatus.error;
      }
      if (error.isConflict) {
        _fieldErrors = {'crefito': error.message};
      } else if (error.isValidation) {
        _fieldErrors = error.fieldErrors!;
      } else {
        _submitError = error.message;
      }
      return false;
    } catch (_) {
      if (generation != _generation) return false;
      _submitError =
          'Não foi possível salvar. Confira sua conexão e tente novamente.';
      return false;
    } finally {
      _isSubmitting = false;
      if (generation == _generation) notifyListeners();
    }
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}

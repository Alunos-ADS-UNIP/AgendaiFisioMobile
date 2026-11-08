import 'package:flutter/foundation.dart';

import '../../../../core/domain/professional_address.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/dtos/professional_profile_dtos.dart';
import '../../data/professional_profile_api.dart';
import '../../domain/professional_profile.dart';

enum ProfessionalProfileStatus { loading, content, forbidden, error }

/// CPF e nascimento vêm de GET /api/profissional/me (só o próprio profissional
/// lê). Se a rota não responder, valem os dados enviados na sessão atual; nunca
/// são inventados a partir do detalhe público.
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
  bool _isPhotoSubmitting = false;
  String? _photoError;
  bool _sessionExpired = false;
  int _generation = 0;

  ProfessionalProfileStatus get status => _status;
  ProfessionalProfile? get profile => _profile;
  String? get cpfInSession => _cpfInSession;
  DateTime? get birthDateInSession => _birthDateInSession;
  String? get loadError => _loadError;
  String? get submitError => _submitError;
  bool get isSubmitting => _isSubmitting;
  bool get isPhotoSubmitting => _isPhotoSubmitting;
  String? get photoError => _photoError;
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
      final private = await _api.fetchOwnPrivateData();
      if (generation != _generation) return;
      if (private != null && private.cpf.length == 11) {
        _cpfInSession = private.cpf;
      }
      if (private?.birthDate != null) _birthDateInSession = private!.birthDate;
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

  /// Salva o perfil. Quando [specialtyId] é informado, a especialidade é
  /// enviada antes (rota própria); se ela falhar, o perfil não é salvo e o
  /// formulário continua aberto para nova tentativa.
  Future<bool> submit(
    ProfessionalUpdateRequest request, {
    String? specialtyId,
    String? specialtyName,
  }) async {
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
        street: request.street,
        number: request.number,
        complement: request.complement,
        zipCode: request.zipCode,
        neighborhood: request.neighborhood,
        city: request.city,
        state: request.state,
      );
      if (specialtyId != null) {
        try {
          await _api.updateOwnSpecialty(specialtyId);
        } on ApiException catch (error) {
          if (error.isUnauthorized) rethrow;
          if (generation != _generation) return false;
          _submitError = error.isValidation || error.isConflict
              ? 'Não foi possível salvar a especialidade. Escolha outra.'
              : 'Não foi possível salvar a especialidade. ${error.message}';
          return false;
        }
      }
      await _api.updateOwnProfile(safeRequest);
      if (generation != _generation || _profile?.id != current.id) return false;
      _profile = current.copyWith(
        name: safeRequest.name.trim(),
        crefito: safeRequest.crefito.trim(),
        phone: safeRequest.phone.replaceAll(RegExp(r'\D'), ''),
        bio: safeRequest.bio.trim(),
        specialtyName: specialtyId != null ? specialtyName : null,
        address: ProfessionalAddress(
          street: safeRequest.street.trim(),
          number: safeRequest.number.trim(),
          complement: safeRequest.complement.trim(),
          zipCode: safeRequest.zipCode.replaceAll(RegExp(r'\D'), ''),
          neighborhood: safeRequest.neighborhood.trim(),
          city: safeRequest.city.trim(),
          state: safeRequest.state.trim().toUpperCase(),
        ),
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

  Future<bool> updatePhoto(List<int> bytes) async {
    if (!canEdit || _isPhotoSubmitting) return false;
    final generation = _generation;
    final current = _profile!;
    _isPhotoSubmitting = true;
    _photoError = null;
    notifyListeners();
    try {
      final url = await _api.updateOwnPhoto(
        bytes: bytes,
        fileName: 'foto-perfil.jpg',
        contentType: 'image/jpeg',
      );
      if (generation != _generation || _profile?.id != current.id) return false;
      _profile = current.withPhotoUrl(url);
      return true;
    } on ApiException catch (error) {
      if (generation != _generation) return false;
      _sessionExpired = error.isUnauthorized;
      _photoError = error.message;
      return false;
    } catch (_) {
      if (generation != _generation) return false;
      _photoError = 'Não foi possível enviar a foto. Tente novamente.';
      return false;
    } finally {
      _isPhotoSubmitting = false;
      if (generation == _generation) notifyListeners();
    }
  }

  Future<bool> removePhoto() async {
    if (!canEdit || _isPhotoSubmitting) return false;
    final generation = _generation;
    final current = _profile!;
    _isPhotoSubmitting = true;
    _photoError = null;
    notifyListeners();
    try {
      await _api.removeOwnPhoto();
      if (generation != _generation || _profile?.id != current.id) return false;
      _profile = current.withPhotoUrl(null);
      return true;
    } on ApiException catch (error) {
      if (generation != _generation) return false;
      _sessionExpired = error.isUnauthorized;
      _photoError = error.message;
      return false;
    } catch (_) {
      if (generation != _generation) return false;
      _photoError = 'Não foi possível remover a foto. Tente novamente.';
      return false;
    } finally {
      _isPhotoSubmitting = false;
      if (generation == _generation) notifyListeners();
    }
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}

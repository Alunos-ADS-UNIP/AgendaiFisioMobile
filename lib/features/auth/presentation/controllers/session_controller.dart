import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/auth_api.dart';
import '../../data/session_storage.dart';
import '../../domain/auth_session.dart';

enum SessionStatus { restoring, unauthenticated, authenticating, authenticated }

class SessionController extends ChangeNotifier {
  factory SessionController({
    required AuthGateway authGateway,
    required SessionStorage storage,
    DateTime Function()? now,
  }) => SessionController._(authGateway, storage, now ?? DateTime.now);

  SessionController._(this._authGateway, this._storage, this._now);

  final AuthGateway _authGateway;
  final SessionStorage _storage;
  final DateTime Function() _now;
  static const _storageTimeout = Duration(seconds: 5);

  SessionStatus _status = SessionStatus.restoring;
  SessionStatus get status => _status;
  AuthSession? _session;
  AuthSession? get session => _session;
  AuthenticatedUser? get user => _session?.user;
  String? get accessToken => _session?.accessToken;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool _sessionExpired = false;

  /// `true` quando a sessão acabou por conta do servidor (401/token vencido)
  /// e não porque a pessoa clicou em "Sair". A tela de login usa isso para
  /// explicar por que o usuário voltou para ela.
  bool get sessionExpired => _sessionExpired;
  bool get isBusy =>
      _status == SessionStatus.restoring ||
      _status == SessionStatus.authenticating;

  Future<String?> tokenProvider() async {
    final current = _session;
    if (current == null || current.isExpiredAt(_now())) return null;
    return current.accessToken;
  }

  Future<void> restore() async {
    _status = SessionStatus.restoring;
    notifyListeners();
    try {
      final saved = await _storage.read().timeout(_storageTimeout);
      if (saved == null || saved.isExpiredAt(_now())) {
        await _clearStorage();
        _setUnauthenticated();
        return;
      }
      final user = await _authGateway.me(saved.accessToken);
      _session = saved.copyWith(user: user);
      await _writeStorage(_session!);
      _status = SessionStatus.authenticated;
      _errorMessage = null;
    } catch (_) {
      unawaited(_clearStorage());
      _setUnauthenticated();
      return;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _status = SessionStatus.authenticating;
    _errorMessage = null;
    _sessionExpired = false;
    notifyListeners();
    try {
      final session = await _authGateway.login(
        email: email,
        password: password,
      );
      await _writeStorage(session);
      _session = session;
      _status = SessionStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _session = null;
      _status = SessionStatus.unauthenticated;
      _errorMessage = error.statusCode == 401
          ? 'E-mail ou senha incorretos.'
          : error.message;
    } catch (_) {
      _session = null;
      _status = SessionStatus.unauthenticated;
      _errorMessage = 'Não foi possível entrar. Verifique sua conexão.';
    }
    notifyListeners();
    return false;
  }

  void clearError() {
    if (_errorMessage == null && !_sessionExpired) return;
    _errorMessage = null;
    _sessionExpired = false;
    notifyListeners();
  }

  Future<void> logout() async {
    final token = _session?.accessToken;
    if (token != null) {
      try {
        await _authGateway.logout(token);
      } catch (_) {
        // A sessão local sempre termina, mesmo se a API estiver indisponível.
      }
    }
    await _endSession();
  }

  /// Chamado quando a API recusa o token (401). Encerra a sessão e marca que
  /// foi expiração, para o login avisar o usuário.
    Future<void> expireSession() async {
    final shouldNotify = _session != null || _sessionExpired;
    await _endSession();
    if (shouldNotify) {
      _sessionExpired = true;
      notifyListeners();
    }
  }

  Future<void> _endSession() async {
    await _clearStorage();
    _setUnauthenticated();
    notifyListeners();
  }

  Future<void> _writeStorage(AuthSession session) async {
    try {
      await _storage.write(session).timeout(_storageTimeout);
    } catch (_) {
      // A sessão continua válida em memória; apenas não será restaurada.
    }
  }

  Future<void> _clearStorage() async {
    try {
      await _storage.clear().timeout(_storageTimeout);
    } catch (_) {
      // Nunca mantém a navegação bloqueada por falha do armazenamento nativo.
    }
  }

  void _setUnauthenticated() {
    _session = null;
    _status = SessionStatus.unauthenticated;
    _errorMessage = null;
    _sessionExpired = false;
  }
}

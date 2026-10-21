import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_exception.dart';
import '../domain/auth_session.dart';

abstract interface class AuthGateway {
  Future<AuthSession> login({required String email, required String password});
  Future<AuthenticatedUser> me(String accessToken);
  Future<void> logout(String accessToken);
}

class AuthApi implements AuthGateway {
  factory AuthApi({required String baseUrl, http.Client? client}) =>
      AuthApi._(baseUrl, client ?? http.Client());

  AuthApi._(this._baseUrl, this._client);

  final String _baseUrl;
  final http.Client _client;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl/api/Auth/login'),
        headers: _jsonHeaders,
        body: jsonEncode({'email': email.trim(), 'senha': password}),
      ),
    );
    final json = _decodeMap(response);
    try {
      return AuthSession.fromLoginJson(json);
    } on FormatException {
      throw ApiException('O servidor devolveu uma sessão inválida.');
    }
  }

  @override
  Future<AuthenticatedUser> me(String accessToken) async {
    final response = await _send(
      () => _client.get(
        Uri.parse('$_baseUrl/api/Auth/me'),
        headers: _authorizedHeaders(accessToken),
      ),
    );
    return AuthenticatedUser.fromJson(_decodeMap(response));
  }

  @override
  Future<void> logout(String accessToken) async {
    await _send(
      () => _client.post(
        Uri.parse('$_baseUrl/api/Auth/logout'),
        headers: _authorizedHeaders(accessToken),
      ),
    );
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(const Duration(seconds: 20));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      throw _exceptionFor(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('O servidor demorou para responder. Tente novamente.');
    } on http.ClientException {
      throw ApiException('Não foi possível conectar ao servidor.');
    }
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // Mapeado abaixo como resposta inesperada, sem expor o corpo recebido.
    }
    throw ApiException('O servidor devolveu uma resposta inválida.');
  }

  ApiException _exceptionFor(http.Response response) {
    String? message;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        message = (decoded['erro'] ?? decoded['Erro'] ?? decoded['mensagem'])
            ?.toString();
      }
    } catch (_) {}
    if (response.statusCode == 401) {
      return ApiException(
        message ?? 'E-mail ou senha incorretos.',
        statusCode: 401,
      );
    }
    return ApiException(
      message ?? 'Não foi possível completar a operação.',
      statusCode: response.statusCode,
    );
  }

  static const _jsonHeaders = <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Map<String, String> _authorizedHeaders(String token) => {
    ..._jsonHeaders,
    'Authorization': 'Bearer $token',
  };
}

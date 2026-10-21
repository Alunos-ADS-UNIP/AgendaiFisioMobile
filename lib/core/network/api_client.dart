import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'auth_header_provider.dart';

/// Cliente HTTP único do aplicativo. Centraliza a URL base, a injeção do
/// Bearer token em chamadas autenticadas e a conversão de erros da API em
/// [ApiException].
///
/// Pensado para ser criado uma vez (ex: num `main.dart` ou num container de
/// dependências) e injetado em cada `*_api.dart` de feature, como
/// `PatientApi`. O [authHeaderProvider] deve vir do `session_controller.dart`
/// do Jonas; enquanto essa parte não existe, qualquer função que devolva
/// `null` ou um token fixo de teste serve.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    this.authHeaderProvider,
  }) : _client = httpClient ?? http.Client();

  /// Ex: http://localhost:5048 (emulador Android usa 10.0.2.2 em vez de
  /// localhost para enxergar o host da máquina).
  final String baseUrl;
  final http.Client _client;
  final AuthHeaderProvider? authHeaderProvider;

  Future<Map<String, dynamic>> get(
    String path, {
    bool authenticated = true,
  }) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: await _buildHeaders(authenticated: authenticated),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: await _buildHeaders(authenticated: authenticated),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = true,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl$path'),
      headers: await _buildHeaders(authenticated: authenticated),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, String>> _buildHeaders({
    required bool authenticated,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Login, cadastro e a documentação da API nunca recebem o Bearer.
    if (authenticated && authHeaderProvider != null) {
      final token = await authHeaderProvider!.call();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
    }

    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

    if (isSuccess) {
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{};
    }

    throw _toApiException(response.statusCode, decoded);
  }

  ApiException _toApiException(int statusCode, dynamic decoded) {
    if (statusCode == 401) {
      return ApiException(
        'Sessão expirada. Faça login novamente.',
        statusCode: 401,
      );
    }

    if (decoded is Map<String, dynamic>) {
      // Formato padrão de validação do ASP.NET: { "errors": { "Campo": [...] } }
      final rawErrors = decoded['errors'];
      if (rawErrors is Map<String, dynamic>) {
        final fieldErrors = <String, String>{};
        rawErrors.forEach((field, messages) {
          fieldErrors[field] = messages is List
              ? messages.join(' ')
              : messages.toString();
        });
        return ApiException(
          decoded['title']?.toString() ?? 'Verifique os campos destacados.',
          statusCode: statusCode,
          fieldErrors: fieldErrors,
        );
      }

      // Formato usado pelos controllers: { "erro": "..." } ou { "Erro": "..." }
      final message =
          decoded['erro'] ??
          decoded['Erro'] ??
          decoded['mensagem'] ??
          decoded['title'];
      if (message != null) {
        return ApiException(message.toString(), statusCode: statusCode);
      }
    }

    return ApiException(
      'Não foi possível completar a operação.',
      statusCode: statusCode,
    );
  }
}

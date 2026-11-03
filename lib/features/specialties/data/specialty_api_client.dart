import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

abstract interface class SpecialtyHttpClient {
  /// Recebe caminhos canônicos começando por `/api`.
  /// O adapter do cliente compartilhado remove o prefixo quando a base URL já
  /// termina em `/api`. Esta interface não conhece nem armazena JWT.
  Future<SpecialtyHttpResponse> get(String path, {required bool authenticated});

  Future<SpecialtyHttpResponse> post(
    String path,
    Map<String, dynamic> body, {
    required bool authenticated,
  });

  Future<SpecialtyHttpResponse> put(
    String path,
    Map<String, dynamic> body, {
    required bool authenticated,
  });
}

class ApiSpecialtyHttpClient implements SpecialtyHttpClient {
  const ApiSpecialtyHttpClient({required this.apiClient, this.onUnauthorized});

  final ApiClient apiClient;
  final Future<void> Function()? onUnauthorized;

  @override
  Future<SpecialtyHttpResponse> get(
    String path, {
    required bool authenticated,
  }) => _send('GET', path, authenticated: authenticated);

  @override
  Future<SpecialtyHttpResponse> post(
    String path,
    Map<String, dynamic> body, {
    required bool authenticated,
  }) => _send('POST', path, body: body, authenticated: authenticated);

  @override
  Future<SpecialtyHttpResponse> put(
    String path,
    Map<String, dynamic> body, {
    required bool authenticated,
  }) => _send('PUT', path, body: body, authenticated: authenticated);

  Future<SpecialtyHttpResponse> _send(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    required bool authenticated,
  }) async {
    try {
      final response = await apiClient.request(
        method,
        specialtyPathForBaseUrl(apiClient.baseUrl, endpoint),
        body: body,
        authenticated: authenticated,
      );
      return SpecialtyHttpResponse(
        statusCode: response.statusCode,
        body: response.body,
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await onUnauthorized?.call();
      }
      return SpecialtyHttpResponse(statusCode: error.statusCode ?? 500);
    }
  }
}

class SpecialtyHttpResponse {
  const SpecialtyHttpResponse({required this.statusCode, this.body});

  final int statusCode;
  final Object? body;
}

/// Normaliza um endpoint canônico para a convenção de base URL do futuro
/// adapter do cliente compartilhado.
String specialtyPathForBaseUrl(String baseUrl, String endpoint) {
  final basePath = Uri.parse(baseUrl).path.replaceFirst(RegExp(r'/+$'), '');
  final canonical = endpoint.startsWith('/') ? endpoint : '/$endpoint';
  final baseHasApiSuffix = basePath == '/api' || basePath.endsWith('/api');
  if (baseHasApiSuffix && canonical == '/api') return '/';
  if (baseHasApiSuffix && canonical.startsWith('/api/')) {
    return canonical.substring('/api'.length);
  }
  return canonical;
}

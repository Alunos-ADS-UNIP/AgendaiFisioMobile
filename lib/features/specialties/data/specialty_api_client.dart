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

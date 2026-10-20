/// Erro lançado pelo [ApiClient] quando a API responde com um status de erro.
///
/// [fieldErrors] vem preenchido quando o backend devolve o formato de
/// validação do ASP.NET (`{ "errors": { "Campo": ["mensagem"] } }`), que é o
/// mesmo formato usado nos controllers de Paciente e Profissional. Cada chave
/// já vem com as mensagens concatenadas, prontas para exibir embaixo do
/// campo correspondente.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors});

  final String message;
  final int? statusCode;
  final Map<String, String>? fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;
  bool get isValidation => fieldErrors != null && fieldErrors!.isNotEmpty;

  @override
  String toString() => message;
}

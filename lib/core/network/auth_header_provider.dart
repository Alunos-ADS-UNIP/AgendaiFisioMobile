/// Função que devolve o header de autorização (ex: "Bearer eyJ...") para
/// requisições autenticadas, ou `null` quando não há sessão ativa.
///
/// O Jonas vai implementar a versão real disso dentro do
/// `session_controller.dart` (lendo o token do armazenamento seguro). Até lá,
/// qualquer tela que precise de um [ApiClient] pode passar uma função
/// provisória, como `() async => null`, sem travar o desenvolvimento.
typedef AuthHeaderProvider = Future<String?> Function();

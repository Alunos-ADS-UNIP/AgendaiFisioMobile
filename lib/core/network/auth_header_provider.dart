/// Função que devolve somente o token JWT (sem o prefixo `Bearer`) para
/// requisições autenticadas, ou `null` quando não há sessão ativa.
typedef AuthHeaderProvider = Future<String?> Function();

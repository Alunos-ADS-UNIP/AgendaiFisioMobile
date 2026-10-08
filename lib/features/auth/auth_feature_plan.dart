/// RESPONSÁVEIS: Dudu (interface) e Jonas (sessão e infraestrutura).
///
/// OBJETIVO DA FEATURE:
/// Substituir o catálogo de componentes pelo fluxo real de inicialização,
/// autenticação e restauração de sessão. Deve existir uma única implementação
/// compartilhada pelos dois grupos.
///
/// DUDU DEVE CRIAR:
/// - `presentation/pages/login_page.dart`: formulário de e-mail e senha usando
///   AppTextField e AppPrimaryButton; validar campos; mostrar carregamento e
///   mensagens de credenciais inválidas; não implementar "lembrar senha" falso.
/// - `presentation/pages/session_expired_page.dart` ou diálogo equivalente:
///   explicar que a sessão expirou e levar o usuário novamente ao login.
/// - Estados visuais de carregamento, erro, sem conexão e autenticação concluída.
///
/// JONAS DEVE CRIAR:
/// - `data/auth_api.dart`: integrar POST /api/auth/login, GET /api/auth/me e
///   POST /api/auth/logout; DTOs devem refletir exatamente a resposta da API.
/// - `data/secure_session_storage.dart`: guardar accessToken, usuarioId,
///   perfilId, email, tipoUsuario e expiresAtUtc em armazenamento seguro.
/// - `presentation/controllers/session_controller.dart`: restaurar sessão ao
///   abrir o aplicativo, limpar sessão em logout ou 401 e expor o usuário atual.
/// - Interceptor HTTP que injeta Bearer somente nas rotas protegidas.
/// - Guardas que impeçam Paciente, Profissional e Clínica de abrir telas de outro
///   papel. Não confiar apenas em esconder botões.
///
/// FLUXO DE INICIALIZAÇÃO:
/// 1. Abrir uma splash simples.
/// 2. Ler a sessão segura.
/// 3. Se não houver token, abrir login.
/// 4. Se houver token, consultar /api/auth/me.
/// 5. Se a resposta for 200, direcionar pelo tipoUsuario.
/// 6. Se a resposta for 401, limpar tudo e abrir login.
///
/// REGRAS OBRIGATÓRIAS:
/// - Nunca salvar senha.
/// - Nunca imprimir JWT, senha ou CPF em logs.
/// - Login, cadastro e OpenAPI não recebem Bearer.
/// - Requisições para outra origem nunca recebem o token.
/// - Todas as telas protegidas usam a identidade retornada pela sessão.
///
/// CRITÉRIOS DE CONCLUSÃO:
/// - Login válido abre a área correta sem copiar JWT manualmente.
/// - Reiniciar o aplicativo restaura uma sessão válida.
/// - 401 limpa a sessão e volta ao login.
/// - Existem testes do controller, armazenamento e guarda de navegação.
abstract final class AuthFeaturePlan {
  const AuthFeaturePlan._();
}

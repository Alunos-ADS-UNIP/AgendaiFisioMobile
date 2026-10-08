/// RESPONSÁVEL: João V - Grupo B.
///
/// OBJETIVO DA FEATURE:
/// Implementar cadastro básico, completar perfil e área Meu perfil do
/// Fisioterapeuta, sempre usando a identidade do JWT e sem pedir IDs técnicos.
///
/// TELAS QUE JOÃO V DEVE CRIAR:
/// - `presentation/pages/professional_register_page.dart`: se o autocadastro fizer
///   parte da apresentação, chamar POST /api/auth/register com tipoUsuario
///   "Profissional" e depois direcionar para completar o perfil.
/// - `presentation/pages/professional_profile_page.dart`: resumo com nome, CREFITO,
///   telefone, bio, especialidade, situação, Editar, Alterar especialidade e Sair.
/// - `presentation/pages/professional_profile_form_page.dart`: nome, CPF, CREFITO,
///   telefone, nascimento e bio; integrar PUT /api/profissional/completar-perfil;
///   usar ProfileSection/AppTextField e atualizar o estado só após sucesso.
///
/// LIMITAÇÃO ATUAL DO BACKEND:
/// Ainda não existe GET /api/profissional/me com todos os campos privados. Não usar
/// GET /api/profissional/{id} para preencher CPF ou nascimento, porque essa rota é
/// pública e não deve expor esses dados. A tela pode manter os valores enviados na
/// sessão atual, mas deve deixar a integração de leitura marcada como pendente.
///
/// ERROS E REGRAS:
/// - Não solicitar usuarioId ou profissionalId.
/// - Tratar 409 de CREFITO duplicado sem sobrescrever valores locais.
/// - Mostrar erros de validação junto ao campo.
/// - Somente Profissional acessa o formulário próprio.
///
/// FEATURE ADMINISTRATIVA BLOQUEADA:
/// A atualização de outro profissional pela Clínica precisa de uma rota com ID
/// explícito. Pode preparar `professional_admin_edit_page.dart`, mas não reutilizar
/// a rota de autoatendimento e não marcar a integração como concluída.
///
/// CRITÉRIOS DE CONCLUSÃO:
/// - Perfil é enviado e confirmado pela API.
/// - CREFITO duplicado mantém os dados digitados.
/// - Há testes de formulário, 409 e restrição por papel.
abstract final class ProfessionalProfileFeaturePlan {
  const ProfessionalProfileFeaturePlan._();
}

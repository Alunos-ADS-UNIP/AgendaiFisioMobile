/// RESPONSÁVEL: Jonas - Grupo B.
///
/// OBJETIVO DA FEATURE:
/// Implementar catálogo, filtros e detalhe público dos Fisioterapeutas. Jonas
/// também é corresponsável pela sessão descrita em auth/auth_feature_plan.dart.
///
/// TELAS QUE JONAS DEVE CRIAR:
/// - `presentation/pages/professional_catalog_page.dart`: integrar GET
///   /api/profissional?nome=&especialidadeId=&ativo=&pagina=&tamanhoPagina=;
///   usar AppSearchField, ProfessionalCard, paginação e estados comuns.
/// - `presentation/widgets/professional_filters_sheet.dart`: especialidade e
///   ativo/inativo; buscar especialidades em GET /api/especialidade; permitir
///   aplicar e limpar; mudança de filtro reinicia a paginação.
/// - `presentation/pages/professional_details_page.dart`: integrar GET
///   /api/profissional/{id}; mostrar nome, CREFITO, bio, especialidade e situação.
///   Para Paciente, oferecer "Agendar com este profissional" abrindo o fluxo da
///   Liska já com o profissional selecionado.
///
/// REGRAS OBRIGATÓRIAS:
/// - Busca por nome deve usar debounce para não chamar a API a cada tecla.
/// - Preservar filtros e posição ao voltar do detalhe.
/// - Não carregar todas as páginas de uma vez.
/// - O detalhe público nunca mostra CPF, nascimento ou outros dados privados.
/// - 404 volta com mensagem amigável sem quebrar a navegação.
///
/// CAMADAS A CRIAR:
/// - DTOs, modelo de domínio, professional_api, repository e controller paginado.
/// - O controller deve cancelar/ignorar respostas antigas de buscas substituídas.
///
/// CRITÉRIOS DE CONCLUSÃO:
/// - Pesquisa, filtros e paginação funcionam juntos.
/// - Voltar do detalhe conserva a busca.
/// - Vazio, erro e carregamento ficam visualmente distintos.
/// - Existem testes de debounce, paginação, filtros e detalhe 404.
abstract final class ProfessionalCatalogFeaturePlan {
  const ProfessionalCatalogFeaturePlan._();
}

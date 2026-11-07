/// RESPONSÁVEL: Davi - Grupo B.
///
/// OBJETIVO DA FEATURE:
/// Implementar o catálogo reutilizável de Especialidades, o seletor usado por
/// outras features e o vínculo ao perfil profissional.
///
/// TELAS E COMPONENTES QUE DAVI DEVE CRIAR:
/// - `presentation/pages/specialty_list_page.dart`: GET /api/especialidade; lista
///   pública com busca local/remota conforme o contrato; loading, vazio e erro.
/// - `presentation/widgets/specialty_picker_sheet.dart`: pesquisa e seleção única;
///   deve ser reutilizado por Jonas nos filtros, por João V no perfil e por Liska
///   no agendamento; não duplicar três seletores diferentes.
/// - `presentation/widgets/specialty_chip.dart`: representação compacta do nome.
/// - `presentation/pages/professional_specialty_page.dart`: mostrar especialidade
///   atual e integrar PUT /api/profissional/especialidade com
///   {"especialidadeId":"..."}.
///
/// ROTAS:
/// - GET /api/especialidade
/// - GET /api/especialidade/{id}
/// - PUT /api/profissional/especialidade
///
/// ERROS E REGRAS:
/// - A listagem deve funcionar antes do login.
/// - Tratar 400, 404 e 409 com mensagens específicas.
/// - Uma especialidade duplicada não aparece duas vezes na memória.
/// - Profissional pode selecionar/trocar; Paciente apenas consulta.
///
/// CRITÉRIOS DE CONCLUSÃO:
/// - Um único picker é reutilizado pelas outras features.
/// - Troca de especialidade reflete apenas após sucesso da API.
/// - Criação 201 atualiza a lista; conflito 409 não duplica.
/// - Existem testes dos três papéis e da prevenção de duplicidade.
abstract final class SpecialtyFeaturePlan {
  const SpecialtyFeaturePlan._();
}

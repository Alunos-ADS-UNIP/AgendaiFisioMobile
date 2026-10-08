/// RESPONSÁVEL: Davi - Grupo B.
///
/// OBJETIVO DA FEATURE:
/// Implementar o catálogo reutilizável de Especialidades, o seletor usado por
/// outras features, o vínculo ao perfil profissional e a criação pela Clínica.
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
/// - `presentation/pages/clinic_specialties_page.dart`: lista com ação Nova
///   especialidade visível apenas para Clínica.
/// - `presentation/widgets/create_specialty_dialog.dart`: integrar POST
///   /api/especialidade e incluir o item retornado no catálogo sem duplicar.
///
/// ROTAS:
/// - GET /api/especialidade
/// - GET /api/especialidade/{id}
/// - PUT /api/profissional/especialidade
/// - POST /api/especialidade (somente Clínica)
///
/// ERROS E REGRAS:
/// - A listagem deve funcionar antes do login.
/// - Tratar 400, 404 e 409 com mensagens específicas.
/// - Uma especialidade duplicada não aparece duas vezes na memória.
/// - Profissional pode selecionar/trocar; Paciente apenas consulta; Clínica cria.
///
/// CRITÉRIOS DE CONCLUSÃO:
/// - Um único picker é reutilizado pelas outras features.
/// - Troca de especialidade reflete apenas após sucesso da API.
/// - Criação 201 atualiza a lista; conflito 409 não duplica.
/// - Existem testes dos três papéis e da prevenção de duplicidade.
abstract final class SpecialtyFeaturePlan {
  const SpecialtyFeaturePlan._();
}

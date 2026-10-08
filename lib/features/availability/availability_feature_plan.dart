/// RESPONSÁVEL: Gabriel - Grupo B.
///
/// OBJETIVO DA FEATURE:
/// Preparar a interface de agenda semanal e disponibilidade do Fisioterapeuta.
/// As rotas específicas ainda não existem; por isso a UI e os testes podem ser
/// adiantados com repositório falso, mas a integração permanece bloqueada.
///
/// TELAS QUE GABRIEL DEVE CRIAR:
/// - `presentation/pages/professional_home_page.dart`: resumo do dia e próximas
///   consultas usando GET /api/agendamento, atalhos para Agenda, Pacientes, Grade e
///   Perfil. Esta parte pode funcionar antes das novas rotas de disponibilidade.
/// - `presentation/pages/professional_availability_page.dart`: calendário semanal,
///   dias/turnos, vazio, carregando e indisponível.
/// - `presentation/pages/weekly_schedule_form_page.dart`: ativar/desativar dia,
///   escolher início/fim e permitir turnos; impedir intervalos inválidos ou
///   sobrepostos antes de enviar.
/// - `presentation/pages/available_slots_page.dart`: selecionar data e mostrar
///   horários disponíveis, selecionados, ocupados e desabilitados.
/// - `presentation/widgets/weekly_schedule.dart` e
///   `presentation/widgets/available_time_grid.dart`: componentes sem HTTP que
///   possam ser reutilizados por Liska no agendamento.
///
/// O QUE PODE SER FEITO AGORA:
/// - Modelos de apresentação e interfaces de repository sem URL concreta.
/// - Repositório falso com cenários cheio, vazio, carregando e erro.
/// - Widgets, validações e testes de widget.
/// - ProfessionalHomePage usando a rota de agenda já existente.
///
/// O QUE NÃO PODE SER FEITO:
/// - Inventar endpoints ou payloads.
/// - Gravar grade apenas em memória e chamar isso de integração concluída.
/// - Assumir duração, intervalo ou regra de sobreposição sem contrato do backend.
///
/// DEPENDÊNCIAS PARA CONCLUIR:
/// O backend precisa publicar contratos para consultar/alterar a grade e consultar
/// disponibilidade por profissional e período, incluindo timezone e regras.
///
/// CRITÉRIOS DE CONCLUSÃO DA PARTE VISUAL:
/// - Funciona em 360 px e com texto a 150%.
/// - Horários não dependem só de cor; possuem texto/semântica.
/// - Testes cobrem seleção, dia inativo, conflito local e estados da grade.
abstract final class AvailabilityFeaturePlan {
  const AvailabilityFeaturePlan._();
}

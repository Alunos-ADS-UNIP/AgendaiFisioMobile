/// RESPONSÁVEL: Liska - Grupo A.
///
/// OBJETIVO DA FEATURE:
/// Implementar a agenda do Paciente, o detalhe e o fluxo completo de novo
/// agendamento. Este é o principal fluxo da apresentação.
///
/// TELAS QUE LISKA DEVE CRIAR:
/// - `presentation/pages/patient_home_page.dart`: saudação, próxima consulta,
///   botão Agendar, atalho para Agenda e atalho para Histórico.
/// - `presentation/pages/appointments_page.dart`: lista paginada/filtrada de
///   GET /api/agendamento?data=&profissionalId=&status= usando AppointmentCard;
///   conter carregamento, vazio, erro e atualização após criar um item.
/// - `presentation/widgets/appointment_filters_sheet.dart`: data, profissional e
///   status; permitir combinar, aplicar e limpar filtros.
/// - `presentation/pages/appointment_details_page.dart`: GET /api/agendamento/{id};
///   mostrar data, horário, profissional, especialidade, observações e StatusChip.
/// - `presentation/pages/new_appointment_page.dart`: fluxo em etapas para escolher
///   especialidade, profissional, data/hora, observações e revisar antes de enviar.
/// - `presentation/pages/appointment_created_page.dart`: resumo após resposta 201,
///   com botões para abrir o detalhe ou voltar à agenda.
///
/// ROTAS A INTEGRAR:
/// - GET /api/agendamento
/// - GET /api/agendamento/{id}
/// - POST /api/agendamento
/// - GET /api/profissional
/// - GET /api/profissional/{id}
/// - GET /api/especialidade
///
/// REGRA MAIS IMPORTANTE:
/// O POST do paciente envia somente profissionalId, dataHora, status opcional e
/// observacoes opcional. Nunca enviar pacienteId: a API identifica o paciente pelo
/// JWT. Datas devem sair em ISO 8601 com offset ou Z e aparecer no fuso local.
///
/// ERROS OBRIGATÓRIOS:
/// - 404: profissional não encontrado/indisponível.
/// - 409: o horário acabou de ser reservado; orientar a escolher outro.
/// - 401: usar o fluxo global de sessão expirada.
/// - Falha de rede: preservar a seleção e oferecer nova tentativa.
///
/// CRITÉRIOS DE CONCLUSÃO:
/// - Agendamento criado sem pacienteId aparece imediatamente na lista.
/// - Filtros combinam e podem ser limpos.
/// - Conflito não duplica registro.
/// - Há testes de serialização, controller, filtros e widgets do fluxo principal.
abstract final class AppointmentFeaturePlan {
  const AppointmentFeaturePlan._();
}

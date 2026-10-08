/// RESPONSÁVEL: Caio - Grupo A.
///
/// OBJETIVO DA FEATURE:
/// Implementar o histórico de consultas do Paciente e o componente reutilizável
/// para a visão autorizada do Fisioterapeuta. Preparar também as interfaces do
/// ciclo futuro de reagendamento, cancelamento e alteração de status.
///
/// TELAS QUE CAIO DEVE CRIAR AGORA:
/// - `presentation/pages/patient_history_page.dart`: usar GET
///   /api/paciente/me/historico-consultas?pagina=&tamanhoPagina=; listar da consulta
///   mais recente para a mais antiga; suportar paginação incremental sem duplicar.
/// - `presentation/pages/patient_history_for_professional_page.dart`: usar GET
///   /api/paciente/{pacienteId}/historico-consultas somente quando o Profissional
///   recebeu esse ID de um fluxo autorizado; reutilizar o mesmo item visual.
/// - `presentation/widgets/appointment_history_tile.dart`: data/hora, profissional,
///   especialidade e StatusChip; não conter chamada HTTP dentro do widget.
///
/// ESTADOS E SEGURANÇA:
/// - Histórico vazio tem mensagem específica, não erro genérico.
/// - 403 e 404 não devem revelar se um paciente proibido realmente existe.
/// - Paciente usa exclusivamente a rota /me e nunca informa o próprio ID.
/// - Fim da paginação não dispara novamente a mesma página.
///
/// BAIXA PRIORIDADE PARA A APRESENTAÇÃO:
/// - `administrative_appointment_page.dart` integraria POST
///   /api/agendamento/administrativo e seria visível somente para Clínica. Como não
///   haverá agendamento por Clínica na apresentação, fazer apenas depois do fluxo
///   principal e nunca reutilizar esse payload no agendamento do Paciente.
///
/// FUNCIONALIDADES BLOQUEADAS PELO BACKEND:
/// - `reschedule_appointment_page.dart`.
/// - `cancel_appointment_dialog.dart`.
/// - `appointment_status_sheet.dart`.
/// Caio pode preparar interface e testes falsos, mas não deve inventar endpoints,
/// transições de status ou simular sucesso somente no estado local.
///
/// CRITÉRIOS DE CONCLUSÃO:
/// - Histórico próprio funciona sem pacienteId.
/// - Paginação mantém ordem e não duplica itens.
/// - Visão profissional respeita 403/404.
/// - Existem testes de paginação e dos estados vazio, carregando e erro.
abstract final class HistoryFeaturePlan {
  const HistoryFeaturePlan._();
}

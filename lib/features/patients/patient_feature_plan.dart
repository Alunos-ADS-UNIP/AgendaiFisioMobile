/// RESPONSÁVEL: Dudu - Grupo A.
///
/// OBJETIVO DA FEATURE:
/// Implementar cadastro, visualização e edição do próprio perfil de Paciente.
/// Esta é a parte do frontend correspondente às rotas de pacientes feitas pelo
/// Grupo B no backend.
///
/// TELAS QUE DUDU DEVE CRIAR:
/// - `presentation/pages/patient_register_page.dart`: e-mail, senha e confirmação;
///   enviar tipoUsuario "Paciente" para POST /api/auth/register; tratar e-mail
///   duplicado e validações; depois direcionar para login ou sessão autenticada.
/// - `presentation/pages/patient_profile_page.dart`: consultar GET /api/paciente/me;
///   mostrar nome, CPF mascarado, nascimento, telefone, endereço, e-mail, botão
///   Editar perfil e botão Sair; nunca mostrar IDs técnicos.
/// - `presentation/pages/patient_profile_form_page.dart`: preencher/editar nome,
///   CPF, nascimento, telefone e endereço; integrar PUT
///   /api/paciente/completar-perfil; usar máscaras apenas na apresentação e
///   converter para o formato esperado pela API.
///
/// CAMADAS QUE DUDU DEVE CRIAR:
/// - DTOs de request/response em `data/dtos/`.
/// - `data/patient_api.dart` para as chamadas HTTP.
/// - `domain/patient.dart` sem dependência de widgets.
/// - `presentation/controllers/patient_profile_controller.dart` para loading,
///   conteúdo, validação, sucesso e erro.
///
/// REGRAS OBRIGATÓRIAS:
/// - Usar somente /api/paciente/me para o perfil do usuário logado.
/// - Nunca pedir, armazenar em campo ou montar manualmente pacienteId.
/// - Campos opcionais omitidos não podem apagar valores existentes sem intenção.
/// - Profissional e Clínica não acessam essas páginas.
/// - Reutilizar AppTextField, AppPrimaryButton, EmptyState e ErrorState.
///
/// FEATURE FUTURA BLOQUEADA:
/// - A lista administrativa, busca por nome/documento e detalhe de outro paciente
///   aguardam rotas administrativas do backend. É permitido preparar widgets e
///   testes falsos, mas não inventar URLs e não marcar a integração como concluída.
///
/// CRITÉRIOS DE CONCLUSÃO:
/// - Paciente cadastra, consulta e atualiza o próprio perfil.
/// - Erros aparecem no campo correto e envio duplicado é impedido.
/// - Há testes de DTO, controller e widget dos três estados principais.
abstract final class PatientFeaturePlan {
  const PatientFeaturePlan._();
}

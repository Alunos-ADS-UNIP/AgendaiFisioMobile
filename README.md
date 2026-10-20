# AgendaiFisio Mobile

Aplicativo Flutter do AgendaiFisio.

## Estado atual

O projeto contém a fundação visual compartilhada e o fluxo de agenda do paciente:

- tema Material 3;
- tokens de cor, espaçamento e borda;
- botões e campos padronizados;
- componentes de carregamento, vazio e erro;
- cards de agendamento e fisioterapeuta;
- chip centralizado de status;
- catálogo visual dos componentes;
- início do paciente com próxima consulta, agenda, histórico e novo agendamento;
- lista filtrada e paginada no cliente, detalhe e resumo após criar;
- repositório HTTP para agendamentos, profissionais e especialidades.
- arquivos de planejamento por feature e responsável.

A aplicação abre inicialmente o catálogo de componentes. O fluxo do paciente é
exibido quando `AgendaiFisioApp` recebe um `AppointmentRepository` criado pela
sessão autenticada. Essa injeção é intencional: as rotas de agendamento exigem
Bearer e o módulo compartilhado de login ainda precisa fornecer o token e a ação
global para sessão expirada. `AppointmentApiRepository` recebe a origem da API,
um provedor de token e um callback para tratar `401`; o token não é armazenado
nem incluído em rotas públicas de catálogo.

O cadastro de agendamento envia apenas `profissionalId`, `dataHora` em UTC e
observações opcionais. O `pacienteId` vem da identidade do JWT. O seletor trata
conflito `409` sem limpar os dados preenchidos e permite tentar outro horário.

## Organização

```text
lib/
├── app/          # inicialização e tema global
├── core/         # código reutilizado por todas as features
├── development/  # catálogo visual temporário
└── features/     # tarefas separadas por domínio e responsável
    └── appointments/ # agenda, detalhe e criação do paciente
```

Cada pasta dentro de `features` contém um arquivo `*_feature_plan.dart`. Esses
arquivos possuem comentários detalhados informando o responsável, as telas, as
rotas, os estados obrigatórios e os critérios de aceite.

## Comandos de validação

```bash
flutter pub get
flutter analyze
flutter test
```

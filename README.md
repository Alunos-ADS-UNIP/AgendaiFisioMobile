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
nem incluído nas rotas públicas de especialidades. As rotas de profissionais
também recebem o Bearer e acionam o callback de sessão em caso de `401`.

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

## Prévia das telas e padrão visual

```bash
flutter run -d chrome --web-port=5302 -t lib/main_appointments_preview.dart
```

A prévia abre a agenda com dados demonstrativos em memória. Ela permite testar
filtros, detalhes, escolha de especialidade/profissional, data, horário e resumo
de criação. Os dados não são enviados ao banco.

O tema usa Inter incluída nos assets, corpo de 16 px, texto mínimo de 12 px,
controles de pelo menos 48 px, raio de 12 px nos controles e 16 px nos modais.
Há navegação Início, Agendar, Agenda e Perfil. O perfil real deve ser fornecido por
`patientProfileBuilder`; enquanto não for integrado, a aba informa a dependência.

Os testes `agenda_design_test.dart` percorrem as telas em 360 × 800 com texto a
100% e 150%, incluindo a criação e o retorno com a lista atualizada. Para salvar
as capturas da renderização, defina `AGENDA_SCREENSHOTS_DIR` ao rodar esse teste.

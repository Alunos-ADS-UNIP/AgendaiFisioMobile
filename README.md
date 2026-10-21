# AgendaiFisio Mobile

Aplicativo Flutter do AgendaiFisio.

## Estado atual

O projeto contém a fundação visual compartilhada, autenticação e o fluxo de agenda do paciente:

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
- login por e-mail e senha integrado ao JWT do backend;
- restauração e encerramento de sessão com armazenamento seguro;
- proteção de área por perfil (Paciente, Profissional e Administrador);
- cadastro e perfil do paciente com consulta de endereço pelo ViaCEP;
- arquivos de planejamento por feature e responsável.

A aplicação abre na tela de login. O token é salvo no Keychain do iOS ou no
Keystore do Android e é incluído apenas nas chamadas autenticadas. Na abertura,
o app valida a sessão salva em `GET /api/Auth/me`; sessões expiradas ou respostas
`401` voltam ao login. Pacientes entram na área de agenda, histórico e perfil.
Profissionais e administradores permanecem em uma área protegida própria, sem
acesso acidental às telas exclusivas de paciente.

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

Por padrão, o app usa `http://127.0.0.1:5048` no simulador do iPhone e
`http://10.0.2.2:5048` no emulador Android. Outra origem pode ser informada sem
alterar o código:

```bash
flutter run --dart-define=API_BASE_URL=https://api.exemplo.com
```

## Prévia das telas e padrão visual

```bash
flutter run -d chrome --web-port=5302 -t lib/main_appointments_preview.dart
```

A prévia abre a agenda com dados demonstrativos em memória. Ela permite testar
filtros, detalhes, escolha de especialidade/profissional, data, horário e resumo
de criação. Os dados não são enviados ao banco.

## Perfil do profissional

`lib/features/professional_profile/` contém cadastro de conta profissional,
resumo do próprio perfil e formulário de completar/editar. O cadastro usa
`POST /api/auth/register` sem Bearer e, após sucesso, a navegação deve levar ao
login compartilhado. `ProfessionalProfilePage` recebe um
`ProfessionalProfileController` e um callback de logout da sessão. O controller
consulta `/api/auth/me`, confirma o papel `Profissional` e usa o `perfilId` da
resposta para buscar os dados públicos em `/api/profissional/{id}`. O formulário
envia `PUT /api/profissional/completar-perfil` sem incluir IDs técnicos nem
especialidade. A situação `ativo` é preservada a partir do detalhe carregado.

O backend ainda não fornece `GET /api/profissional/me` com CPF e data de
nascimento. Esses campos são obrigatórios no PUT, então precisam ser informados
novamente ao abrir o formulário após reiniciar a sessão; somente um envio
confirmado os mantém em memória durante a sessão atual. A troca de especialidade
é acionada por `onChangeSpecialty`, para usar a tela e o seletor do módulo de
especialidades quando estiverem integrados. O fluxo de login compartilhado ainda
deve montar essas páginas na navegação autenticada.

O tema usa Inter incluída nos assets, corpo de 16 px, texto mínimo de 12 px,
controles de pelo menos 48 px, raio de 12 px nos controles e 16 px nos modais.
Há navegação Início, Agendar, Agenda e Perfil. O perfil está integrado à
identidade do token, sem receber um `pacienteId` fornecido pela interface.

Os testes `agenda_design_test.dart` percorrem as telas em 360 × 800 com texto a
100% e 150%, incluindo a criação e o retorno com a lista atualizada. Para salvar
as capturas da renderização, defina `AGENDA_SCREENSHOTS_DIR` ao rodar esse teste.

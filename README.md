# AgendaiFisio Mobile

Aplicativo Flutter do AgendaiFisio.

## Estado atual

O projeto contém a fundação visual compartilhada para os Grupos A e B:

- tema Material 3;
- tokens de cor, espaçamento e borda;
- botões e campos padronizados;
- componentes de carregamento, vazio e erro;
- cards de agendamento e fisioterapeuta;
- chip centralizado de status;
- catálogo visual dos componentes;
- arquivos de planejamento por feature e responsável.

A aplicação abre inicialmente o catálogo de componentes. Ele é uma tela de
desenvolvimento e deve ser substituído pelo fluxo de sessão quando a autenticação
for integrada.

## Organização

```text
lib/
├── app/          # inicialização e tema global
├── core/         # código reutilizado por todas as features
├── development/  # catálogo visual temporário
└── features/     # tarefas separadas por domínio e responsável
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

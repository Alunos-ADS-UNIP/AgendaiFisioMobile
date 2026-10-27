import 'dart:convert';

import 'package:agendaifisiomobile/core/network/api_client.dart';
import 'package:agendaifisiomobile/core/utils/input_masks.dart';
import 'package:agendaifisiomobile/core/widgets/app_primary_button.dart';
import 'package:agendaifisiomobile/features/professional_profile/data/dtos/professional_profile_dtos.dart';
import 'package:agendaifisiomobile/features/professional_profile/data/professional_profile_api.dart';
import 'package:agendaifisiomobile/features/professional_profile/presentation/controllers/professional_profile_controller.dart';
import 'package:agendaifisiomobile/features/professional_profile/presentation/controllers/professional_register_controller.dart';
import 'package:agendaifisiomobile/features/professional_profile/presentation/pages/professional_profile_form_page.dart';
import 'package:agendaifisiomobile/features/professional_profile/presentation/pages/professional_profile_page.dart';
import 'package:agendaifisiomobile/features/professional_profile/presentation/pages/professional_register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _id = 'd701445c-485f-4a24-b1d1-a592c99d1272';
const _session = {
  'usuarioId': 'account-id',
  'perfilId': _id,
  'email': 'fisio@exemplo.com',
  'tipoUsuario': 'Profissional',
};
const _detail = {
  'id': _id,
  'nomeCompleto': 'Cadastro Pendente',
  'crefito': '',
  'telefone': '',
  'bio': '',
  'ativo': true,
  'especialidade': null,
  'email': 'fisio@exemplo.com',
};

ProfessionalUpdateRequest _request({String crefito = 'CREFITO-123'}) =>
    ProfessionalUpdateRequest(
      name: 'Joana Silva',
      cpf: '123.456.789-01',
      crefito: crefito,
      phone: '(11) 98765-4321',
      birthDate: DateTime(1990, 5, 12),
      bio: 'Fisioterapeuta esportiva',
      isActive: false,
    );

http.Response _json(Object value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

ProfessionalProfileApi _api(MockClient client) => ProfessionalProfileApi(
  ApiClient(
    baseUrl: 'https://backend.test',
    httpClient: client,
    authHeaderProvider: () async => 'token-de-teste',
  ),
);

void main() {
  test('telefone fixo e celular usam máscaras correspondentes', () {
    expect(InputMasks.applyTelefoneMask('1132345678'), '(11) 3234-5678');
    expect(InputMasks.applyTelefoneMask('11987654321'), '(11) 98765-4321');
  });

  test('cadastro usa tipo Profissional e nunca envia Bearer', () async {
    late http.Request sent;
    final controller = ProfessionalRegisterController(
      _api(
        MockClient((request) async {
          sent = request;
          return _json({'mensagem': 'Criado'});
        }),
      ),
    );

    expect(
      await controller.submit(
        email: ' fisio@exemplo.com ',
        password: 'senha-forte',
      ),
      isTrue,
    );
    expect(sent.url.path, '/api/auth/register');
    expect(sent.headers, isNot(contains('authorization')));
    expect(jsonDecode(sent.body), {
      'email': 'fisio@exemplo.com',
      'senha': 'senha-forte',
      'tipoUsuario': 'Profissional',
    });
  });

  test('perfil usa o ID de /auth/me e só lê dados públicos', () async {
    final paths = <String>[];
    final controller = ProfessionalProfileController(
      _api(
        MockClient((request) async {
          paths.add(request.url.path);
          expect(request.headers['authorization'], 'Bearer token-de-teste');
          expect(request.followRedirects, isFalse);
          if (request.url.path == '/api/auth/me') return _json(_session);
          return _json(_detail);
        }),
      ),
    );

    await controller.load();
    expect(paths, ['/api/auth/me', '/api/profissional/$_id']);
    expect(controller.status, ProfessionalProfileStatus.content);
    expect(controller.profile!.isPendingCompletion, isTrue);
    expect(controller.cpfInSession, isNull);
    expect(controller.birthDateInSession, isNull);
  });

  test('erros de validação ficam associados ao campo enviado', () async {
    final controller = ProfessionalProfileController(
      _api(
        MockClient((request) async {
          if (request.url.path == '/api/auth/me') return _json(_session);
          if (request.method == 'GET') return _json(_detail);
          return _json({
            'title': 'Dados inválidos',
            'errors': {
              'Cpf': ['O CPF informado é inválido.'],
            },
          }, 400);
        }),
      ),
    );
    await controller.load();

    expect(await controller.submit(_request()), isFalse);
    expect(controller.errorFor('cpf'), 'O CPF informado é inválido.');
    expect(controller.profile!.isPendingCompletion, isTrue);
  });

  test(
    'PUT confirma antes de mudar estado e preserva ativo/especialidade',
    () async {
      Map<String, dynamic>? sentBody;
      var putStatus = 409;
      final controller = ProfessionalProfileController(
        _api(
          MockClient((request) async {
            if (request.url.path == '/api/auth/me') return _json(_session);
            if (request.url.path == '/api/profissional/$_id') {
              return _json({
                ..._detail,
                'especialidade': {'id': 's1', 'nome': 'Ortopedia'},
              });
            }
            sentBody = jsonDecode(request.body) as Map<String, dynamic>;
            return putStatus == 409
                ? _json({'erro': 'CREFITO já cadastrado.'}, 409)
                : _json({'mensagem': 'Perfil atualizado com sucesso!'});
          }),
        ),
      );
      await controller.load();

      expect(await controller.submit(_request()), isFalse);
      expect(controller.profile!.isPendingCompletion, isTrue);
      expect(controller.errorFor('Crefito'), 'CREFITO já cadastrado.');
      expect(controller.cpfInSession, isNull);
      putStatus = 200;
      expect(await controller.submit(_request(crefito: 'CREFITO-456')), isTrue);
      expect(sentBody, {
        'nomeCompleto': 'Joana Silva',
        'cpf': '12345678901',
        'crefito': 'CREFITO-456',
        'telefone': '11987654321',
        'dataNascimento': '1990-05-12',
        'bio': 'Fisioterapeuta esportiva',
        'ativo': true,
      });
      expect(controller.profile!.name, 'Joana Silva');
      expect(controller.profile!.specialtyName, 'Ortopedia');
      expect(controller.cpfInSession, '12345678901');
      expect(controller.birthDateInSession, DateTime(1990, 5, 12));
    },
  );

  for (final role in ['Paciente', 'Clinica']) {
    test('$role não carrega nem altera perfil profissional', () async {
      final paths = <String>[];
      final controller = ProfessionalProfileController(
        _api(
          MockClient((request) async {
            paths.add(request.url.path);
            return _json({..._session, 'tipoUsuario': role});
          }),
        ),
      );

      await controller.load();
      expect(controller.status, ProfessionalProfileStatus.forbidden);
      expect(controller.canEdit, isFalse);
      expect(await controller.submit(_request()), isFalse);
      expect(paths, ['/api/auth/me']);
    });
  }

  testWidgets('formulário mantém dados após conflito 409', (tester) async {
    final controller = ProfessionalProfileController(
      _api(
        MockClient((request) async {
          if (request.url.path == '/api/auth/me') return _json(_session);
          if (request.url.path == '/api/profissional/$_id') {
            return _json(_detail);
          }
          return _json({'erro': 'CREFITO já cadastrado.'}, 409);
        }),
      ),
    );
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        home: ProfessionalProfileFormPage(
          controller: controller,
          onSaved: () {},
          onSessionExpired: () {},
        ),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome completo'),
      'Joana Silva',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'CPF'),
      '12345678901',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Telefone com DDD'),
      '11987654321',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'CREFITO'),
      'CREFITO-123',
    );
    await tester.ensureVisible(
      find.widgetWithText(TextFormField, 'Data de nascimento'),
    );
    await tester.tap(find.widgetWithText(TextFormField, 'Data de nascimento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salvar perfil'));
    await tester.tap(find.text('Salvar perfil'));
    await tester.pumpAndSettle();

    expect(find.text('CREFITO já cadastrado.'), findsOneWidget);
    expect(controller.profile!.isPendingCompletion, isTrue);
    expect(find.widgetWithText(TextFormField, 'CREFITO-123'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Joana Silva'), findsOneWidget);
  });

  testWidgets('formulário bloqueia acesso fora da sessão profissional', (
    tester,
  ) async {
    final controller = ProfessionalProfileController(
      _api(
        MockClient(
          (_) async => _json({..._session, 'tipoUsuario': 'Paciente'}),
        ),
      ),
    );
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        home: ProfessionalProfileFormPage(
          controller: controller,
          onSaved: () {},
          onSessionExpired: () {},
        ),
      ),
    );
    expect(find.text('Acesso restrito'), findsOneWidget);
    expect(find.text('Salvar perfil'), findsNothing);
  });

  testWidgets('perfil mostra resumo e ação de especialidade', (tester) async {
    final controller = ProfessionalProfileController(
      _api(
        MockClient(
          (request) async => request.url.path == '/api/auth/me'
              ? _json(_session)
              : _json({..._detail, 'nomeCompleto': 'Joana Silva'}),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProfessionalProfilePage(
          controller: controller,
          onLogout: () {},
          onChangeSpecialty: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Joana Silva'), findsOneWidget);
    expect(find.text('Ativo'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Alterar especialidade'), 200);
    expect(find.text('Alterar especialidade'), findsOneWidget);
  });

  testWidgets('perfil não mostra Alterar especialidade sem ação', (
    tester,
  ) async {
    final controller = ProfessionalProfileController(
      _api(
        MockClient(
          (request) async => request.url.path == '/api/auth/me'
              ? _json(_session)
              : _json({..._detail, 'nomeCompleto': 'Joana Silva'}),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProfessionalProfilePage(controller: controller, onLogout: () {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Joana Silva'), findsOneWidget);
    expect(find.text('Alterar especialidade', skipOffstage: false), findsNothing);
  });

  testWidgets('perfil e formulário cabem em 360 px com texto a 150%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ProfessionalProfileController(
      _api(
        MockClient(
          (request) async => request.url.path == '/api/auth/me'
              ? _json(_session)
              : _json({..._detail, 'nomeCompleto': 'Joana Silva'}),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: ProfessionalProfilePage(controller: controller, onLogout: () {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.widgetWithText(AppPrimaryButton, 'Editar perfil'),
      150,
    );
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Editar perfil'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.widgetWithText(AppPrimaryButton, 'Salvar perfil'),
      150,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('cadastro valida senha antes de chamar a API', (tester) async {
    var calls = 0;
    final controller = ProfessionalRegisterController(
      _api(
        MockClient((_) async {
          calls++;
          return _json({});
        }),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProfessionalRegisterPage(
          controller: controller,
          onRegistered: () {},
        ),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-mail'),
      'fisio@exemplo.com',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), '123');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar senha'),
      '123',
    );
    await tester.tap(find.text('Criar conta'));
    await tester.pump();
    expect(
      find.text('A senha precisa ter pelo menos 6 caracteres.'),
      findsOneWidget,
    );
    expect(calls, 0);
  });

  testWidgets('cadastro concluído chama navegação para login', (tester) async {
    var registered = false;
    final controller = ProfessionalRegisterController(
      _api(MockClient((_) async => _json({'mensagem': 'Criado'}))),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProfessionalRegisterPage(
          controller: controller,
          onRegistered: () => registered = true,
        ),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-mail'),
      'fisio@exemplo.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha'),
      'senha-forte',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar senha'),
      'senha-forte',
    );
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    expect(registered, isTrue);
  });
}

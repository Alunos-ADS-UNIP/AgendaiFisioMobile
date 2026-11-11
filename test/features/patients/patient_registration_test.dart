import 'dart:convert';

import 'package:agendaifisiomobile/core/network/api_client.dart';
import 'package:agendaifisiomobile/core/widgets/app_primary_button.dart';
import 'package:agendaifisiomobile/features/patients/data/patient_api.dart';
import 'package:agendaifisiomobile/features/patients/presentation/controllers/patient_register_controller.dart';
import 'package:agendaifisiomobile/features/patients/presentation/pages/patient_register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('paciente precisa aceitar os termos para criar a conta', (
    tester,
  ) async {
    var calls = 0;
    final controller = PatientRegisterController(
      PatientApi(
        ApiClient(
          baseUrl: 'https://backend.test',
          httpClient: MockClient((_) async {
            calls++;
            return _ok();
          }),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PatientRegisterPage(controller: controller, onRegistered: () {}),
      ),
    );
    await _fillForm(tester);
    final createButton = find.widgetWithText(AppPrimaryButton, 'Criar conta');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pump();

    expect(
      find.text('Aceite os Termos de Uso e a Política de Privacidade.'),
      findsOneWidget,
    );
    expect(calls, 0);
  });

  testWidgets('paciente envia o aceite LGPD explicitamente', (tester) async {
    late http.Request sent;
    var registered = false;
    final controller = PatientRegisterController(
      PatientApi(
        ApiClient(
          baseUrl: 'https://backend.test',
          httpClient: MockClient((request) async {
            sent = request;
            return _ok();
          }),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PatientRegisterPage(
          controller: controller,
          onRegistered: () => registered = true,
        ),
      ),
    );
    await _fillForm(tester);
    await tester.ensureVisible(
      find.byKey(const Key('terms-acceptance-checkbox')),
    );
    await tester.tap(find.byKey(const Key('terms-acceptance-checkbox')));
    await tester.pumpAndSettle();
    expect(find.text('Exclusão em até 90 dias'), findsOneWidget);
    expect(find.text('Aplicativo demonstrativo'), findsOneWidget);
    await tester.tap(find.byKey(const Key('accept-terms-button')));
    await tester.pumpAndSettle();
    final createButton = find.widgetWithText(AppPrimaryButton, 'Criar conta');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(registered, isTrue);
    expect(sent.url.path, '/api/auth/register');
    expect(sent.headers, isNot(contains('authorization')));
    expect(jsonDecode(sent.body), {
      'email': 'paciente@exemplo.com',
      'senha': 'senha-forte',
      'tipoUsuario': 'Paciente',
      'aceiteLgpd': true,
      'dataNascimento': '1990-05-20',
      'consentimentoResponsavelLegal': false,
      'nomeResponsavelLegal': null,
    });
  });

  testWidgets('menor de 16 anos exige e envia autorização do responsável', (
    tester,
  ) async {
    late http.Request sent;
    var calls = 0;
    final controller = PatientRegisterController(
      PatientApi(
        ApiClient(
          baseUrl: 'https://backend.test',
          httpClient: MockClient((request) async {
            calls++;
            sent = request;
            return _ok();
          }),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PatientRegisterPage(controller: controller, onRegistered: () {}),
      ),
    );

    await _fillForm(tester, birthDate: '10/11/2015');
    expect(find.textContaining('menos de 16 anos'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome completo do responsável legal'),
      'Maria Responsável',
    );
    await tester.ensureVisible(
      find.byKey(const Key('terms-acceptance-checkbox')),
    );
    await tester.tap(find.byKey(const Key('terms-acceptance-checkbox')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('accept-terms-button')));
    await tester.pumpAndSettle();

    final createButton = find.widgetWithText(AppPrimaryButton, 'Criar conta');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pump();
    expect(calls, 0);
    expect(
      find.text('A autorização do responsável legal é obrigatória.'),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const Key('guardian-consent-checkbox')),
    );
    await tester.tap(find.byKey(const Key('guardian-consent-checkbox')));
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(calls, 1);
    final body = jsonDecode(sent.body) as Map<String, dynamic>;
    expect(body['consentimentoResponsavelLegal'], isTrue);
    expect(body['nomeResponsavelLegal'], 'Maria Responsável');
    expect(body['dataNascimento'], '2015-11-10');
  });

  testWidgets('senha com 7 caracteres mostra o campo e não chama a API', (
    tester,
  ) async {
    var calls = 0;
    final controller = PatientRegisterController(
      PatientApi(
        ApiClient(
          baseUrl: 'https://backend.test',
          httpClient: MockClient((_) async {
            calls++;
            return _ok();
          }),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PatientRegisterPage(controller: controller, onRegistered: () {}),
      ),
    );
    await _fillForm(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha'),
      '1234567',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar senha'),
      '1234567',
    );
    final createButton = find.widgetWithText(AppPrimaryButton, 'Criar conta');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pump();

    expect(
      find.text('A senha precisa ter pelo menos 8 caracteres.'),
      findsOneWidget,
    );
    expect(calls, 0);
  });

  testWidgets('erros da API aparecem nos campos e somem ao corrigir', (
    tester,
  ) async {
    final controller = PatientRegisterController(
      PatientApi(
        ApiClient(
          baseUrl: 'https://backend.test',
          httpClient: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'title': 'Corrija os campos indicados.',
                'errors': {
                  'Email': ['Este e-mail já está cadastrado.'],
                  r'$.dataNascimento': [
                    'Revise a data de nascimento informada.',
                  ],
                  'Senha': ['A senha foi recusada pelo servidor.'],
                },
              }),
              400,
              headers: {'content-type': 'application/json; charset=utf-8'},
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PatientRegisterPage(controller: controller, onRegistered: () {}),
      ),
    );
    await _fillForm(tester);
    await _acceptTerms(tester);
    final createButton = find.widgetWithText(AppPrimaryButton, 'Criar conta');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text('Este e-mail já está cadastrado.'), findsOneWidget);
    expect(find.text('Revise a data de nascimento informada.'), findsOneWidget);
    expect(find.text('A senha foi recusada pelo servidor.'), findsOneWidget);
    expect(
      find.text('Revise os campos destacados abaixo e tente novamente.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-mail'),
      'novo@exemplo.com',
    );
    await tester.pump();
    expect(find.text('Este e-mail já está cadastrado.'), findsNothing);
    expect(find.text('A senha foi recusada pelo servidor.'), findsOneWidget);
  });

  testWidgets('cadastro cabe em 320 px com texto ampliado a 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = PatientRegisterController(
      PatientApi(
        ApiClient(
          baseUrl: 'https://backend.test',
          httpClient: MockClient((_) async => _ok()),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: PatientRegisterPage(controller: controller, onRegistered: () {}),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -1600),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _fillForm(
  WidgetTester tester, {
  String birthDate = '20/05/1990',
}) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'E-mail'),
    'paciente@exemplo.com',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Data de nascimento'),
    birthDate,
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Senha'),
    'senha-forte',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Confirmar senha'),
    'senha-forte',
  );
}

Future<void> _acceptTerms(WidgetTester tester) async {
  final checkbox = find.byKey(const Key('terms-acceptance-checkbox'));
  await tester.ensureVisible(checkbox);
  await tester.tap(checkbox);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('accept-terms-button')));
  await tester.pumpAndSettle();
}

http.Response _ok() => http.Response(
  jsonEncode({'mensagem': 'Criado'}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

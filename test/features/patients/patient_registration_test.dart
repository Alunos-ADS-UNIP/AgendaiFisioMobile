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
    await tester.tap(find.byKey(const Key('terms-acceptance-checkbox')));
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
    });
  });
}

Future<void> _fillForm(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'E-mail'),
    'paciente@exemplo.com',
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

http.Response _ok() => http.Response(
  jsonEncode({'mensagem': 'Criado'}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

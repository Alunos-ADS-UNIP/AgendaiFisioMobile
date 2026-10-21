import 'dart:async';

import 'package:agendaifisiomobile/core/network/api_client.dart';
import 'package:agendaifisiomobile/core/theme/app_theme.dart';
import 'package:agendaifisiomobile/features/patients/data/patient_api.dart';
import 'package:agendaifisiomobile/features/patients/data/viacep_client.dart';
import 'package:agendaifisiomobile/features/patients/domain/patient.dart';
import 'package:agendaifisiomobile/features/patients/presentation/controllers/patient_profile_form_controller.dart';
import 'package:agendaifisiomobile/features/patients/presentation/pages/patient_profile_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _blankPatient = Patient(
  nomeCompleto: 'Cadastro Pendente',
  cpf: '',
  telefone: '',
  dataNascimento: null,
  sexo: '',
  estadoCivil: '',
  endereco: PatientAddress(),
  email: 'paciente@exemplo.com',
);

const _se = ViaCepAddress(
  rua: 'Praça da Sé',
  bairro: 'Sé',
  cidade: 'São Paulo',
  estado: 'SP',
);

PatientProfileFormController _controller() => PatientProfileFormController(
  PatientApi(
    ApiClient(
      baseUrl: 'http://backend.test',
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    ),
  ),
);

Widget _page(
  Patient patient, {
  Future<ViaCepAddress> Function(String cep)? cepLookup,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: PatientProfileFormPage(
      controller: _controller(),
      currentPatient: patient,
      onSaved: () {},
      cepLookup: cepLookup,
    ),
  );
}

/// Tela alta o bastante para o formulário inteiro caber sem rolagem.
void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

String _textOf(WidgetTester tester, String label) =>
    tester.widget<TextFormField>(_field(label)).controller!.text;

void main() {
  group('dropdowns de sexo e estado civil', () {
    testWidgets('valor da API fora da lista de opções não quebra a tela', (
      tester,
    ) async {
      _useTallScreen(tester);
      const patient = Patient(
        nomeCompleto: 'João Teste',
        cpf: '12345678901',
        telefone: '11987654321',
        dataNascimento: null,
        sexo: 'feminino', // minúscula: não bate com 'Feminino'
        estadoCivil: 'Casado', // sem o "(a)": não bate com 'Casado(a)'
        endereco: PatientAddress(),
        email: 'joao@exemplo.com',
      );

      await tester.pumpWidget(_page(patient));

      expect(tester.takeException(), isNull);
      expect(find.text('feminino'), findsOneWidget);
      expect(find.text('Casado'), findsOneWidget);
    });

    testWidgets('valor que está nas opções continua funcionando', (
      tester,
    ) async {
      _useTallScreen(tester);
      const patient = Patient(
        nomeCompleto: 'Mariana',
        cpf: '',
        telefone: '',
        dataNascimento: null,
        sexo: 'Feminino',
        estadoCivil: 'Solteiro(a)',
        endereco: PatientAddress(),
        email: 'm@exemplo.com',
      );

      await tester.pumpWidget(_page(patient));

      expect(tester.takeException(), isNull);
      expect(find.text('Feminino'), findsOneWidget);
      expect(find.text('Solteiro(a)'), findsOneWidget);
    });
  });

  group('preenchimento de endereço pelo CEP (ViaCEP)', () {
    testWidgets('CEP completo preenche rua, bairro, cidade e estado', (
      tester,
    ) async {
      _useTallScreen(tester);
      final requestedCeps = <String>[];
      await tester.pumpWidget(
        _page(
          _blankPatient,
          cepLookup: (cep) async {
            requestedCeps.add(cep);
            return _se;
          },
        ),
      );

      await tester.enterText(_field('CEP'), '01001000');
      await tester.pumpAndSettle();

      expect(requestedCeps, ['01001000']);
      expect(_textOf(tester, 'CEP'), '01001-000');
      expect(_textOf(tester, 'Rua'), 'Praça da Sé');
      expect(_textOf(tester, 'Bairro'), 'Sé');
      expect(_textOf(tester, 'Cidade'), 'São Paulo');
      expect(_textOf(tester, 'Estado'), 'SP');
    });

    testWidgets('não mexe em número e complemento', (tester) async {
      _useTallScreen(tester);
      await tester.pumpWidget(
        _page(_blankPatient, cepLookup: (_) async => _se),
      );

      await tester.enterText(_field('Número'), '100');
      await tester.enterText(_field('Complemento'), 'Apto 12');
      await tester.enterText(_field('CEP'), '01001000');
      await tester.pumpAndSettle();

      expect(_textOf(tester, 'Número'), '100');
      expect(_textOf(tester, 'Complemento'), 'Apto 12');
    });

    testWidgets('os campos continuam editáveis depois do preenchimento', (
      tester,
    ) async {
      _useTallScreen(tester);
      await tester.pumpWidget(
        _page(_blankPatient, cepLookup: (_) async => _se),
      );

      await tester.enterText(_field('CEP'), '01001000');
      await tester.pumpAndSettle();
      await tester.enterText(_field('Rua'), 'Rua Corrigida à mão');
      await tester.pump();

      expect(_textOf(tester, 'Rua'), 'Rua Corrigida à mão');
    });

    testWidgets('resposta sem rua mantém a rua já digitada', (tester) async {
      _useTallScreen(tester);
      await tester.pumpWidget(
        _page(
          _blankPatient,
          cepLookup: (_) async => const ViaCepAddress(
            rua: '',
            bairro: '',
            cidade: 'Atibaia',
            estado: 'SP',
          ),
        ),
      );

      await tester.enterText(_field('Rua'), 'Rua que eu já digitei');
      await tester.enterText(_field('CEP'), '12940000');
      await tester.pumpAndSettle();

      expect(_textOf(tester, 'Rua'), 'Rua que eu já digitei');
      expect(_textOf(tester, 'Cidade'), 'Atibaia');
    });

    testWidgets('mostra indicador de carregamento durante a consulta', (
      tester,
    ) async {
      _useTallScreen(tester);
      final pending = Completer<ViaCepAddress>();
      await tester.pumpWidget(
        _page(_blankPatient, cepLookup: (_) => pending.future),
      );

      await tester.enterText(_field('CEP'), '01001000');
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      pending.complete(_se);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_textOf(tester, 'Rua'), 'Praça da Sé');
    });

    testWidgets('CEP inexistente avisa e permite preencher à mão', (
      tester,
    ) async {
      _useTallScreen(tester);
      await tester.pumpWidget(
        _page(
          _blankPatient,
          cepLookup: (_) async =>
              throw const CepLookupException(CepLookupFailure.notFound),
        ),
      );

      await tester.enterText(_field('CEP'), '99999999');
      await tester.pumpAndSettle();

      expect(find.textContaining('CEP não encontrado'), findsOneWidget);
      await tester.enterText(_field('Rua'), 'Rua Manual');
      await tester.pump();
      expect(_textOf(tester, 'Rua'), 'Rua Manual');
    });

    testWidgets('timeout avisa e permite preencher à mão', (tester) async {
      _useTallScreen(tester);
      await tester.pumpWidget(
        _page(
          _blankPatient,
          cepLookup: (_) async =>
              throw const CepLookupException(CepLookupFailure.timeout),
        ),
      );

      await tester.enterText(_field('CEP'), '01001000');
      await tester.pumpAndSettle();

      expect(find.textContaining('demorou demais'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('falha de rede avisa sem travar o formulário', (tester) async {
      _useTallScreen(tester);
      await tester.pumpWidget(
        _page(
          _blankPatient,
          cepLookup: (_) async =>
              throw const CepLookupException(CepLookupFailure.network),
        ),
      );

      await tester.enterText(_field('CEP'), '01001000');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Não foi possível consultar o CEP'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('resposta de consulta antiga é descartada', (tester) async {
      _useTallScreen(tester);
      final first = Completer<ViaCepAddress>();
      await tester.pumpWidget(
        _page(_blankPatient, cepLookup: (_) => first.future),
      );

      await tester.enterText(_field('CEP'), '01001000');
      await tester.pump();
      // Usuário apaga um dígito antes da resposta chegar.
      await tester.enterText(_field('CEP'), '0100100');
      await tester.pump();

      first.complete(_se);
      await tester.pumpAndSettle();

      expect(_textOf(tester, 'Rua'), isEmpty);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('CEP já salvo não dispara consulta ao abrir a tela', (
      tester,
    ) async {
      _useTallScreen(tester);
      var calls = 0;
      const patient = Patient(
        nomeCompleto: 'Mariana',
        cpf: '',
        telefone: '',
        dataNascimento: null,
        sexo: '',
        estadoCivil: '',
        endereco: PatientAddress(cep: '01001000', rua: 'Rua Salva'),
        email: 'm@exemplo.com',
      );

      await tester.pumpWidget(
        _page(
          patient,
          cepLookup: (_) async {
            calls++;
            return _se;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(calls, 0);
      expect(_textOf(tester, 'CEP'), '01001-000');
      expect(_textOf(tester, 'Rua'), 'Rua Salva');
    });
  });
}

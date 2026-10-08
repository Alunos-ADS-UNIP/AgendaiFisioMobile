import 'package:agendaifisiomobile/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe os campos e ações da tela de login', (tester) async {
    await tester.pumpWidget(const AgendaiFisioApp());

    expect(find.text('Agendai Fisio'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}

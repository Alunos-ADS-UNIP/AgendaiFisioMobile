import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// O aceite só é marcado depois que a pessoa abre o modal e confirma a leitura.
class TermsAcceptanceField extends FormField<bool> {
  TermsAcceptanceField({
    required super.enabled,
    bool initialValue = false,
    String? errorText,
    ValueChanged<bool>? onChanged,
    super.key,
  }) : super(
         initialValue: initialValue,
         autovalidateMode: AutovalidateMode.onUserInteraction,
         validator: (value) {
           if (errorText != null) return errorText;
           return value == true
               ? null
               : 'Aceite os Termos de Uso e a Política de Privacidade.';
         },
         builder: (field) {
           Future<void> openTerms() async {
             final accepted = await showDialog<bool>(
               context: field.context,
               builder: (context) => const _TermsDialog(),
             );
             if (accepted == true) {
               field.didChange(true);
               onChanged?.call(true);
             }
           }

           final visibleError = errorText ?? field.errorText;

           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               CheckboxListTile(
                 key: const ValueKey('terms-acceptance-checkbox'),
                 value: field.value ?? false,
                 onChanged: !field.widget.enabled
                     ? null
                     : (value) {
                         if (value == false) {
                           field.didChange(false);
                           onChanged?.call(false);
                         } else {
                           openTerms();
                         }
                       },
                 controlAffinity: ListTileControlAffinity.leading,
                 contentPadding: EdgeInsets.zero,
                 title: const Text(
                   'Li e aceito os Termos de Uso e a Política de Privacidade.',
                 ),
                 subtitle: Align(
                   alignment: Alignment.centerLeft,
                   child: TextButton(
                     key: const ValueKey('open-terms-button'),
                     onPressed: field.widget.enabled ? openTerms : null,
                     child: const Text('Ler os termos completos'),
                   ),
                 ),
               ),
               if (visibleError != null)
                 Semantics(
                   liveRegion: true,
                   child: Padding(
                     padding: const EdgeInsets.only(left: AppSpacing.md),
                     child: Text(
                       visibleError,
                       style: TextStyle(
                         color: Theme.of(field.context).colorScheme.error,
                       ),
                     ),
                   ),
                 ),
             ],
           );
         },
       );
}

class _TermsDialog extends StatelessWidget {
  const _TermsDialog();

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Termos de Uso e Privacidade'),
    content: const SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TermsSection(
              title: 'Aplicativo demonstrativo',
              body:
                  'O AgendaiFisio é um projeto acadêmico usado somente para demonstração. '
                  'Ele não substitui atendimento, diagnóstico ou orientação de um profissional de saúde.',
            ),
            _TermsSection(
              title: 'Dados utilizados',
              body:
                  'O app usa os dados fornecidos no cadastro e no perfil para autenticação, '
                  'exibição de profissionais e demonstração de agendamentos. Não informe dados '
                  'clínicos reais ou informações que não sejam necessárias para testar o aplicativo.',
            ),
            _TermsSection(
              title: 'Exclusão em até 90 dias',
              body:
                  'Por segurança, a conta e os dados relacionados serão apagados automaticamente '
                  'após 90 dias da criação. Como o ambiente é demonstrativo, os dados também podem '
                  'ser removidos antes desse prazo durante reinicializações ou manutenção.',
            ),
            _TermsSection(
              title: 'Pacientes menores de 16 anos',
              body:
                  'O cadastro de paciente menor de 16 anos só pode ser feito com autorização '
                  'expressa de pai, mãe ou responsável legal, que deve se identificar no formulário.',
            ),
            _TermsSection(
              title: 'Aceite',
              body:
                  'Ao continuar, você declara que leu estas condições, concorda com o uso '
                  'demonstrativo dos dados e está ciente do prazo de exclusão.',
            ),
            Text('Versão dos termos: 10/11/2026'),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Agora não'),
      ),
      FilledButton(
        key: const ValueKey('accept-terms-button'),
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Li e aceito'),
      ),
    ],
  );
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(body),
      ],
    ),
  );
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../controllers/professional_register_controller.dart';

/// Cria a conta; a sessão compartilhada conduz o login antes de completar o
/// perfil, pois o cadastro não devolve um token.
class ProfessionalRegisterPage extends StatefulWidget {
  const ProfessionalRegisterPage({
    required this.controller,
    required this.onRegistered,
    this.onGoToLogin,
    super.key,
  });

  final ProfessionalRegisterController controller;
  final VoidCallback onRegistered;
  final VoidCallback? onGoToLogin;

  @override
  State<ProfessionalRegisterPage> createState() =>
      _ProfessionalRegisterPageState();
}

class _ProfessionalRegisterPageState extends State<ProfessionalRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _submit() async {
    if (widget.controller.isSubmitting ||
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final created = await widget.controller.submit(
      email: _email.text.trim(),
      password: _password.text,
    );
    if (created && mounted) widget.onRegistered();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Criar conta profissional')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cadastro de fisioterapeuta',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Depois de criar a conta, entre para completar seu perfil.',
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'E-mail',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                enabled: !widget.controller.isSubmitting,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Informe seu e-mail.';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    return 'E-mail inválido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Senha',
                controller: _password,
                obscureText: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                enabled: !widget.controller.isSubmitting,
                validator: (value) => (value?.length ?? 0) < 6
                    ? 'A senha precisa ter pelo menos 6 caracteres.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Confirmar senha',
                controller: _confirmation,
                obscureText: true,
                textInputAction: TextInputAction.done,
                enabled: !widget.controller.isSubmitting,
                onSubmitted: (_) => _submit(),
                validator: (value) =>
                    value != _password.text ? 'As senhas não coincidem.' : null,
              ),
              if (widget.controller.error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.controller.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: 'Criar conta',
                onPressed: _submit,
                isLoading: widget.controller.isSubmitting,
              ),
              if (widget.onGoToLogin != null) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: widget.controller.isSubmitting
                      ? null
                      : widget.onGoToLogin,
                  child: const Text('Já tenho uma conta'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

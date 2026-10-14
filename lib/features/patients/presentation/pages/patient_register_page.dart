import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../controllers/patient_register_controller.dart';

/// Tela de cadastro de conta de Paciente.
/// POST /api/auth/register com tipoUsuario "Paciente".
class PatientRegisterPage extends StatefulWidget {
  const PatientRegisterPage({
    required this.controller,
    required this.onRegistered,
    this.onGoToLogin,
    super.key,
  });

  final PatientRegisterController controller;

  /// Chamado após o cadastro ter sucesso. Normalmente deve levar para a
  /// tela de login (o Jonas ainda não logou automaticamente o usuário
  /// recém-criado — o fluxo de sessão é dele).
  final VoidCallback onRegistered;

  final VoidCallback? onGoToLogin;

  @override
  State<PatientRegisterPage> createState() => _PatientRegisterPageState();
}

class _PatientRegisterPageState extends State<PatientRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await widget.controller.submit(
      email: _emailController.text.trim(),
      senha: _senhaController.text,
    );

    if (success && mounted) {
      widget.onRegistered();
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Informe seu e-mail.';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(email)) return 'E-mail inválido.';
    return null;
  }

  String? _validateSenha(String? value) {
    final senha = value ?? '';
    if (senha.isEmpty) return 'Informe uma senha.';
    if (senha.length < 6) return 'A senha precisa ter pelo menos 6 caracteres.';
    return null;
  }

  String? _validateConfirmarSenha(String? value) {
    if (value != _senhaController.text) return 'As senhas não coincidem.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Crie sua conta de paciente',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Depois do cadastro, você completa seus dados pessoais no perfil.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'E-mail',
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: _validateEmail,
                  enabled: !controller.isSubmitting,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Senha',
                  controller: _senhaController,
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: _validateSenha,
                  enabled: !controller.isSubmitting,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Confirmar senha',
                  controller: _confirmarSenhaController,
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: _validateConfirmarSenha,
                  onSubmitted: (_) => _submit(),
                  enabled: !controller.isSubmitting,
                ),
                if (controller.generalError != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _InlineErrorBanner(
                    message: controller.generalError!,
                    actionLabel: controller.emailJaCadastrado ? 'Já tenho conta' : null,
                    onAction: controller.emailJaCadastrado ? widget.onGoToLogin : null,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppPrimaryButton(
                  label: 'Criar conta',
                  isLoading: controller.isSubmitting,
                  onPressed: _submit,
                ),
                if (widget.onGoToLogin != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: controller.isSubmitting ? null : widget.onGoToLogin,
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
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: TextStyle(color: colorScheme.error)),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

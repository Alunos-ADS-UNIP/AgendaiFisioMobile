import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/terms_acceptance_field.dart';
import '../../../auth/presentation/widgets/registration_layout.dart';
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
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmationFocus = FocusNode();
  final _emailKey = GlobalKey();
  final _passwordKey = GlobalKey();
  final _confirmationKey = GlobalKey();
  final _termsKey = GlobalKey<FormFieldState<bool>>();
  bool _termsAccepted = false;
  bool _showValidationMessage = false;

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
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmationFocus.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (widget.controller.isSubmitting) {
      return;
    }
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      setState(() => _showValidationMessage = true);
      _revealFirstLocalError();
      return;
    }
    if (_showValidationMessage) {
      setState(() => _showValidationMessage = false);
    }
    final created = await widget.controller.submit(
      email: _email.text.trim(),
      password: _password.text,
      aceiteLgpd: _termsAccepted,
    );
    if (created && mounted) {
      widget.onRegistered();
    } else if (mounted) {
      setState(() => _showValidationMessage = true);
      _revealFirstServerError();
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Informe seu e-mail.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'E-mail inválido.';
    }
    return null;
  }

  String? _validatePassword(String? value) => (value?.length ?? 0) < 8
      ? 'A senha precisa ter pelo menos 8 caracteres.'
      : null;

  void _onFieldChanged(String field) {
    widget.controller.clearFieldError(field);
    if (_showValidationMessage && mounted) {
      setState(() => _showValidationMessage = false);
    }
  }

  void _onTermsChanged(bool value) {
    _termsAccepted = value;
    _onFieldChanged('aceiteLgpd');
  }

  void _reveal(GlobalKey key, [FocusNode? focusNode]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      focusNode?.requestFocus();
      final fieldContext = key.currentContext;
      if (fieldContext != null) {
        Scrollable.ensureVisible(
          fieldContext,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: 0.18,
        );
      }
    });
  }

  void _revealFirstLocalError() {
    if (_validateEmail(_email.text) != null) {
      _reveal(_emailKey, _emailFocus);
    } else if (_validatePassword(_password.text) != null) {
      _reveal(_passwordKey, _passwordFocus);
    } else if (_confirmation.text != _password.text) {
      _reveal(_confirmationKey, _confirmationFocus);
    } else if (!_termsAccepted) {
      _reveal(_termsKey);
    }
  }

  void _revealFirstServerError() {
    final errors = widget.controller.fieldErrors;
    if (errors.containsKey('email')) {
      _reveal(_emailKey, _emailFocus);
    } else if (errors.containsKey('senha')) {
      _reveal(_passwordKey, _passwordFocus);
    } else if (errors.containsKey('aceiteLgpd')) {
      _reveal(_termsKey);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Criar conta profissional')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: RegistrationLayout(
          title: 'Cadastro de fisioterapeuta',
          description: 'Crie seus dados de acesso. Depois, entre para completar seu perfil profissional.',
          children: [
            if (_showValidationMessage || widget.controller.error != null) ...[
              RegistrationMessage(
                message: widget.controller.error ?? 'Revise os campos marcados e corrija as informações antes de continuar.',
                isError: true,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            RegistrationSection(
              title: 'Dados da conta',
              description:
                  'Informe um e-mail válido para acessar o aplicativo.',
              children: [
                AppTextField(
                  key: _emailKey,
                  label: 'E-mail',
                  prefixIcon: Icons.email_outlined,
                  controller: _email,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  enabled: !widget.controller.isSubmitting,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: _validateEmail,
                  errorText: widget.controller.fieldError('email'),
                  highlightError: widget.controller.fieldError('email') != null,
                  onChanged: (_) => _onFieldChanged('email'),
                ),
              ],
            ),
            RegistrationSection(
              title: 'Crie uma senha',
              description: 'Use uma senha que você consiga lembrar e não compartilhe com outras pessoas.',
              children: [
                AppTextField(
                  key: _passwordKey,
                  label: 'Senha',
                  prefixIcon: Icons.lock_outline,
                  controller: _password,
                  focusNode: _passwordFocus,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !widget.controller.isSubmitting,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: _validatePassword,
                  errorText: widget.controller.fieldError('senha'),
                  highlightError: widget.controller.fieldError('senha') != null,
                  onChanged: (_) => _onFieldChanged('senha'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  key: _confirmationKey,
                  label: 'Confirmar senha',
                  prefixIcon: Icons.lock_outline,
                  controller: _confirmation,
                  focusNode: _confirmationFocus,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  enabled: !widget.controller.isSubmitting,
                  onSubmitted: (_) => _submit(),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) => value != _password.text
                      ? 'As senhas não coincidem.'
                      : null,
                  onChanged: (_) {
                    if (_showValidationMessage) {
                      setState(() => _showValidationMessage = false);
                    }
                  },
                ),
              ],
            ),
            RegistrationSection(
              title: 'Termos e privacidade',
              description: 'Abra os termos completos para conhecer o uso e o prazo de exclusão dos dados.',
              children: [
                TermsAcceptanceField(
                  key: _termsKey,
                  enabled: !widget.controller.isSubmitting,
                  initialValue: _termsAccepted,
                  errorText: widget.controller.fieldError('aceiteLgpd'),
                  onChanged: _onTermsChanged,
                ),
              ],
            ),
            SizedBox(
              height: 56,
              child: AppPrimaryButton(
                label: 'Criar conta',
                onPressed: _submit,
                isLoading: widget.controller.isSubmitting,
              ),
            ),
            if (widget.onGoToLogin != null) ...[
              const SizedBox(height: AppSpacing.lg),
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
  );
}

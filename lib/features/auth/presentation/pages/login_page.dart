import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../controllers/session_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    required this.controller,
    required this.onCreateAccount,
    super.key,
  });

  final SessionController controller;
  final VoidCallback onCreateAccount;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.controller.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Informe seu e-mail.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Digite um e-mail válido.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Informe sua senha.';
    if (value.length < 6) return 'A senha precisa ter pelo menos 6 caracteres.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.controller.status == SessionStatus.authenticating;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: _LoginBackground()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (AppSpacing.lg * 2),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _BrandHeader(),
                            const SizedBox(height: AppSpacing.xl),
                            _LoginCard(
                              formKey: _formKey,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              showPassword: _showPassword,
                              isLoading: isLoading,
                              errorMessage: widget.controller.errorMessage,
                              sessionExpired: widget.controller.sessionExpired,
                              validateEmail: _validateEmail,
                              validatePassword: _validatePassword,
                              onTogglePassword: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                              onChanged: (_) => widget.controller.clearError(),
                              onSubmit: _submit,
                              onCreateAccount: widget.onCreateAccount,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const _SecurityNote(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0, 0.44, 1],
        colors: [Color(0xFF0B5F59), AppColors.primary, AppColors.background],
      ),
    ),
  );
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.health_and_safety_rounded,
          color: AppColors.primary,
          size: 40,
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        'AgendaiFisio',
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(color: Colors.white, fontSize: 28),
      ),
      const SizedBox(height: AppSpacing.xxs),
      Text(
        'Seu cuidado, no seu tempo.',
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: Colors.white.withValues(alpha: 0.88)),
      ),
    ],
  );
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.showPassword,
    required this.isLoading,
    required this.errorMessage,
    required this.sessionExpired,
    required this.validateEmail,
    required this.validatePassword,
    required this.onTogglePassword,
    required this.onChanged,
    required this.onSubmit,
    required this.onCreateAccount,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool showPassword;
  final bool isLoading;
  final String? errorMessage;
  final bool sessionExpired;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;
  final VoidCallback onTogglePassword;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A0F172A),
          blurRadius: 30,
          offset: Offset(0, 14),
        ),
      ],
    ),
    child: AutofillGroup(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Boas-vindas',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Entre para gerenciar seus atendimentos.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            if (sessionExpired) ...[
              const SizedBox(height: AppSpacing.md),
              const _SessionExpiredNotice(),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              key: const Key('login-email'),
              label: 'E-mail',
              hint: 'seuemail@exemplo.com',
              controller: emailController,
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              validator: validateEmail,
              onChanged: onChanged,
              enabled: !isLoading,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const Key('login-password'),
              label: 'Senha',
              controller: passwordController,
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                tooltip: showPassword ? 'Ocultar senha' : 'Mostrar senha',
                onPressed: isLoading ? null : onTogglePassword,
                icon: Icon(
                  showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
              obscureText: !showPassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: validatePassword,
              onChanged: onChanged,
              onSubmitted: (_) => onSubmit(),
              enabled: !isLoading,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              _LoginError(message: errorMessage!),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Entrar',
              icon: Icons.login_rounded,
              isLoading: isLoading,
              onPressed: onSubmit,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Flexible(child: Text('Ainda não tem conta?')),
                TextButton(
                  onPressed: isLoading ? null : onCreateAccount,
                  child: const Text('Criar conta'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _SessionExpiredNotice extends StatelessWidget {
  const _SessionExpiredNotice();

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      key: const Key('session-expired-notice'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: AppRadius.medium,
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_clock_outlined, color: AppColors.primary),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Sua sessão expirou. Entre novamente para continuar.',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    ),
  );
}

class _LoginError extends StatelessWidget {
  const _LoginError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: AppRadius.medium,
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.lock_outline,
        size: 16,
        color: Colors.white.withValues(alpha: 0.8),
      ),
      const SizedBox(width: AppSpacing.xs),
      Flexible(
        child: Text(
          'Sua sessão é armazenada com segurança neste dispositivo.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Colors.white.withValues(alpha: 0.86)),
        ),
      ),
    ],
  );
}

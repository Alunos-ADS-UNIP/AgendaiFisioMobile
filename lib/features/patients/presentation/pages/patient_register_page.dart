import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_masks.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/terms_acceptance_field.dart';
import '../../../auth/presentation/widgets/registration_layout.dart';
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
  final _dataNascimentoController = TextEditingController();
  final _nomeResponsavelController = TextEditingController();
  final _emailFocus = FocusNode();
  final _dataNascimentoFocus = FocusNode();
  final _nomeResponsavelFocus = FocusNode();
  final _senhaFocus = FocusNode();
  final _confirmarSenhaFocus = FocusNode();
  final _emailKey = GlobalKey();
  final _dataNascimentoKey = GlobalKey();
  final _nomeResponsavelKey = GlobalKey();
  final _consentimentoKey = GlobalKey<FormFieldState<bool>>();
  final _senhaKey = GlobalKey();
  final _confirmarSenhaKey = GlobalKey();
  final _termosKey = GlobalKey<FormFieldState<bool>>();
  DateTime? _dataNascimento;
  bool _autorizacaoResponsavel = false;
  bool _aceiteLgpd = false;
  bool _showValidationMessage = false;

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
    _dataNascimentoController.dispose();
    _nomeResponsavelController.dispose();
    _emailFocus.dispose();
    _dataNascimentoFocus.dispose();
    _nomeResponsavelFocus.dispose();
    _senhaFocus.dispose();
    _confirmarSenhaFocus.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (widget.controller.isSubmitting) return;
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      setState(() => _showValidationMessage = true);
      _revealFirstLocalError();
      return;
    }

    if (_showValidationMessage) {
      setState(() => _showValidationMessage = false);
    }

    final success = await widget.controller.submit(
      email: _emailController.text.trim(),
      senha: _senhaController.text,
      aceiteLgpd: _aceiteLgpd,
      dataNascimento: _dataNascimento!,
      consentimentoResponsavelLegal: _menorDe16 && _autorizacaoResponsavel,
      nomeResponsavelLegal: _menorDe16
          ? _nomeResponsavelController.text.trim()
          : null,
    );

    if (success && mounted) {
      widget.onRegistered();
    } else if (mounted) {
      setState(() => _showValidationMessage = true);
      _revealFirstServerError();
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
    if (senha.length < 8) return 'A senha precisa ter pelo menos 8 caracteres.';
    return null;
  }

  String? _validateConfirmarSenha(String? value) {
    if (value != _senhaController.text) return 'As senhas não coincidem.';
    return null;
  }

  bool get _menorDe16 {
    final nascimento = _dataNascimento;
    if (nascimento == null) return false;
    final hoje = DateTime.now();
    var idade = hoje.year - nascimento.year;
    if (nascimento.isAfter(DateTime(hoje.year - idade, hoje.month, hoje.day))) {
      idade--;
    }
    return idade < 16;
  }

  void _onNascimentoChanged(String value) {
    final parsed = InputMasks.parseDate(value);
    widget.controller.clearFieldError('dataNascimento');
    setState(() {
      _showValidationMessage = false;
      _dataNascimento = parsed;
      if (!_menorDe16) {
        _autorizacaoResponsavel = false;
        _nomeResponsavelController.clear();
      }
    });
  }

  String? _validateNascimento(String? value) {
    final nascimento = InputMasks.parseDate(value ?? '');
    if (nascimento == null) {
      return 'Informe uma data válida no formato DD/MM/AAAA.';
    }
    final hoje = DateTime.now();
    if (nascimento.isAfter(hoje) ||
        nascimento.isBefore(DateTime(hoje.year - 130))) {
      return 'Informe uma data de nascimento válida.';
    }
    return null;
  }

  void _onFieldChanged(String field) {
    widget.controller.clearFieldError(field);
    if (_showValidationMessage && mounted) {
      setState(() => _showValidationMessage = false);
    }
  }

  void _onTermsChanged(bool value) {
    _aceiteLgpd = value;
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
    if (_validateEmail(_emailController.text) != null) {
      _reveal(_emailKey, _emailFocus);
    } else if (_validateNascimento(_dataNascimentoController.text) != null) {
      _reveal(_dataNascimentoKey, _dataNascimentoFocus);
    } else if (_menorDe16 && _nomeResponsavelController.text.trim().isEmpty) {
      _reveal(_nomeResponsavelKey, _nomeResponsavelFocus);
    } else if (_menorDe16 && !_autorizacaoResponsavel) {
      _reveal(_consentimentoKey);
    } else if (_validateSenha(_senhaController.text) != null) {
      _reveal(_senhaKey, _senhaFocus);
    } else if (_validateConfirmarSenha(_confirmarSenhaController.text) !=
        null) {
      _reveal(_confirmarSenhaKey, _confirmarSenhaFocus);
    } else if (!_aceiteLgpd) {
      _reveal(_termosKey);
    }
  }

  void _revealFirstServerError() {
    final errors = widget.controller.fieldErrors;
    if (errors.containsKey('email')) {
      _reveal(_emailKey, _emailFocus);
    } else if (errors.containsKey('dataNascimento')) {
      _reveal(_dataNascimentoKey, _dataNascimentoFocus);
    } else if (errors.containsKey('nomeResponsavelLegal')) {
      _reveal(_nomeResponsavelKey, _nomeResponsavelFocus);
    } else if (errors.containsKey('consentimentoResponsavelLegal')) {
      _reveal(_consentimentoKey);
    } else if (errors.containsKey('senha')) {
      _reveal(_senhaKey, _senhaFocus);
    } else if (errors.containsKey('aceiteLgpd')) {
      _reveal(_termosKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: RegistrationLayout(
            title: 'Crie sua conta de paciente',
            description: 'Preencha os dados abaixo. Depois do cadastro, você completa seu perfil.',
            children: [
              if (_showValidationMessage ||
                  controller.generalError != null) ...[
                RegistrationMessage(
                  message: controller.generalError ?? 'Revise os campos marcados e corrija as informações antes de continuar.',
                  isError: true,
                  actionLabel: controller.emailJaCadastrado
                      ? 'Já tenho conta'
                      : null,
                  onAction: controller.emailJaCadastrado
                      ? widget.onGoToLogin
                      : null,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              RegistrationSection(
                title: 'Dados da conta',
                description:
                    'Informe um e-mail válido e sua data de nascimento.',
                children: [
                  AppTextField(
                    key: _emailKey,
                    label: 'E-mail',
                    controller: _emailController,
                    focusNode: _emailFocus,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: _validateEmail,
                    errorText: controller.fieldError('email'),
                    highlightError: controller.fieldError('email') != null,
                    onChanged: (_) => _onFieldChanged('email'),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    enabled: !controller.isSubmitting,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    key: _dataNascimentoKey,
                    label: 'Data de nascimento',
                    hint: 'DD/MM/AAAA',
                    controller: _dataNascimentoController,
                    focusNode: _dataNascimentoFocus,
                    prefixIcon: Icons.cake_outlined,
                    keyboardType: TextInputType.datetime,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [InputMasks.dataFormatter()],
                    onChanged: _onNascimentoChanged,
                    validator: _validateNascimento,
                    errorText: controller.fieldError('dataNascimento'),
                    highlightError:
                        controller.fieldError('dataNascimento') != null,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    enabled: !controller.isSubmitting,
                  ),
                ],
              ),
              if (_menorDe16) ...[
                RegistrationSection(
                  title: 'Autorização do responsável',
                  children: [
                    const RegistrationMessage(
                      message: 'Para pacientes com menos de 16 anos, pai, mãe ou responsável legal precisa autorizar o cadastro.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      key: _nomeResponsavelKey,
                      label: 'Nome completo do responsável legal',
                      controller: _nomeResponsavelController,
                      focusNode: _nomeResponsavelFocus,
                      prefixIcon: Icons.supervisor_account_outlined,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Informe o nome do responsável legal.'
                          : null,
                      errorText: controller.fieldError('nomeResponsavelLegal'),
                      highlightError:
                          controller.fieldError('nomeResponsavelLegal') != null,
                      onChanged: (_) => _onFieldChanged('nomeResponsavelLegal'),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      enabled: !controller.isSubmitting,
                    ),
                    FormField<bool>(
                      key: _consentimentoKey,
                      initialValue: false,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (_) {
                        final serverError = controller.fieldError(
                          'consentimentoResponsavelLegal',
                        );
                        if (serverError != null) return serverError;
                        return _autorizacaoResponsavel
                            ? null
                            : 'A autorização do responsável legal é obrigatória.';
                      },
                      builder: (field) {
                        final visibleError =
                            controller.fieldError(
                              'consentimentoResponsavelLegal',
                            ) ??
                            field.errorText;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CheckboxListTile(
                              key: const ValueKey('guardian-consent-checkbox'),
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: _autorizacaoResponsavel,
                              onChanged: controller.isSubmitting
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _autorizacaoResponsavel =
                                            value ?? false;
                                        field.didChange(
                                          _autorizacaoResponsavel,
                                        );
                                      });
                                      _onFieldChanged(
                                        'consentimentoResponsavelLegal',
                                      );
                                    },
                              title: const Text(
                                'Sou o responsável legal e autorizo expressamente este cadastro demonstrativo.',
                              ),
                            ),
                            if (visibleError != null)
                              Semantics(
                                liveRegion: true,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: AppSpacing.md,
                                  ),
                                  child: Text(
                                    visibleError,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
              RegistrationSection(
                title: 'Crie uma senha',
                description: 'Use uma senha que você consiga lembrar e não compartilhe com outras pessoas.',
                children: [
                  AppTextField(
                    key: _senhaKey,
                    label: 'Senha',
                    controller: _senhaController,
                    focusNode: _senhaFocus,
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: _validateSenha,
                    errorText: controller.fieldError('senha'),
                    highlightError: controller.fieldError('senha') != null,
                    onChanged: (_) => _onFieldChanged('senha'),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    enabled: !controller.isSubmitting,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    key: _confirmarSenhaKey,
                    label: 'Confirmar senha',
                    controller: _confirmarSenhaController,
                    focusNode: _confirmarSenhaFocus,
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: _validateConfirmarSenha,
                    onChanged: (_) {
                      if (_showValidationMessage) {
                        setState(() => _showValidationMessage = false);
                      }
                    },
                    onSubmitted: (_) => _submit(),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    enabled: !controller.isSubmitting,
                  ),
                ],
              ),
              RegistrationSection(
                title: 'Termos e privacidade',
                description: 'Abra os termos completos para conhecer o uso e o prazo de exclusão dos dados.',
                children: [
                  TermsAcceptanceField(
                    key: _termosKey,
                    enabled: !controller.isSubmitting,
                    initialValue: _aceiteLgpd,
                    errorText: controller.fieldError('aceiteLgpd'),
                    onChanged: _onTermsChanged,
                  ),
                ],
              ),
              SizedBox(
                height: 56,
                child: AppPrimaryButton(
                  label: 'Criar conta',
                  isLoading: controller.isSubmitting,
                  onPressed: _submit,
                ),
              ),
              if (widget.onGoToLogin != null) ...[
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: controller.isSubmitting
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
}

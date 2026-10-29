import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_masks.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../appointments/domain/appointment_repository.dart';
import '../../../appointments/domain/specialty.dart';
import '../../../appointments/presentation/widgets/appointment_specialty_picker_sheet.dart';
import '../../data/dtos/professional_profile_dtos.dart';
import '../controllers/professional_profile_controller.dart';
import '../widgets/profile_section.dart';

class ProfessionalProfileFormPage extends StatefulWidget {
  const ProfessionalProfileFormPage({
    required this.controller,
    required this.onSaved,
    required this.onSessionExpired,
    this.onLogout,
    this.specialtyRepository,
    super.key,
  });

  final ProfessionalProfileController controller;
  final VoidCallback onSaved;
  final VoidCallback onSessionExpired;

  /// Quando informado (primeiro acesso, sem tela anterior), mostra "Sair" na
  /// barra superior.
  final VoidCallback? onLogout;

  /// Fonte do catálogo (GET /api/especialidade). Quando informado, o formulário
  /// mostra o campo Especialidade, reutilizando o seletor já existente.
  final AppointmentRepository? specialtyRepository;

  @override
  State<ProfessionalProfileFormPage> createState() =>
      _ProfessionalProfileFormPageState();
}

class _ProfessionalProfileFormPageState
    extends State<ProfessionalProfileFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _cpf = TextEditingController();
  final _crefito = TextEditingController();
  final _phone = TextEditingController();
  final _birthDateText = TextEditingController();
  final _bio = TextEditingController();
  final _specialtyText = TextEditingController();
  Specialty? _specialty;
  DateTime? _birthDate;
  bool _sessionExpiredHandled = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    final profile = widget.controller.profile;
    if (widget.controller.canEdit && profile != null) {
      _name.text = profile.isPendingCompletion ? '' : profile.name;
      _crefito.text = profile.crefito;
      _phone.text = InputMasks.applyTelefoneMask(profile.phone);
      _bio.text = profile.bio;
      _specialtyText.text = profile.specialtyName;
      _cpf.text = InputMasks.applyMask(
        InputMasks.cpf,
        widget.controller.cpfInSession ?? '',
      );
      _birthDate = widget.controller.birthDateInSession;
      if (_birthDate != null) _birthDateText.text = _formatDate(_birthDate!);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _name.dispose();
    _cpf.dispose();
    _crefito.dispose();
    _phone.dispose();
    _birthDateText.dispose();
    _bio.dispose();
    _specialtyText.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (widget.controller.isSessionExpired && !_sessionExpiredHandled) {
      _sessionExpiredHandled = true;
      widget.onSessionExpired();
      return;
    }
    if (mounted) setState(() {});
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  /// Lê a data digitada (DD/MM/AAAA). Vazia ou incompleta vira null.
  void _onBirthDateChanged(String value) {
    setState(() => _birthDate = InputMasks.parseDate(value));
  }

  String? _validateBirthDate(String? value) {
    final date = InputMasks.parseDate(value ?? '');
    if (date == null) return 'Informe uma data válida.';
    return null;
  }

  Future<void> _chooseSpecialty() async {
    final repository = widget.specialtyRepository;
    if (repository == null) return;
    final picked = await showModalBottomSheet<Specialty>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AppointmentSpecialtyPickerSheet(repository: repository),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _specialty = picked;
      _specialtyText.text = picked.name;
    });
  }

  Future<void> _submit() async {
    if (widget.controller.isSubmitting ||
        !widget.controller.canEdit ||
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final date = _birthDate;
    if (date == null) return;
    final success = await widget.controller.submit(
      ProfessionalUpdateRequest(
        name: _name.text,
        cpf: _cpf.text,
        crefito: _crefito.text,
        phone: _phone.text,
        birthDate: date,
        bio: _bio.text,
        isActive: widget.controller.profile!.isActive,
      ),
      specialtyId: _specialty?.id,
      specialtyName: _specialty?.name,
    );
    if (success && mounted) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.canEdit) {
      return const Scaffold(
        body: SafeArea(
          child: ErrorState(
            title: 'Acesso restrito',
            message: 'Esta área é exclusiva para profissionais.',
          ),
        ),
      );
    }
    final controller = widget.controller;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.controller.profile?.isPendingCompletion ?? true
              ? 'Completar perfil'
              : 'Editar perfil',
        ),
        actions: [
          if (widget.onLogout != null)
            IconButton(
              tooltip: 'Sair',
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (controller.cpfInSession == null ||
                    controller.birthDateInSession == null) ...[
                  const Text(
                    'Por segurança, informe CPF e data de nascimento para salvar. Esses dados não estão disponíveis para consulta nesta versão.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                ProfileSection(
                  title: 'Dados pessoais',
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Nome completo',
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        errorText: controller.errorFor('nomeCompleto'),
                        validator: (value) {
                          final length = value?.trim().length ?? 0;
                          return length < 3 || length > 150
                              ? 'Informe entre 3 e 150 caracteres.'
                              : null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'CPF',
                        controller: _cpf,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [InputMasks.cpfFormatter()],
                        errorText: controller.errorFor('cpf'),
                        validator: (value) =>
                            InputMasks.digitsOnly(value ?? '').length == 11
                            ? null
                            : 'Informe os 11 dígitos do CPF.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Telefone com DDD',
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [InputMasks.telefoneFlexFormatter()],
                        errorText: controller.errorFor('telefone'),
                        validator: (value) {
                          final length = InputMasks.digitsOnly(value ?? '')
                              .length;
                          return length == 10 || length == 11
                              ? null
                              : 'Informe DDD e telefone com 10 ou 11 dígitos.';
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Data de nascimento',
                        controller: _birthDateText,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [InputMasks.dataFormatter()],
                        onChanged: _onBirthDateChanged,
                        hint: 'DD/MM/AAAA',
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        errorText: controller.errorFor('dataNascimento'),
                        validator: _validateBirthDate,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ProfileSection(
                  title: 'Atuação profissional',
                  child: Column(
                    children: [
                      if (widget.specialtyRepository != null) ...[
                        AppTextField(
                          label: 'Especialidade',
                          controller: _specialtyText,
                          readOnly: true,
                          onTap: _chooseSpecialty,
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                          validator: (value) => (value?.trim().isEmpty ?? true)
                              ? 'Escolha sua especialidade.'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      AppTextField(
                        label: 'CREFITO',
                        controller: _crefito,
                        textInputAction: TextInputAction.next,
                        errorText: controller.errorFor('crefito'),
                        validator: (value) {
                          final length = value?.trim().length ?? 0;
                          return length < 4 || length > 20
                              ? 'Informe entre 4 e 20 caracteres.'
                              : null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Bio (opcional)',
                        controller: _bio,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        errorText: controller.errorFor('bio'),
                        validator: (value) => (value?.trim().length ?? 0) > 1000
                            ? 'A bio deve ter até 1000 caracteres.'
                            : null,
                      ),
                    ],
                  ),
                ),
                if (controller.submitError != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    controller.submitError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppPrimaryButton(
                  label: 'Salvar perfil',
                  icon: Icons.check,
                  isLoading: controller.isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

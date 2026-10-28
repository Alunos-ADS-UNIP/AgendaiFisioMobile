import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_masks.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../appointments/domain/appointment_repository.dart';
import '../../domain/professional_profile.dart';
import '../controllers/professional_profile_controller.dart';
import '../widgets/profile_section.dart';
import 'professional_profile_form_page.dart';

class ProfessionalProfilePage extends StatefulWidget {
  const ProfessionalProfilePage({
    required this.controller,
    required this.onLogout,
    this.onChangeSpecialty,
    this.specialtyRepository,
    super.key,
  });

  final ProfessionalProfileController controller;
  final VoidCallback onLogout;

  /// Recebe a navegação do módulo de especialidades, quando ele estiver ligado
  /// à sessão. A página recarrega o perfil ao voltar.
  final Future<void> Function()? onChangeSpecialty;

  /// Repassado ao formulário para permitir escolher/trocar a especialidade.
  final AppointmentRepository? specialtyRepository;

  @override
  State<ProfessionalProfilePage> createState() =>
      _ProfessionalProfilePageState();
}

class _ProfessionalProfilePageState extends State<ProfessionalProfilePage> {
  bool _logoutRequested = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.load();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (widget.controller.isSessionExpired) {
      _logout();
      return;
    }
    if (mounted) setState(() {});
  }

  void _logout() {
    if (_logoutRequested) return;
    _logoutRequested = true;
    widget.onLogout();
  }

  Future<void> _edit() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => ProfessionalProfileFormPage(
          controller: widget.controller,
          onSaved: () => Navigator.of(context).pop(),
          onSessionExpired: _logout,
          specialtyRepository: widget.specialtyRepository,
        ),
      ),
    );
  }

  Future<void> _changeSpecialty() async {
    final action = widget.onChangeSpecialty;
    if (action == null) return;
    await action();
    if (mounted) await widget.controller.load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Meu perfil profissional'),
      actions: [
        IconButton(
          tooltip: 'Sair',
          onPressed: _logout,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: SafeArea(child: _body(context)),
  );

  Widget _body(BuildContext context) {
    switch (widget.controller.status) {
      case ProfessionalProfileStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ProfessionalProfileStatus.forbidden:
        return const ErrorState(
          title: 'Acesso restrito',
          message: 'Esta área é exclusiva para profissionais.',
        );
      case ProfessionalProfileStatus.error:
        return ErrorState(
          message: widget.controller.loadError ?? 'Não foi possível carregar.',
          onRetry: widget.controller.load,
        );
      case ProfessionalProfileStatus.content:
        return _content(context, widget.controller.profile!);
    }
  }

  Widget _content(BuildContext context, ProfessionalProfile profile) =>
      RefreshIndicator(
        onRefresh: widget.controller.load,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (profile.isPendingCompletion) ...[
              Text(
                'Complete seus dados profissionais para começar.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            ProfileSection(
              title: 'Dados profissionais',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field(
                    'Nome',
                    profile.isPendingCompletion ? 'Pendente' : profile.name,
                  ),
                  _field('E-mail', profile.email),
                  _field('CREFITO', InputMasks.displayCrefito(profile.crefito)),
                  _field(
                    'Telefone',
                    profile.phone.isEmpty
                        ? ''
                        : InputMasks.applyTelefoneMask(profile.phone),
                  ),
                  _field('Bio', profile.bio),
                  _field('Especialidade', profile.specialtyName),
                  _field('Situação', profile.isActive ? 'Ativo' : 'Inativo'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: profile.isPendingCompletion
                  ? 'Completar perfil'
                  : 'Editar perfil',
              icon: Icons.edit_outlined,
              onPressed: _edit,
            ),
            // Sem rota/ação para trocar a especialidade, o botão não aparece.
            if (widget.onChangeSpecialty != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppSecondaryButton(
                label: 'Alterar especialidade',
                icon: Icons.spa_outlined,
                onPressed: _changeSpecialty,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: 'Sair',
              icon: Icons.logout,
              onPressed: _logout,
            ),
          ],
        ),
      );

  Widget _field(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xxs),
        Text(value.isEmpty ? '—' : value),
      ],
    ),
  );
}

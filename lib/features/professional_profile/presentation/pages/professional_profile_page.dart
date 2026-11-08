import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_masks.dart';
import '../../../../core/utils/profile_photo_processor.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/profile_avatar.dart';
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
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    // O mesmo controller já alimenta a home. Notificá-lo durante a montagem
    // desta rota causava "setState during build" ao abrir o perfil.
    if (widget.controller.profile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.controller.load();
      });
    }
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

  Future<void> _changePhoto() async {
    if (widget.controller.isPhotoSubmitting) return;
    final profile = widget.controller.profile;
    if (profile == null) return;
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(sheetContext, _PhotoAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(sheetContext, _PhotoAction.gallery),
            ),
            if (profile.photoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remover foto'),
                onTap: () => Navigator.pop(sheetContext, _PhotoAction.remove),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == _PhotoAction.remove) {
      final confirmed = await showConfirmDialog(
        context: context,
        title: 'Remover foto?',
        message: 'Os pacientes voltarão a ver apenas as suas iniciais.',
        confirmLabel: 'Remover',
      );
      if (!confirmed || !mounted) return;
      final removed = await widget.controller.removePhoto();
      if (!mounted) return;
      if (removed) {
        AppFeedback.showSuccess(context, 'Foto removida com sucesso.');
      } else {
        AppFeedback.showError(
          context,
          widget.controller.photoError ?? 'Não foi possível remover a foto.',
        );
      }
      return;
    }

    try {
      final selected = await _imagePicker.pickImage(
        source: action == _PhotoAction.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
      );
      if (selected == null || !mounted) return;
      final prepared = await prepareProfilePhoto(await selected.readAsBytes());
      if (!mounted) return;
      final uploaded = await widget.controller.updatePhoto(prepared);
      if (!mounted) return;
      if (uploaded) {
        AppFeedback.showSuccess(context, 'Foto atualizada com sucesso.');
      } else {
        AppFeedback.showError(
          context,
          widget.controller.photoError ?? 'Não foi possível enviar a foto.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(
          context,
          'A imagem escolhida não pôde ser usada.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meu perfil profissional')),
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
            Center(
              child: ProfileAvatar(
                name: profile.name,
                photoUrl: profile.photoUrl,
                radius: 56,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton.icon(
                onPressed: widget.controller.isPhotoSubmitting
                    ? null
                    : _changePhoto,
                icon: widget.controller.isPhotoSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_a_photo_outlined),
                label: Text(
                  widget.controller.isPhotoSubmitting
                      ? 'Enviando foto...'
                      : profile.photoUrl == null
                      ? 'Adicionar foto'
                      : 'Alterar foto',
                ),
              ),
            ),
            if (widget.controller.photoError case final error?)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
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
                  _field('CREFITO', profile.crefito),
                  _field(
                    'Telefone',
                    profile.phone.isEmpty
                        ? ''
                        : InputMasks.applyTelefoneMask(profile.phone),
                  ),
                  _field('Especialidade', profile.specialtyName),
                  _field('Bio', profile.bio),

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

enum _PhotoAction { camera, gallery, remove }

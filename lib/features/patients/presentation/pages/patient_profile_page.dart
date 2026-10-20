import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_masks.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../../../core/widgets/error_state.dart';
import '../../domain/patient.dart';
import '../controllers/patient_profile_controller.dart';

/// Tela "Meu perfil" do paciente. Consulta GET /api/paciente/me — nunca
/// recebe ou monta um pacienteId, a identidade vem inteiramente da sessão.
class PatientProfilePage extends StatefulWidget {
  const PatientProfilePage({
    required this.controller,
    required this.onEdit,
    required this.onLogout,
    super.key,
  });

  final PatientProfileController controller;
  final void Function(Patient currentPatient) onEdit;

  /// Chamado quando o paciente toca em "Sair", e também automaticamente se
  /// o GET /me voltar 401 (sessão expirada). A limpeza de fato da sessão
  /// (token, storage) é responsabilidade do session_controller do Jonas;
  /// aqui só disparamos o callback.
  final VoidCallback onLogout;

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    widget.controller.load();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller.isSessionExpired) {
      widget.onLogout();
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, controller)),
    );
  }

  Widget _buildBody(BuildContext context, PatientProfileController controller) {
    switch (controller.status) {
      case PatientProfileStatus.loading:
        // TODO(Dudu): trocar por AppLoadingSkeleton quando eu confirmar a
        // assinatura dele — não vi o conteúdo de app_loading_skeleton.dart.
        return const Center(child: CircularProgressIndicator());

      case PatientProfileStatus.error:
        return ErrorState(
          message:
              controller.errorMessage ??
              'Não foi possível carregar seu perfil.',
          onRetry: controller.load,
        );

      case PatientProfileStatus.content:
        final patient = controller.patient!;
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (patient.isPendingCompletion) ...[
                _PendingProfileBanner(onTap: () => widget.onEdit(patient)),
                const SizedBox(height: AppSpacing.lg),
              ],
              _ProfileField(
                label: 'Nome completo',
                value: patient.nomeCompleto,
              ),
              _ProfileField(
                label: 'CPF',
                value: patient.cpf.isEmpty
                    ? '—'
                    : InputMasks.applyMask(InputMasks.cpf, patient.cpf),
              ),
              _ProfileField(
                label: 'Data de nascimento',
                value: patient.dataNascimento == null
                    ? '—'
                    : _formatDate(patient.dataNascimento!),
              ),
              _ProfileField(
                label: 'Telefone',
                value: patient.telefone.isEmpty
                    ? '—'
                    : InputMasks.applyMask(
                        InputMasks.telefone,
                        patient.telefone,
                      ),
              ),
              _ProfileField(label: 'E-mail', value: patient.email),
              _ProfileField(
                label: 'Endereço',
                value: patient.endereco.isEmpty
                    ? '—'
                    : _formatAddress(patient.endereco),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: patient.isPendingCompletion
                    ? 'Completar perfil'
                    : 'Editar perfil',
                icon: Icons.edit_outlined,
                onPressed: () => widget.onEdit(patient),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppSecondaryButton(
                label: 'Sair',
                icon: Icons.logout,
                onPressed: widget.onLogout,
              ),
            ],
          ),
        );
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatAddress(PatientAddress endereco) {
    final parts = [
      if (endereco.rua.isNotEmpty) endereco.rua,
      if (endereco.numero.isNotEmpty) endereco.numero,
      if (endereco.bairro.isNotEmpty) endereco.bairro,
      if (endereco.cidade.isNotEmpty) endereco.cidade,
      if (endereco.estado.isNotEmpty) endereco.estado,
    ];
    return parts.join(', ');
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _PendingProfileBanner extends StatelessWidget {
  const _PendingProfileBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primaryDark),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Seu cadastro ainda não foi completado. Toque para preencher seus dados.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.primaryDark),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primaryDark),
          ],
        ),
      ),
    );
  }
}

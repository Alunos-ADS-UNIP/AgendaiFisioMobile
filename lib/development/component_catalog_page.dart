import 'package:flutter/material.dart';

import '../core/models/appointment_status.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/app_feedback.dart';
import '../core/widgets/app_loading_skeleton.dart';
import '../core/widgets/app_primary_button.dart';
import '../core/widgets/app_search_field.dart';
import '../core/widgets/app_secondary_button.dart';
import '../core/widgets/app_text_field.dart';
import '../core/widgets/appointment_card.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/error_state.dart';
import '../core/widgets/professional_card.dart';
import '../core/widgets/status_chip.dart';

class ComponentCatalogPage extends StatefulWidget {
  const ComponentCatalogPage({super.key});

  @override
  State<ComponentCatalogPage> createState() => _ComponentCatalogPageState();
}

class _ComponentCatalogPageState extends State<ComponentCatalogPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgendaiFisio - Componentes'),
        backgroundColor: AppColors.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Base compartilhada',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Esta tela existe para os integrantes validarem o mesmo padrão visual antes de criarem as features.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Section(
            title: 'Botões',
            children: [
              AppPrimaryButton(
                label: 'Ação principal',
                icon: Icons.check,
                onPressed: () => AppFeedback.showSuccess(
                  context,
                  'Ação concluída com sucesso.',
                ),
              ),
              AppSecondaryButton(
                label: 'Ação secundária',
                icon: Icons.tune,
                onPressed: () =>
                    AppFeedback.showWarning(context, 'Exemplo de aviso.'),
              ),
              const AppPrimaryButton(
                label: 'Carregando',
                onPressed: null,
                isLoading: true,
              ),
            ],
          ),
          _Section(
            title: 'Campos',
            children: [
              const AppTextField(
                label: 'E-mail',
                hint: 'nome@exemplo.com',
                prefixIcon: Icons.email_outlined,
              ),
              AppSearchField(
                controller: _searchController,
                hint: 'Fisioterapeuta ou especialidade',
                onChanged: (_) {},
              ),
            ],
          ),
          _Section(
            title: 'Status',
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: AppointmentStatus.values
                    .map((status) => StatusChip(status: status))
                    .toList(),
              ),
            ],
          ),
          const _Section(
            title: 'Agendamento',
            children: [
              AppointmentCard(
                dateLabel: '18 OUT',
                timeLabel: '14:30',
                personName: 'Dra. Marina Lopes',
                specialtyName: 'Fisioterapia esportiva',
                status: AppointmentStatus.confirmed,
              ),
            ],
          ),
          const _Section(
            title: 'Fisioterapeuta',
            children: [
              ProfessionalCard(
                name: 'Dra. Marina Lopes',
                specialty: 'Fisioterapia esportiva',
                crefito: 'CREFITO 123456-F',
                isActive: true,
              ),
            ],
          ),
          const _Section(
            title: 'Carregamento',
            children: [AppLoadingSkeleton()],
          ),
          const _Section(
            title: 'Estado vazio',
            children: [
              EmptyState(
                title: 'Nenhum agendamento',
                message: 'Quando uma consulta for marcada, ela aparecerá aqui.',
              ),
            ],
          ),
          _Section(
            title: 'Estado de erro',
            children: [
              ErrorState(
                message: 'Confira sua conexão e tente novamente.',
                onRetry: () =>
                    AppFeedback.showError(context, 'Nova tentativa iniciada.'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          ...children.expand(
            (child) => [child, const SizedBox(height: AppSpacing.sm)],
          ),
        ],
      ),
    );
  }
}

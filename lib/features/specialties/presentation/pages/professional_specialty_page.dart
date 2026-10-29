import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/error_state.dart';
import '../../domain/entities/specialty.dart';
import '../controllers/specialty_controller.dart';
import '../widgets/specialty_primary_button.dart';
import '../widgets/specialty_picker_sheet.dart';

class ProfessionalSpecialtyPage extends StatefulWidget {
  const ProfessionalSpecialtyPage({
    required this.catalogController,
    required this.professionalController,
    super.key,
  });

  final SpecialtyCatalogController catalogController;
  final ProfessionalSpecialtyController professionalController;

  @override
  State<ProfessionalSpecialtyPage> createState() =>
      _ProfessionalSpecialtyPageState();
}

class _ProfessionalSpecialtyPageState extends State<ProfessionalSpecialtyPage> {
  Specialty? _pendingSelection;

  @override
  void initState() {
    super.initState();
    if (widget.catalogController.state.status ==
        SpecialtyCatalogStatus.initial) {
      widget.catalogController.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha especialidade')),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          widget.catalogController,
          widget.professionalController,
        ]),
        builder: (context, _) {
          final state = widget.catalogController.state;
          final selected = _pendingSelection ?? _selectedFromState(state.items);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Vincule sua área de atendimento',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'A alteração será aplicada somente após a confirmação da API.',
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.large,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                  title: Text(selected?.name ?? 'Nenhuma selecionada'),
                  subtitle: const Text('Especialidade atual ou escolhida'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: state.items.isEmpty ? null : _chooseSpecialty,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (state.status == SpecialtyCatalogStatus.loading)
                Semantics(
                  label: 'Carregando especialidades',
                  liveRegion: true,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.status == SpecialtyCatalogStatus.empty)
                const Text('O catálogo ainda não possui especialidades.')
              else if (state.status == SpecialtyCatalogStatus.error ||
                  state.status == SpecialtyCatalogStatus.offline)
                SizedBox(
                  width: double.infinity,
                  child: ErrorState(
                    title: state.status == SpecialtyCatalogStatus.offline
                        ? 'Sem conexão'
                        : 'Não foi possível carregar',
                    message: state.errorMessage ?? 'Tente novamente.',
                    onRetry: widget.catalogController.load,
                  ),
                ),
              if (widget.professionalController.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.professionalController.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SpecialtyPrimaryButton(
                label: 'Salvar especialidade',
                icon: Icons.save_outlined,
                isLoading: widget.professionalController.isSaving,
                onPressed: selected == null ? null : () => _save(selected),
              ),
            ],
          );
        },
      ),
    );
  }

  Specialty? _selectedFromState(List<Specialty> items) {
    final selectedId = widget.professionalController.selectedId;
    if (selectedId == null) return null;
    for (final item in items) {
      if (item.id == selectedId) return item;
    }
    return null;
  }

  Future<void> _chooseSpecialty() async {
    final selected = await SpecialtyPickerSheet.show(
      context,
      items: widget.catalogController.state.items,
      initialSelection:
          _pendingSelection ??
          _selectedFromState(widget.catalogController.state.items),
    );
    if (mounted && selected != null) {
      setState(() => _pendingSelection = selected);
    }
  }

  Future<void> _save(Specialty selected) async {
    final success = await widget.professionalController.save(selected.id);
    if (!mounted) return;
    if (success) {
      setState(() => _pendingSelection = null);
      AppFeedback.showSuccess(context, 'Especialidade atualizada com sucesso.');
    } else {
      setState(() => _pendingSelection = null);
      AppFeedback.showError(
        context,
        widget.professionalController.errorMessage ??
            'Não foi possível atualizar a especialidade.',
      );
    }
  }
}

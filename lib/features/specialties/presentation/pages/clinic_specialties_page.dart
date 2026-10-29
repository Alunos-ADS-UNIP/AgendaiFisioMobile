import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/specialty.dart';
import '../controllers/specialty_controller.dart';
import '../widgets/create_specialty_dialog.dart';

class ClinicSpecialtiesPage extends StatefulWidget {
  const ClinicSpecialtiesPage({
    required this.catalogController,
    required this.clinicController,
    required this.canCreate,
    super.key,
  });

  final SpecialtyCatalogController catalogController;
  final ClinicSpecialtyController clinicController;
  final bool canCreate;

  @override
  State<ClinicSpecialtiesPage> createState() => _ClinicSpecialtiesPageState();
}

class _ClinicSpecialtiesPageState extends State<ClinicSpecialtiesPage> {
  @override
  void initState() {
    super.initState();
    if (widget.canCreate &&
        widget.catalogController.state.status ==
            SpecialtyCatalogStatus.initial) {
      widget.catalogController.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.canCreate) {
      return const Scaffold(
        appBar: _RestrictedAppBar(),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Esta área administrativa está disponível somente para Clínica.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Especialidades da Clínica')),
      body: AnimatedBuilder(
        animation: widget.catalogController,
        builder: (context, _) {
          final state = widget.catalogController.state;
          if (state.status == SpecialtyCatalogStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == SpecialtyCatalogStatus.empty) {
            return EmptyState(
              title: 'Nenhuma especialidade cadastrada',
              message: 'Cadastre a primeira especialidade da clínica.',
              actionLabel: 'Nova especialidade',
              onAction: _openCreateDialog,
            );
          }
          if (state.status == SpecialtyCatalogStatus.error ||
              state.status == SpecialtyCatalogStatus.offline) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.errorMessage ??
                          'Não foi possível carregar o catálogo.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppPrimaryButton(
                      label: 'Tentar novamente',
                      icon: Icons.refresh,
                      onPressed: widget.catalogController.load,
                      expand: false,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: state.items.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == 0) {
                return AppPrimaryButton(
                  label: 'Nova especialidade',
                  icon: Icons.add,
                  onPressed: _openCreateDialog,
                );
              }
              return _SpecialtyListTile(specialty: state.items[index - 1]);
            },
          );
        },
      ),
    );
  }

  Future<void> _openCreateDialog() async {
    final created = await CreateSpecialtyDialog.show(
      context,
      controller: widget.clinicController,
      existingItems: widget.catalogController.state.items,
    );
    if (!mounted || created == null) return;
    widget.catalogController.addCreated(created);
    AppFeedback.showSuccess(context, 'Especialidade cadastrada com sucesso.');
  }
}

class _RestrictedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _RestrictedAppBar();

  @override
  Widget build(BuildContext context) =>
      AppBar(title: const Text('Acesso restrito'));

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SpecialtyListTile extends StatelessWidget {
  const _SpecialtyListTile({required this.specialty});

  final Specialty specialty;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      minVerticalPadding: AppSpacing.sm,
      leading: const Icon(Icons.medical_services_outlined),
      title: Text(specialty.name),
      subtitle: const Text('Disponível para vínculo profissional'),
    ),
  );
}

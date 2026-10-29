import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../domain/entities/specialty.dart';
import '../../domain/repositories/specialty_repository.dart';
import '../controllers/specialty_controller.dart';

class SpecialtyListPage extends StatefulWidget {
  const SpecialtyListPage({
    required this.controller,
    this.repository,
    super.key,
  });

  final SpecialtyCatalogController controller;
  final SpecialtyRepository? repository;

  @override
  State<SpecialtyListPage> createState() => _SpecialtyListPageState();
}

class _SpecialtyListPageState extends State<SpecialtyListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.controller.state.status == SpecialtyCatalogStatus.initial) {
      widget.controller.load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Especialidades'),
        actions: [
          IconButton(
            tooltip: 'Atualizar catálogo',
            onPressed: () => widget.controller.load(refresh: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final state = widget.controller.state;
          final query = _searchController.text.trim().toLowerCase();
          final filtered = state.items
              .where((item) => item.name.toLowerCase().contains(query))
              .toList(growable: false);

          return RefreshIndicator(
            onRefresh: () => widget.controller.load(refresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              children: [
                Text(
                  'Encontre uma área de atendimento',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Consulte o catálogo público de especialidades do AgendaiFisio.',
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSearchField(
                  controller: _searchController,
                  hint: 'Pesquisar especialidade',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildContent(context, state, filtered),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SpecialtyCatalogState state,
    List<Specialty> filtered,
  ) {
    if (state.status == SpecialtyCatalogStatus.loading) {
      return const Column(
        children: [
          AppLoadingSkeleton(lines: 4),
          SizedBox(height: AppSpacing.md),
          AppLoadingSkeleton(lines: 4),
        ],
      );
    }
    if (state.status == SpecialtyCatalogStatus.error ||
        state.status == SpecialtyCatalogStatus.offline) {
      return ErrorState(
        title: state.status == SpecialtyCatalogStatus.offline
            ? 'Sem conexão'
            : 'Não foi possível carregar',
        message: state.errorMessage ?? 'Tente novamente.',
        onRetry: widget.controller.load,
      );
    }
    if (state.status == SpecialtyCatalogStatus.empty || filtered.isEmpty) {
      return const EmptyState(
        title: 'Nenhuma especialidade encontrada',
        message: 'Tente outro termo de pesquisa.',
        icon: Icons.search_off_outlined,
      );
    }
    return Column(
      children: filtered
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _SpecialtyCard(
                specialty: item,
                onTap: widget.repository == null
                    ? null
                    : () => _showDetails(item),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<void> _showDetails(Specialty item) async {
    final repository = widget.repository;
    if (repository == null) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: FutureBuilder<Specialty>(
          future: repository.getById(item.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 48,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return const Text(
                'Não foi possível consultar esta especialidade.',
              );
            }
            return Text('Especialidade disponível: ${snapshot.data!.name}');
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

class _SpecialtyCard extends StatelessWidget {
  const _SpecialtyCard({required this.specialty, this.onTap});

  final Specialty specialty;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        minVerticalPadding: AppSpacing.sm,
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.medical_services_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(specialty.name),
        subtitle: Text(
          onTap == null
              ? 'Especialidade disponível no catálogo'
              : 'Toque para consultar detalhes',
        ),
      ),
    );
  }
}

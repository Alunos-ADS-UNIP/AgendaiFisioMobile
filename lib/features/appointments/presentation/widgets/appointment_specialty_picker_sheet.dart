import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../domain/appointment_repository.dart';
import '../../domain/specialty.dart';

class AppointmentSpecialtyPickerSheet extends StatefulWidget {
  const AppointmentSpecialtyPickerSheet({required this.repository, super.key});

  final AppointmentRepository repository;

  @override
  State<AppointmentSpecialtyPickerSheet> createState() =>
      _AppointmentSpecialtyPickerSheetState();
}

class _AppointmentSpecialtyPickerSheetState
    extends State<AppointmentSpecialtyPickerSheet> {
  final _searchController = TextEditingController();
  late Future<List<Specialty>> _specialties = widget.repository
      .fetchSpecialties();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Escolha uma especialidade',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSearchField(
              controller: _searchController,
              hint: 'Pesquisar especialidade',
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: FutureBuilder<List<Specialty>>(
                future: _specialties,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return SingleChildScrollView(
                      child: ErrorState(
                        message: 'Não foi possível carregar especialidades.',
                        onRetry: () => setState(
                          () => _specialties = widget.repository
                              .fetchSpecialties(),
                        ),
                      ),
                    );
                  }
                  final filtered = (snapshot.data ?? const <Specialty>[])
                      .where((item) => item.name.toLowerCase().contains(_query))
                      .toList();
                  if (filtered.isEmpty) {
                    return const SingleChildScrollView(
                      child: EmptyState(
                        title: 'Nenhuma especialidade encontrada',
                        message: 'Tente outro termo de busca.',
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return ListTile(
                        leading: const Icon(Icons.spa_outlined),
                        title: Text(item.name),
                        onTap: () => Navigator.pop(context, item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

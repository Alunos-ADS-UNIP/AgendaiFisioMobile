import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
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
  late final Future<List<Specialty>> _specialties = widget.repository
      .fetchSpecialties();
  String _query = '';

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
            TextField(
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Pesquisar',
              ),
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
                    return Center(
                      child: Text('Não foi possível carregar especialidades.'),
                    );
                  }
                  final filtered = (snapshot.data ?? const <Specialty>[])
                      .where((item) => item.name.toLowerCase().contains(_query))
                      .toList();
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('Nenhuma especialidade encontrada.'),
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

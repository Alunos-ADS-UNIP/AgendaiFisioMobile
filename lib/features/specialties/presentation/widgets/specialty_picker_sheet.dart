import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../domain/entities/specialty.dart';
import '../../domain/specialty_name_normalizer.dart';

class SpecialtyPickerSheet extends StatefulWidget {
  const SpecialtyPickerSheet({
    required this.items,
    this.initialSelection,
    this.title = 'Selecionar especialidade',
    super.key,
  });

  final List<Specialty> items;
  final Specialty? initialSelection;
  final String title;

  static Future<Specialty?> show(
    BuildContext context, {
    required List<Specialty> items,
    Specialty? initialSelection,
    String title = 'Selecionar especialidade',
  }) {
    return showModalBottomSheet<Specialty>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (_) => SpecialtyPickerSheet(
        items: items,
        initialSelection: initialSelection,
        title: title,
      ),
    );
  }

  @override
  State<SpecialtyPickerSheet> createState() => _SpecialtyPickerSheetState();
}

class _SpecialtyPickerSheetState extends State<SpecialtyPickerSheet> {
  final _searchController = TextEditingController();
  Specialty? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelection;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = normalizeSpecialtyName(_searchController.text);
    final filtered = widget.items
        .where((item) => normalizeSpecialtyName(item.name).contains(query))
        .toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          top: AppSpacing.md,
          right: AppSpacing.md,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              AppSearchField(
                controller: _searchController,
                hint: 'Pesquisar especialidade',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('Nenhuma especialidade encontrada.'),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final selected = _selected?.id == item.id;
                          return Semantics(
                            button: true,
                            selected: selected,
                            label: item.name,
                            child: Card(
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.large,
                              ),
                              child: ListTile(
                                minVerticalPadding: AppSpacing.xs,
                                selected: selected,
                                leading: Icon(
                                  selected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: selected
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                                title: Text(item.name),
                                onTap: () => Navigator.of(context).pop(item),
                              ),
                            ),
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
}

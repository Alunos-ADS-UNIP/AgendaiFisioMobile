import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/specialty.dart';
import '../../domain/specialty_name_normalizer.dart';
import '../controllers/specialty_controller.dart';
import 'specialty_primary_button.dart';

class CreateSpecialtyDialog extends StatefulWidget {
  const CreateSpecialtyDialog({
    required this.controller,
    this.existingItems = const [],
    super.key,
  });

  final ClinicSpecialtyController controller;
  final List<Specialty> existingItems;

  static Future<Specialty?> show(
    BuildContext context, {
    required ClinicSpecialtyController controller,
    List<Specialty> existingItems = const [],
  }) {
    return showDialog<Specialty>(
      context: context,
      builder: (_) => CreateSpecialtyDialog(
        controller: controller,
        existingItems: existingItems,
      ),
    );
  }

  @override
  State<CreateSpecialtyDialog> createState() => _CreateSpecialtyDialogState();
}

class _CreateSpecialtyDialogState extends State<CreateSpecialtyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.large),
      title: const Text('Nova especialidade'),
      actionsOverflowDirection: VerticalDirection.down,
      content: Form(
        key: _formKey,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Nome da especialidade',
                hint: 'Ex.: Fisioterapia Esportiva',
                controller: _nameController,
                textInputAction: TextInputAction.done,
                validator: _validateName,
              ),
              AnimatedBuilder(
                animation: widget.controller,
                builder: (context, _) {
                  final error = widget.controller.errorMessage;
                  if (error == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        error,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.controller.isSaving
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) => SpecialtyPrimaryButton(
            label: 'Cadastrar',
            icon: Icons.add_rounded,
            isLoading: widget.controller.isSaving,
            expand: false,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }

  String? _validateName(String? value) {
    final normalized = normalizeSpecialtyName(value ?? '');
    if (normalized.isEmpty) return 'Informe o nome da especialidade.';
    if (normalized.length < 3 || normalized.length > 100) {
      return 'Use entre 3 e 100 caracteres.';
    }
    final duplicate = widget.existingItems.any(
      (item) => normalizeSpecialtyName(item.name) == normalized,
    );
    if (duplicate) return 'Esta especialidade já está no catálogo.';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final created = await widget.controller.create(
      _displayName(_nameController.text),
    );
    if (!mounted || created == null) return;
    Navigator.of(context).pop(created);
  }

  String _displayName(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');
}

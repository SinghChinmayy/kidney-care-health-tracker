import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_form_layout.dart';
import 'package:app/ui/features/medications/view_models/medications_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> showAddMedicationSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.background,
    shape: const RoundedRectangleBorder(
      borderRadius: AppTheme.sheetTopRadius,
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: AppTheme.spacingSm,
          right: AppTheme.spacingSm,
          top: AppTheme.spacingMd,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom +
              AppTheme.spacingMd,
        ),
        child: const _AddMedicationSheet(),
      );
    },
  );
}

class _AddMedicationSheet extends StatefulWidget {
  const _AddMedicationSheet();

  @override
  State<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<_AddMedicationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _compositionController = TextEditingController();
  final _aboutController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _compositionController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<MedicationsViewModel>().addMedication(
            pharmaceuticalName: _nameController.text,
            composition: _compositionController.text,
            about: _aboutController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Medication added')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not add medication')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add medication',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Pharmaceutical name',
                hintText: 'e.g. Furosemide',
              ),
              validator: (value) =>
                  validateRequired(value, label: 'Pharmaceutical name'),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _compositionController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Composition',
                hintText: 'e.g. Furosemide 40 mg tablets',
              ),
              validator: (value) =>
                  validateRequired(value, label: 'Composition'),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _aboutController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'About',
                hintText: 'What it is used for',
                alignLabelWithHint: true,
              ),
              validator: (value) => validateRequired(value, label: 'About'),
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

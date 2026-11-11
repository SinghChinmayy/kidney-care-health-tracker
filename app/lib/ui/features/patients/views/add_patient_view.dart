import 'package:app/domain/models/patient.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_form_layout.dart';
import 'package:app/ui/features/patients/view_models/patients_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Creates a patient for someone without their own account (e.g. a parent
/// you care for). The signed-in user becomes its owner. Needs a connection:
/// creation goes through the server so ownership is granted atomically.
class AddPatientView extends StatefulWidget {
  const AddPatientView({super.key});

  @override
  State<AddPatientView> createState() => _AddPatientViewState();
}

class _AddPatientViewState extends State<AddPatientView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _bloodGroup;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 60),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _submit(PatientsViewModel viewModel) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final created = await viewModel.createPatient(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      dateOfBirth: _dateOfBirth,
      bloodGroup: _bloodGroup,
    );
    if (!mounted) {
      return;
    }
    if (created == null) {
      showPlaceholderSnackBar(
        context,
        viewModel.errorMessage ?? "Couldn't create the patient.",
      );
      return;
    }
    showPlaceholderSnackBar(
      context,
      'Now viewing ${created.displayName ?? 'the new patient'}',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PatientsViewModel>();
    final dob = _dateOfBirth;

    return Scaffold(
      appBar: AppBar(title: const Text('Add patient')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: AppFormLayout(
            children: [
              Text(
                'Add someone you care for who does not use the app '
                'themselves. You will be their owner and can share access '
                'later.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              TextFormField(
                key: const ValueKey('add-patient-first-name'),
                controller: _firstNameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'First name'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'First name is required'
                    : null,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              TextFormField(
                key: const ValueKey('add-patient-last-name'),
                controller: _lastNameController,
                textCapitalization: TextCapitalization.words,
                decoration:
                    const InputDecoration(labelText: 'Last name (optional)'),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              OutlinedButton.icon(
                onPressed: _pickDateOfBirth,
                style: AppTheme.secondaryButtonStyle(),
                icon: const Icon(Icons.cake_outlined),
                label: Text(
                  dob == null
                      ? 'Date of birth (optional)'
                      : '${dob.day}/${dob.month}/${dob.year}',
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              DropdownButtonFormField<String?>(
                initialValue: _bloodGroup,
                decoration:
                    const InputDecoration(labelText: 'Blood group (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Not set')),
                  for (final group in bloodGroupOptions)
                    DropdownMenuItem(value: group, child: Text(group)),
                ],
                onChanged: (value) => setState(() => _bloodGroup = value),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              ElevatedButton(
                onPressed:
                    viewModel.isCreating ? null : () => _submit(viewModel),
                child: viewModel.isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create patient'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

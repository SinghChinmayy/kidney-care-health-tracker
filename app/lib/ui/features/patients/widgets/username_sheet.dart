import 'package:app/domain/models/patient_member.dart';
import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Asks for a username; returns the normalized value or null if cancelled.
/// [save] performs the server write and returns an error message or null.
Future<String?> showUsernameSheet(
  BuildContext context, {
  String? initial,
  required Future<String?> Function(String username) save,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: AppTheme.sheetTopRadius,
    ),
    builder: (_) => _UsernameSheet(initial: initial, save: save),
  );
}

class _UsernameSheet extends StatefulWidget {
  const _UsernameSheet({required this.initial, required this.save});

  final String? initial;
  final Future<String?> Function(String username) save;

  @override
  State<_UsernameSheet> createState() => _UsernameSheetState();
}

class _UsernameSheetState extends State<_UsernameSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);
  final _formKey = GlobalKey<FormState>();
  String? _serverError;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _serverError = null);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final value = normalizeUsername(_controller.text);
    setState(() => _saving = true);
    final error = await widget.save(value);
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
      _serverError = error;
    });
    if (error == null) {
      Navigator.of(context).pop(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingSm,
        right: AppTheme.spacingSm,
        top: AppTheme.spacingSm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingSm,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your username',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'People share a patient with you by this username. Your email '
              'is never shown to them.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.muted,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              key: const ValueKey('username-field'),
              controller: _controller,
              autofocus: true,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixText: '@',
                errorText: _serverError,
              ),
              validator: validateUsername,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

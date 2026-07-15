import 'package:app/domain/models/medication.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/medications/view_models/medications_view_model.dart';
import 'package:app/ui/features/medications/widgets/medication_add_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Pick a catalog medication. Returns selected [Medication] or null.
Future<Medication?> showMedicationPickerSheet(
  BuildContext context, {
  required List<Medication> medications,
  required String title,
  Set<String> excludeIds = const {},
}) {
  return showModalBottomSheet<Medication>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: AppTheme.sheetTopRadius,
    ),
    builder: (sheetContext) {
      return _MedicationPickerSheet(
        initialMedications: medications,
        title: title,
        excludeIds: excludeIds,
      );
    },
  );
}

class _MedicationPickerSheet extends StatefulWidget {
  const _MedicationPickerSheet({
    required this.initialMedications,
    required this.title,
    required this.excludeIds,
  });

  final List<Medication> initialMedications;
  final String title;
  final Set<String> excludeIds;

  @override
  State<_MedicationPickerSheet> createState() => _MedicationPickerSheetState();
}

class _MedicationPickerSheetState extends State<_MedicationPickerSheet> {
  late List<Medication> _medications;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _medications = List<Medication>.from(widget.initialMedications);
  }

  List<Medication> get _filtered {
    final q = _query.trim().toLowerCase();
    var list = _medications
        .where((m) => !widget.excludeIds.contains(m.id))
        .toList();
    if (q.isEmpty) {
      return list;
    }
    return list
        .where(
          (m) =>
              m.pharmaceuticalName.toLowerCase().contains(q) ||
              m.composition.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _createCustom() async {
    await showAddMedicationSheet(context);
    if (!mounted) return;
    await context.read<MedicationsViewModel>().refresh();
    if (!mounted) return;
    setState(() {
      _medications =
          List<Medication>.from(context.read<MedicationsViewModel>().medications);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingSm,
        right: AppTheme.spacingSm,
        top: AppTheme.spacingMd,
        bottom: bottom + AppTheme.spacingMd,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search medications',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _createCustom,
                icon: const Icon(Icons.add),
                label: const Text('Create custom med'),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No medications found'))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final med = filtered[index];
                        return ListTile(
                          title: Text(med.pharmaceuticalName),
                          subtitle: Text(
                            med.composition,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.of(context).pop(med),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> showDayMedActionsSheet(
  BuildContext context, {
  required String medicationName,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppTheme.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: AppTheme.sheetTopRadius,
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingSm,
            AppTheme.spacingMd,
            AppTheme.spacingSm,
            AppTheme.spacingMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                medicationName,
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Replace'),
                onTap: () => Navigator.of(sheetContext).pop('replace'),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppTheme.error),
                title: Text(
                  'Remove from this day',
                  style: TextStyle(color: AppTheme.error),
                ),
                onTap: () => Navigator.of(sheetContext).pop('remove'),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

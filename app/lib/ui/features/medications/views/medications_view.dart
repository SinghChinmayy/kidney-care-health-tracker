import 'package:app/domain/models/medication.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/features/medications/view_models/medications_view_model.dart';
import 'package:app/ui/features/medications/views/medication_detail_view.dart';
import 'package:app/ui/features/medications/widgets/medication_add_sheet.dart';
import 'package:app/ui/features/medications/widgets/medication_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MedicationsView extends StatefulWidget {
  const MedicationsView({super.key});

  @override
  State<MedicationsView> createState() => _MedicationsViewState();
}

class _MedicationsViewState extends State<MedicationsView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MedicationsViewModel>().refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addMedication() {
    return showAddMedicationSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MedicationsViewModel>();
    final medications = viewModel.medications;

    return Scaffold(
      backgroundColor: AppTheme.bpBackground,
      appBar: const AppScreenAppBar(title: 'Medications'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMedication,
        tooltip: 'Add medication',
        icon: const Icon(Icons.add),
        label: const Text(
          'Add',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingSm,
              AppTheme.spacingXs,
              AppTheme.spacingSm,
              AppTheme.spacingXs,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: viewModel.setQuery,
              decoration: InputDecoration(
                hintText: 'Search name or composition',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: viewModel.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          viewModel.setQuery('');
                        },
                      ),
                filled: true,
                fillColor: AppTheme.cardSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.cardBorder),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: viewModel.refresh,
              child: _buildBody(viewModel, medications),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    MedicationsViewModel viewModel,
    List<Medication> medications,
  ) {
    if (viewModel.isLoading && medications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null && medications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          AppEmptyState(message: viewModel.error!),
        ],
      );
    }

    if (viewModel.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          AppEmptyState(message: 'No medications found.'),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingSm,
        AppTheme.spacingXs,
        AppTheme.spacingSm,
        AppTheme.floatingNavClearance,
      ),
      itemCount: medications.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spacingXs),
      itemBuilder: (context, index) {
        final medication = medications[index];
        return MedicationListTile(
          medication: medication,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MedicationDetailView(medication: medication),
              ),
            );
          },
        );
      },
    );
  }
}

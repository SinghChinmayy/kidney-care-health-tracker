import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/profile/utils/profile_formatters.dart';
import 'package:app/ui/features/profile/view_models/profile_view_model.dart';
import 'package:app/ui/features/profile/widgets/profile_option_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const double _profileContentMaxWidth = 600;

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileViewModel>().refresh();
    });
  }

  Future<void> _pickCkdStage(ProfileViewModel viewModel) async {
    final selected = await showProfileOptionPickerSheet(
      context,
      title: 'CKD stage',
      selectedValue: viewModel.patient?.ckdStage,
      options: [
        for (final value in ckdStageOptions)
          ProfilePickerOption(
            value: value,
            label: formatCkdStageLabel(value),
          ),
      ],
    );
    if (!mounted || selected == null) {
      return;
    }
    final saved = await viewModel.updateCkdStage(selected);
    _showSaveFeedback(saved, viewModel);
  }

  Future<void> _pickDialysisType(ProfileViewModel viewModel) async {
    final selected = await showProfileOptionPickerSheet(
      context,
      title: 'Dialysis',
      selectedValue: viewModel.patient?.dialysisType ?? 'none',
      options: [
        for (final value in dialysisTypeOptions)
          ProfilePickerOption(
            value: value,
            label: formatDialysisTypeLabel(value),
          ),
      ],
    );
    if (!mounted || selected == null) {
      return;
    }
    final saved = await viewModel.updateDialysisType(selected);
    _showSaveFeedback(saved, viewModel);
  }

  Future<void> _pickSex(ProfileViewModel viewModel) async {
    final selected = await showProfileOptionPickerSheet(
      context,
      title: 'Sex',
      selectedValue: viewModel.patient?.sex,
      options: [
        for (final value in sexOptions)
          ProfilePickerOption(value: value, label: value),
      ],
    );
    if (!mounted || selected == null) {
      return;
    }
    final saved = await viewModel.updateSex(selected);
    _showSaveFeedback(saved, viewModel);
  }

  Future<void> _pickDateOfBirth(ProfileViewModel viewModel) async {
    final current = viewModel.patient?.dateOfBirth?.toLocal() ??
        DateTime(DateTime.now().year - 40);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (!mounted || picked == null) {
      return;
    }
    final saved = await viewModel.updateDateOfBirth(
      DateTime(picked.year, picked.month, picked.day),
    );
    _showSaveFeedback(saved, viewModel);
  }

  Future<void> _pickHeight(ProfileViewModel viewModel) async {
    final selected = await showProfileHeightPickerSheet(
      context,
      initialHeightCm: viewModel.patient?.heightCm,
    );
    if (!mounted || selected == null) {
      return;
    }
    final saved = await viewModel.updateHeightCm(selected);
    _showSaveFeedback(saved, viewModel);
  }

  void _showSaveFeedback(bool saved, ProfileViewModel viewModel) {
    if (!mounted) {
      return;
    }
    final message = saved
        ? 'Profile updated'
        : (viewModel.errorMessage ?? 'Could not update profile.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();
    final patient = viewModel.patient;
    final displayName = patient?.displayName?.isNotEmpty == true
        ? patient!.displayName!
        : 'Patient';
    final canEdit = patient != null && !viewModel.isSaving;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _profileContentMaxWidth),
          child: RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              children: [
                Text(
                  'Profile',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  'Your account and kidney care details.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.muted,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                if (viewModel.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingLg),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _ProfileHeader(
                    name: displayName,
                    email: viewModel.email,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  _ProfileSection(
                    title: 'Health details',
                    children: [
                      _ProfileDetailRow(
                        label: 'CKD stage',
                        value: formatCkdStageLabel(patient?.ckdStage),
                        onTap: canEdit ? () => _pickCkdStage(viewModel) : null,
                      ),
                      _ProfileDetailRow(
                        label: 'Dialysis',
                        value: formatDialysisTypeLabel(
                          patient?.dialysisType ?? 'none',
                        ),
                        onTap:
                            canEdit ? () => _pickDialysisType(viewModel) : null,
                      ),
                      _ProfileDetailRow(
                        label: 'Date of birth',
                        value: formatDateOfBirthLabel(patient?.dateOfBirth),
                        onTap:
                            canEdit ? () => _pickDateOfBirth(viewModel) : null,
                      ),
                      _ProfileDetailRow(
                        label: 'Sex',
                        value: formatSexLabel(patient?.sex),
                        onTap: canEdit ? () => _pickSex(viewModel) : null,
                      ),
                      _ProfileDetailRow(
                        label: 'Height',
                        value: formatHeightLabel(patient?.heightCm),
                        onTap: canEdit ? () => _pickHeight(viewModel) : null,
                        isLast: true,
                      ),
                    ],
                  ),
                  if (viewModel.isSaving) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  const SizedBox(height: AppTheme.spacingLg),
                  OutlinedButton.icon(
                    onPressed: viewModel.isSigningOut
                        ? null
                        : () => viewModel.signOut(),
                    style: AppTheme.secondaryButtonStyle(),
                    icon: viewModel.isSigningOut
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout_outlined),
                    label: Text(
                      viewModel.isSigningOut ? 'Signing out…' : 'Sign out',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
  });

  final String name;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: AppTheme.readingCardDecoration,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
              border: Border.all(color: AppTheme.ink),
            ),
            child: Text(
              _initials(name),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (email != null && email!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.muted,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Container(
          decoration: AppTheme.readingCardDecoration,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({
    required this.label,
    required this.value,
    this.onTap,
    this.isLast = false,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppTheme.muted.withValues(alpha: 0.25),
                ),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.muted,
                  ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: AppTheme.spacingXs),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppTheme.muted.withValues(alpha: 0.8),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: content,
      ),
    );
  }
}

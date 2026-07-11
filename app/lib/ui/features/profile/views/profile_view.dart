import 'package:app/debug/agent_debug_log.dart';
import 'package:app/domain/models/patient_preferences.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/profile/utils/profile_formatters.dart';
import 'package:app/ui/features/profile/view_models/profile_view_model.dart';
import 'package:app/ui/features/profile/widgets/profile_option_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const double _profileContentMaxWidth = 600;
const Color _profileAccent = Color(0xFFE57373);

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

  Future<void> _pickDialysisDays(ProfileViewModel viewModel) async {
    final selected = await showProfileDialysisDaysPickerSheet(
      context,
      initialDays: viewModel.patient?.dialysisDaysOfWeek,
    );
    if (!mounted || selected == null) {
      return;
    }
    final saved = await viewModel.updateDialysisDaysOfWeek(selected);
    _showSaveFeedback(saved, viewModel);
  }

  Future<void> _pickName(ProfileViewModel viewModel) async {
    // #region agent log
    final tapAt = DateTime.now().millisecondsSinceEpoch;
    agentDebugLog(
      hypothesisId: 'F',
      location: 'profile_view.dart:_pickName',
      message: 'edit_profile_tap',
      data: {'tapAt': tapAt},
      runId: 'snap-fix',
    );
    // #endregion
    final selected = await showProfileNamePickerSheet(
      context,
      initialFirstName: viewModel.patient?.firstName,
      initialLastName: viewModel.patient?.lastName,
      debugTapAt: tapAt,
    );
    if (!mounted || selected == null) {
      return;
    }
    final saved = await viewModel.updateName(
      firstName: selected.firstName,
      lastName: selected.lastName,
    );
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

  Future<void> _pickWeightUnit(ProfileViewModel viewModel) async {
    final selected = await showProfileOptionPickerSheet(
      context,
      title: 'Weight unit',
      selectedValue: viewModel.preferences?.weightUnit ??
          PatientPreferences.defaultWeightUnit,
      options: [
        for (final value in weightUnitOptions)
          ProfilePickerOption(
            value: value,
            label: formatWeightUnitLabel(value),
          ),
      ],
    );
    if (!mounted || selected == null) {
      return;
    }
    final saved = await viewModel.updateWeightUnit(selected);
    _showSaveFeedback(saved, viewModel, successMessage: 'Preferences updated');
  }

  Future<void> _pickBloodGlucoseUnit(ProfileViewModel viewModel) async {
    final selected = await showProfileOptionPickerSheet(
      context,
      title: 'Glucose unit',
      selectedValue: viewModel.preferences?.bloodGlucoseUnit ??
          PatientPreferences.defaultBloodGlucoseUnit,
      options: [
        for (final value in bloodGlucoseUnitOptions)
          ProfilePickerOption(
            value: value,
            label: formatBloodGlucoseUnitLabel(value),
          ),
      ],
    );
    if (!mounted || selected == null) {
      return;
    }
    final saved = await viewModel.updateBloodGlucoseUnit(selected);
    _showSaveFeedback(saved, viewModel, successMessage: 'Preferences updated');
  }

  Future<void> _pickDailyWaterGoal(ProfileViewModel viewModel) async {
    final selected = await showProfileWaterGoalPickerSheet(
      context,
      initialGoalMl: viewModel.preferences?.dailyWaterGoalMl,
    );
    if (!mounted || selected == null) {
      return;
    }
    final saved = await viewModel.updateDailyWaterGoalMl(selected);
    _showSaveFeedback(saved, viewModel, successMessage: 'Preferences updated');
  }

  void _showSaveFeedback(
    bool saved,
    ProfileViewModel viewModel, {
    String successMessage = 'Profile updated',
  }) {
    if (!mounted) {
      return;
    }
    final message = saved
        ? successMessage
        : (viewModel.errorMessage ?? 'Could not update profile.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();
    final patient = viewModel.patient;
    final preferences = viewModel.preferences;
    final displayName = patient?.displayName?.isNotEmpty == true
        ? patient!.displayName!
        : 'Patient';
    final canEdit = patient != null && !viewModel.isSaving;
    final canEditPreferences = preferences != null && !viewModel.isSaving;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _profileContentMaxWidth),
          child: RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                AppTheme.spacingSm,
                AppTheme.spacingMd,
                AppTheme.spacingLg,
              ),
              children: [
                Text(
                  'My Profile',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                if (viewModel.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingLg),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _ProfileHeader(
                    name: displayName,
                    email: viewModel.email,
                    onEditProfile:
                        canEdit ? () => _pickName(viewModel) : null,
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  _ProfileSection(
                    title: 'Personal',
                    children: [
                      _ProfileDetailRow(
                        icon: Icons.person_outline,
                        label: 'Name',
                        value: displayName,
                        onTap: canEdit ? () => _pickName(viewModel) : null,
                      ),
                      _ProfileDetailRow(
                        icon: Icons.cake_outlined,
                        label: 'Date of birth',
                        value: formatDateOfBirthLabel(patient?.dateOfBirth),
                        onTap:
                            canEdit ? () => _pickDateOfBirth(viewModel) : null,
                      ),
                      _ProfileDetailRow(
                        icon: Icons.wc_outlined,
                        label: 'Sex',
                        value: formatSexLabel(patient?.sex),
                        onTap: canEdit ? () => _pickSex(viewModel) : null,
                      ),
                      _ProfileDetailRow(
                        icon: Icons.height_outlined,
                        label: 'Height',
                        value: formatHeightLabel(patient?.heightCm),
                        onTap: canEdit ? () => _pickHeight(viewModel) : null,
                        isLast: true,
                      ),
                    ],
                  ),
                  const _ProfileSectionDivider(),
                  _ProfileSection(
                    title: 'Kidney care',
                    children: [
                      _ProfileDetailRow(
                        icon: Icons.monitor_heart_outlined,
                        label: 'CKD stage',
                        value: formatCkdStageLabel(patient?.ckdStage),
                        onTap: canEdit ? () => _pickCkdStage(viewModel) : null,
                      ),
                      _ProfileDetailRow(
                        icon: Icons.local_hospital_outlined,
                        label: 'Dialysis',
                        value: formatDialysisTypeLabel(
                          patient?.dialysisType ?? 'none',
                        ),
                        onTap:
                            canEdit ? () => _pickDialysisType(viewModel) : null,
                      ),
                      _ProfileDetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Dialysis days',
                        value: formatDialysisDaysOfWeekLabel(
                          patient?.dialysisDaysOfWeek,
                        ),
                        onTap:
                            canEdit ? () => _pickDialysisDays(viewModel) : null,
                      ),
                      _ProfileDetailRow(
                        icon: Icons.water_drop_outlined,
                        label: 'Daily fluid limit',
                        value: formatDailyWaterGoalLabel(
                          preferences?.dailyWaterGoalMl,
                        ),
                        onTap: canEditPreferences
                            ? () => _pickDailyWaterGoal(viewModel)
                            : null,
                        isLast: true,
                      ),
                    ],
                  ),
                  const _ProfileSectionDivider(),
                  _ProfileSection(
                    title: 'Preferences',
                    children: [
                      _ProfileDetailRow(
                        icon: Icons.monitor_weight_outlined,
                        label: 'Weight unit',
                        value: formatWeightUnitLabel(preferences?.weightUnit),
                        onTap: canEditPreferences
                            ? () => _pickWeightUnit(viewModel)
                            : null,
                      ),
                      _ProfileDetailRow(
                        icon: Icons.bloodtype_outlined,
                        label: 'Glucose unit',
                        value: formatBloodGlucoseUnitLabel(
                          preferences?.bloodGlucoseUnit,
                        ),
                        onTap: canEditPreferences
                            ? () => _pickBloodGlucoseUnit(viewModel)
                            : null,
                        isLast: true,
                      ),
                    ],
                  ),
                  if (viewModel.isSaving) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  const _ProfileSectionDivider(),
                  _LogoutRow(
                    isSigningOut: viewModel.isSigningOut,
                    onTap: viewModel.isSigningOut
                        ? null
                        : () => viewModel.signOut(),
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
    this.onEditProfile,
  });

  final String name;
  final String? email;
  final VoidCallback? onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppTheme.surfaceMuted,
            shape: BoxShape.circle,
          ),
          child: Text(
            _initials(name),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (email != null && email!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  email!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.muted,
                      ),
                ),
              ],
              if (onEditProfile != null) ...[
                const SizedBox(height: AppTheme.spacingXs),
                SizedBox(
                  height: 36,
                  child: FilledButton(
                    onPressed: onEditProfile,
                    style: FilledButton.styleFrom(
                      backgroundColor: _profileAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.cornerRadius),
                      ),
                    ),
                    child: const Text('Edit Profile'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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

class _ProfileSectionDivider extends StatelessWidget {
  const _ProfileSectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppTheme.muted.withValues(alpha: 0.2),
      ),
    );
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
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.muted,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        ...children,
      ],
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.only(
        top: AppTheme.spacingSm,
        bottom: isLast ? AppTheme.spacingXs : AppTheme.spacingSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: AppTheme.muted),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.muted,
                  ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppTheme.muted.withValues(alpha: 0.55),
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
        borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
        child: content,
      ),
    );
  }
}

class _LogoutRow extends StatelessWidget {
  const _LogoutRow({
    required this.isSigningOut,
    this.onTap,
  });

  final bool isSigningOut;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
          child: Row(
            children: [
              if (isSigningOut)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _profileAccent,
                  ),
                )
              else
                const Icon(
                  Icons.logout_outlined,
                  size: 22,
                  color: _profileAccent,
                ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                isSigningOut ? 'Signing out…' : 'Log out',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _profileAccent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

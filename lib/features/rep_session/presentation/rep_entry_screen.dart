import 'package:flutter/material.dart';
import 'package:mivet_app/core/routing/routes.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/utils/extensions.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../data/rep_session_store.dart';
import '../domain/models/rep_profile_model.dart';
import 'widgets/live_date_time_card.dart';
import 'widgets/new_rep_form.dart';
import 'widgets/rep_entry_header.dart';
import 'widgets/saved_reps_list.dart';

class RepEntryScreen extends StatefulWidget {
  const RepEntryScreen({super.key});

  @override
  State<RepEntryScreen> createState() => _RepEntryScreenState();
}

class _RepEntryScreenState extends State<RepEntryScreen> {
  bool _loading = true;
  List<RepProfileModel> _savedReps = [];
  bool _showNewRepForm = false;

  final _nameController = TextEditingController();
  int _selectedAvatarIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedReps();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedReps() async {
    final reps = await RepSessionStore.instance.getSavedReps();
    if (!mounted) return;
    setState(() {
      _savedReps = reps;
      _showNewRepForm = reps.isEmpty;
      _loading = false;
    });
  }

  Future<void> _continueAs(RepProfileModel rep) async {
    final updated = rep.copyWith(lastLoginAt: DateTime.now());
    await RepSessionStore.instance.saveRep(updated);
    await RepSessionStore.instance.setActiveRep(updated.id);
    _goToMain();
  }

  Future<void> _deleteRep(RepProfileModel rep) async {
    await RepSessionStore.instance.removeRep(rep.id);
    await _loadSavedReps();
  }

  Future<void> _createRep() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final now = DateTime.now();
    final rep = RepProfileModel(
      id: now.microsecondsSinceEpoch.toString(),
      name: name,
      avatarIndex: _selectedAvatarIndex,
      createdAt: now,
      lastLoginAt: now,
    );
    await RepSessionStore.instance.saveRep(rep);
    await RepSessionStore.instance.setActiveRep(rep.id);
    _goToMain();
  }

  void _goToMain() {
    if (!mounted) return;
    context.pushReplacementNamed(Routes.mainScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: context.adaptiveMaxContentWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: _loading
                  ? Padding(
                      padding: EdgeInsets.only(top: 80.h),
                      child: const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primaryGreen)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const RepEntryHeader(),
                        SizedBox(height: 20.h),
                        const LiveDateTimeCard(),
                        SizedBox(height: 24.h),
                        Container(
                          padding: EdgeInsets.all(18.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22.r),
                            border: Border.all(color: AppColors.cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: _showNewRepForm
                              ? NewRepForm(
                                  nameController: _nameController,
                                  selectedAvatarIndex: _selectedAvatarIndex,
                                  onAvatarSelected: (i) =>
                                      setState(() => _selectedAvatarIndex = i),
                                  onSubmit: _nameController.text.trim().isEmpty
                                      ? null
                                      : _createRep,
                                  onCancel: _savedReps.isEmpty
                                      ? null
                                      : () => setState(
                                          () => _showNewRepForm = false),
                                )
                              : SavedRepsList(
                                  reps: _savedReps,
                                  onContinue: _continueAs,
                                  onDelete: _deleteRep,
                                  onAddNew: () =>
                                      setState(() => _showNewRepForm = true),
                                ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/errors/app_error_snackbar.dart';
import 'package:mivet_app/core/routing/routes.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/extensions.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../auth/domain/models/user_profile.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../data/owner_service.dart';
import 'widgets/add_rep_dialog.dart';
import 'widgets/rep_list_tile.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final _ownerService = OwnerService();
  List<UserProfile> _reps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReps();
  }

  Future<void> _loadReps() async {
    setState(() => _loading = true);
    try {
      final reps = await _ownerService.getAllReps();
      if (!mounted) return;
      setState(() {
        _reps = reps;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppError(context, e);
    }
  }

  Future<void> _addRep() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => const AddRepDialog(),
    );
    if (added == true) _loadReps();
  }

  Future<void> _deleteRep(UserProfile rep) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف مندوب'),
        content: Text('هل تريد حذف "${rep.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusNotReached,
            ),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _ownerService.deleteRep(rep.id);
      _loadReps();
    } catch (e) {
      if (!mounted) return;
      showAppError(context, e);
    }
  }

  Future<void> _signOut() async {
    await context.read<AuthCubit>().signOut();
    if (mounted) {
      context.pushNamedAndRemoveUntil(
        Routes.loginTypeScreen,
        predicate: (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'لوحة الأونر',
          style: AppTextStyles.cairoBold18
              .copyWith(color: Colors.white, fontSize: 17.sp),
        ),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRep,
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('إضافة مندوب', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : RefreshIndicator(
              onRefresh: _loadReps,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: context.adaptiveMaxContentWidth,
                  ),
                  child: _reps.isEmpty
                      ? ListView(
                          padding: EdgeInsets.all(16.w),
                          children: [
                            SizedBox(height: 100.h),
                            Icon(
                              Icons.people_outline_rounded,
                              size: 64.sp,
                              color: AppColors.navInactive,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'لا يوجد مندوبين بعد',
                              style: AppTextStyles.almaraiRegular14.copyWith(
                                color: AppColors.navInactive,
                                fontSize: 14.sp,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16.w),
                          itemCount: _reps.length,
                          itemBuilder: (context, index) => RepListTile(
                            rep: _reps[index],
                            onDelete: () => _deleteRep(_reps[index]),
                          ),
                        ),
                ),
              ),
            ),
    );
  }
}

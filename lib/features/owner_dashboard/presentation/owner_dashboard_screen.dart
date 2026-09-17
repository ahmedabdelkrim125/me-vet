import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/routing/routes.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/extensions.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../auth/domain/models/user_profile.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../data/owner_service.dart';
import 'cubit/owner_dashboard_cubit.dart';
import 'cubit/owner_dashboard_state.dart';
import 'widgets/add_rep_dialog.dart';
import 'widgets/rep_list_tile.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OwnerDashboardCubit(OwnerService())..loadReps(),
      child: const _OwnerDashboardView(),
    );
  }
}

class _OwnerDashboardView extends StatelessWidget {
  const _OwnerDashboardView();

  Future<void> _addRep(BuildContext context) async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => const AddRepDialog(),
    );
    if (added == true && context.mounted) {
      context.read<OwnerDashboardCubit>().loadReps();
    }
  }

  Future<void> _editRep(BuildContext context, UserProfile rep) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => AddRepDialog(rep: rep),
    );
    if (updated == true && context.mounted) {
      context.read<OwnerDashboardCubit>().loadReps();
    }
  }

  Future<void> _deactivateRep(BuildContext context, UserProfile rep) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعطيل مندوب'),
        content: Text('هل تريد تعطيل "${rep.name}"؟'),
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
            child: const Text('تعطيل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<OwnerDashboardCubit>().deactivateRep(rep.id);
    }
  }

  Future<void> _reactivateRep(BuildContext context, UserProfile rep) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تفعيل مندوب'),
        content: Text('هل تريد إعادة تفعيل المندوب "${rep.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            child: const Text('تفعيل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<OwnerDashboardCubit>().reactivateRep(rep.id);
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await context.read<AuthCubit>().signOut();
    if (context.mounted) {
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
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addRep(context),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('إضافة مندوب', style: TextStyle(color: Colors.white)),
      ),
      body: BlocConsumer<OwnerDashboardCubit, OwnerDashboardState>(
        listenWhen: (previous, current) => previous.error != current.error,
        listener: (context, state) {
          if (state.error != null) {
            showAppError(context, state.error!);
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.reps.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<OwnerDashboardCubit>().loadReps(),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: context.adaptiveMaxContentWidth,
                ),
                child: state.reps.isEmpty
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
                        itemCount: state.reps.length,
                        itemBuilder: (context, index) {
                          final rep = state.reps[index];
                          return RepListTile(
                            rep: rep,
                            onEdit: () => _editRep(context, rep),
                            onDeactivate: () => _deactivateRep(context, rep),
                            onReactivate: () => _reactivateRep(context, rep),
                          );
                        },
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

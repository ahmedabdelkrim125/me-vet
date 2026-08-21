import 'package:flutter/material.dart';
import 'package:mivet_app/core/routing/routes.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/utils/extensions.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/auth/data/auth_service.dart';
import 'package:mivet_app/features/auth/domain/models/user_profile.dart';
import 'package:mivet_app/features/owner_dashboard/data/owner_service.dart';
import 'widgets/add_rep_dialog.dart';
import 'widgets/rep_list_tile.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  List<UserProfile> _reps = [];
  bool _loading = true;
  UserProfile? _currentOwner;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    try {
      final owner = await AuthService.instance.getCurrentUser();
      final reps = await OwnerService.instance.getAllReps();
      
      if (!mounted) return;
      setState(() {
        _currentOwner = owner;
        _reps = reps;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج؟'),
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
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuthService.instance.signOut();
      if (mounted) {
        context.pushReplacementNamed(Routes.ownerLoginScreen);
      }
    }
  }

  Future<void> _showAddRepDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddRepDialog(),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteRep(UserProfile rep) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف مندوب'),
        content: Text('هل تريد حذف "${rep.name}"؟\nهذا سيحذف جميع بياناته نهائياً.'),
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
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await OwnerService.instance.deleteRep(rep.id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف المندوب بنجاح')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في الحذف: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'لوحة تحكم المدير',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: context.adaptiveMaxContentWidth,
                  ),
                  child: ListView(
                    padding: EdgeInsets.all(16.w),
                    children: [
                      // معلومات المدير
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28.w,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.admin_panel_settings_rounded,
                                color: AppColors.primaryGreen,
                                size: 32.w,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentOwner?.name ?? 'المدير',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'صاحب التطبيق',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 13.sp,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      // عنوان القائمة
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'المندوبين (${_reps.length})',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                              fontSize: 18.sp,
                              color: AppColors.primary,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showAddRepDialog,
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text('إضافة مندوب'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      // قائمة المندوبين
                      if (_reps.isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 80.h),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 64.w,
                                  color: AppColors.navInactive,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'لا يوجد مندوبين بعد',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14.sp,
                                    color: AppColors.navInactive,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._reps.map((rep) => RepListTile(
                              rep: rep,
                              onDelete: () => _deleteRep(rep),
                            )),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

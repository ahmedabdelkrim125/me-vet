import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_exception.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// الأونر يقدر يغيّر كلمة مروره بنفسه من هنا، بدل ما يرجع للمطور في كل مرة.
///
/// الجلسة الحالية نفسها هي إثبات الهوية، فـSupabase Auth مش بيطلب كلمة
/// المرور القديمة لتغييرها — بس بنطلب تأكيد الكلمة الجديدة مرتين هنا.
class OwnerChangePasswordScreen extends StatefulWidget {
  const OwnerChangePasswordScreen({super.key});

  @override
  State<OwnerChangePasswordScreen> createState() =>
      _OwnerChangePasswordScreenState();
}

class _OwnerChangePasswordScreenState
    extends State<OwnerChangePasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final newPassword = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (newPassword.length < 6) {
      setState(() => _error = 'كلمة المرور لازم تكون 6 حروف أو أرقام على الأقل');
      return;
    }
    if (newPassword != confirm) {
      setState(() => _error = 'كلمة المرور وتأكيدها مش متطابقين');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(password: newPassword));
      if (!mounted) return;
      showAppInfo(context, 'اتغيّرت كلمة المرور بنجاح');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = mapErrorToAppException(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'تغيير كلمة المرور',
          style: AppTextStyles.cairoBold18
              .copyWith(color: Colors.white, fontSize: 17.sp),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              textDirection: TextDirection.ltr,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'تأكيد كلمة المرور الجديدة',
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            if (_error != null) ...[
              SizedBox(height: 12.h),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.statusNotReached, fontSize: 13.sp),
              ),
            ],
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
              child: _loading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('حفظ',
                      style: AppTextStyles.cairoMedium16
                          .copyWith(color: Colors.white, fontSize: 15.sp)),
            ),
          ],
        ),
      ),
    );
  }
}

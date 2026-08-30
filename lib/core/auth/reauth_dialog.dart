import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mivet_app/core/errors/app_exception.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../features/auth/domain/models/user_profile.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

Future<bool> confirmIdentity(BuildContext context,
    {required String actionLabel}) async {
  final isOwner = context.read<AuthCubit>().state.user?.role == UserRole.owner;
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _ReauthDialog(actionLabel: actionLabel, isOwner: isOwner),
  );
  return result ?? false;
}

class _ReauthDialog extends StatefulWidget {
  final String actionLabel;
  final bool isOwner;

  const _ReauthDialog({required this.actionLabel, required this.isOwner});

  @override
  State<_ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends State<_ReauthDialog> {
  final _controller = TextEditingController();
  bool _isVerifying = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorText = widget.isOwner ? 'اكتب كلمة المرور' : 'اكتب رمز الـ PIN';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null) {
      setState(() {
        _isVerifying = false;
        _errorText = 'تعذر التأكد من هويتك، حاول تسجل دخول تاني';
      });
      return;
    }

    try {
      await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: code);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorText = mapErrorToAppException(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        'تأكيد الهوية',
        style: AppTextStyles.cairoBold18
            .copyWith(color: colors.text, fontSize: 16.sp),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اكتب ${widget.isOwner ? 'كلمة المرور' : 'رمز الـ PIN'} بتاعك عشان تأكد ${widget.actionLabel}',
            style: AppTextStyles.almaraiRegular14
                .copyWith(color: colors.textMuted, fontSize: 12.sp),
          ),
          SizedBox(height: 14.h),
          TextField(
            controller: _controller,
            obscureText: true,
            autofocus: true,
            keyboardType: widget.isOwner
                ? TextInputType.visiblePassword
                : TextInputType.number,
            maxLength: widget.isOwner ? null : 4,
            onSubmitted: (_) => _verify(),
            style: AppTextStyles.cairoRegular14.copyWith(color: colors.text),
            decoration: InputDecoration(
              counterText: '',
              errorText: _errorText,
              filled: true,
              fillColor: colors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed:
              _isVerifying ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isVerifying ? null : _verify,
          style: ElevatedButton.styleFrom(
              backgroundColor: colors.statusNotReached),
          child: _isVerifying
              ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('تأكيد', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

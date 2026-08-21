import 'package:flutter/material.dart';
import 'package:mivet_app/core/routing/routes.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/utils/extensions.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/auth/data/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/login_button.dart';
import 'widgets/login_header.dart';
import 'widgets/phone_input_field.dart';
import 'widgets/pin_input_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  
  String? _phoneError;
  String? _pinError;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();
    return phone.length == 11 && pin.length == 4 && !_isLoading;
  }

  Future<void> _handleLogin() async {
    setState(() {
      _phoneError = null;
      _pinError = null;
      _isLoading = true;
    });

    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    // التحقق من الإدخال
    if (phone.length != 11) {
      setState(() {
        _phoneError = 'رقم الموبايل يجب أن يكون 11 رقم';
        _isLoading = false;
      });
      return;
    }

    if (pin.length != 4) {
      setState(() {
        _pinError = 'رمز PIN يجب أن يكون 4 أرقام';
        _isLoading = false;
      });
      return;
    }

    try {
      final profile = await AuthService.instance.signInWithPhone(phone, pin);
      
      if (!mounted) return;

      if (profile != null) {
        // نجح تسجيل الدخول
        context.pushReplacementNamed(Routes.mainScreen);
      } else {
        setState(() {
          _pinError = 'فشل تسجيل الدخول';
          _isLoading = false;
        });
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.message.contains('Invalid login') || 
            e.message.contains('credentials')) {
          _pinError = 'رقم الموبايل أو رمز PIN غير صحيح';
        } else {
          _pinError = 'حدث خطأ: ${e.message}';
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pinError = 'حدث خطأ غير متوقع';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.adaptiveMaxContentWidth,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 40.h),
                  const LoginHeader(),
                  SizedBox(height: 48.h),
                  Container(
                    padding: EdgeInsets.all(20.w),
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
                    child: Column(
                      children: [
                        PhoneInputField(
                          controller: _phoneController,
                          errorText: _phoneError,
                        ),
                        SizedBox(height: 20.h),
                        PinInputField(
                          controller: _pinController,
                          errorText: _pinError,
                        ),
                        SizedBox(height: 32.h),
                        LoginButton(
                          onPressed: _canSubmit ? _handleLogin : null,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'إذا لم يكن لديك حساب، تواصل مع المدير',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.navInactive,
                          fontSize: 13.sp,
                        ),
                    textAlign: TextAlign.center,
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

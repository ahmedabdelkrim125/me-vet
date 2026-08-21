import 'package:flutter/material.dart';
import 'package:mivet_app/core/routing/routes.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/utils/extensions.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/auth/data/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/login_header.dart';
import 'widgets/owner_email_input_field.dart';
import 'widgets/owner_password_input_field.dart';
import 'widgets/login_button.dart';

class OwnerLoginScreen extends StatefulWidget {
  const OwnerLoginScreen({super.key});

  @override
  State<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends State<OwnerLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    return email.isNotEmpty && password.isNotEmpty && !_isLoading;
  }

  Future<void> _handleLogin() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final profile = await AuthService.instance.signInWithEmail(email, password);
      
      if (!mounted) return;

      if (profile != null) {
        // نجح تسجيل الدخول - الانتقال لـ Owner Dashboard
        context.pushReplacementNamed(Routes.ownerDashboard);
      } else {
        setState(() {
          _passwordError = 'فشل تسجيل الدخول';
          _isLoading = false;
        });
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.message.contains('Invalid login') || 
            e.message.contains('credentials')) {
          _passwordError = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
        } else {
          _passwordError = 'حدث خطأ: ${e.message}';
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _passwordError = e.toString().replaceAll('Exception: ', '');
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
                  SizedBox(height: 16.h),
                  Text(
                    'تسجيل دخول المدير',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryGreen,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32.h),
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
                        OwnerEmailInputField(
                          controller: _emailController,
                          errorText: _emailError,
                        ),
                        SizedBox(height: 20.h),
                        OwnerPasswordInputField(
                          controller: _passwordController,
                          errorText: _passwordError,
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
                  TextButton(
                    onPressed: () {
                      context.pushReplacementNamed(Routes.loginScreen);
                    },
                    child: Text(
                      'تسجيل دخول كمندوب →',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primaryGreen,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
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

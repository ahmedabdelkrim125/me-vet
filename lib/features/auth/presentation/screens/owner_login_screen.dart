import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/routing/routes.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/utils/extensions.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/login_button.dart';
import '../widgets/login_header.dart';
import '../widgets/owner_email_input_field.dart';
import '../widgets/owner_password_input_field.dart';

class OwnerLoginScreen extends StatefulWidget {
  const OwnerLoginScreen({super.key});

  @override
  State<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends State<OwnerLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.trim().isNotEmpty;

  void _submit() {
    context.read<AuthCubit>().signInAsOwner(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.authenticated) {
              context.pushNamedAndRemoveUntil(
                Routes.ownerDashboard,
                predicate: (_) => false,
              );
            }
            if (state.status == AuthStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage ?? 'حدث خطأ')),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state.status == AuthStatus.loading;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: context.adaptiveMaxContentWidth,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 24.h),
                      const LoginHeader(subtitle: 'تسجيل دخول الأونر'),
                      SizedBox(height: 40.h),
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
                            OwnerEmailInputField(controller: _emailController),
                            SizedBox(height: 20.h),
                            OwnerPasswordInputField(
                              controller: _passwordController,
                            ),
                            SizedBox(height: 32.h),
                            LoginButton(
                              isLoading: isLoading,
                              onPressed: _canSubmit ? _submit : null,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      TextButton(
                        onPressed: () =>
                            context.pushReplacementNamed(Routes.repLoginScreen),
                        child: Text(
                          'تسجيل دخول كمندوب ←',
                          style: TextStyle(
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
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/errors/app_exception.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/routing/routes.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/utils/extensions.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/login_button.dart';
import '../widgets/login_header.dart';
import '../widgets/phone_input_field.dart';
import '../widgets/pin_input_field.dart';

class RepLoginScreen extends StatefulWidget {
  const RepLoginScreen({super.key});

  @override
  State<RepLoginScreen> createState() => _RepLoginScreenState();
}

class _RepLoginScreenState extends State<RepLoginScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
    _pinController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _phoneController.text.trim().length == 11 &&
      _pinController.text.trim().length == 4;

  void _submit() {
    context.read<AuthCubit>().signInAsRep(
          phone: _phoneController.text.trim(),
          pin: _pinController.text.trim(),
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
                Routes.mainScreen,
                predicate: (_) => false,
              );
            }
            if (state.status == AuthStatus.error) {
              showAppError(
                context,
                AppException(state.errorMessage ?? 'حدث خطأ'),
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
                      const LoginHeader(subtitle: 'سجّل دخولك برقمك ورمزك'),
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
                            PhoneInputField(controller: _phoneController),
                            SizedBox(height: 20.h),
                            PinInputField(controller: _pinController),
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
                        onPressed: () => context
                            .pushReplacementNamed(Routes.ownerLoginScreen),
                        child: Text(
                          'تسجيل دخول كأونر ←',
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

import 'package:flutter/material.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../../core/const/app_images.dart';
import '../../../../core/theme/app_color_scheme_extension.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../splash_screen.dart';

class SplashNetworkIssueBody extends StatelessWidget {
  final SplashNetworkIssue issue;

  const SplashNetworkIssueBody({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    final message = issue == SplashNetworkIssue.offline
        ? 'مفيش اتصال بالإنترنت، هنحاول الاتصال تلقائيًا عند عودة الشبكة.'
        : 'الاتصال بالإنترنت ضعيف، جاري المحاولة تلقائيًا...';

    return Center(
      child: AdaptiveContentWrapper(
        alignment: Alignment.center,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                AppImages.errorIllustration,
                width: 250.w,
                height: 250.h,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 24.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.tajawalMedium16.copyWith(
                  color: context.colors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

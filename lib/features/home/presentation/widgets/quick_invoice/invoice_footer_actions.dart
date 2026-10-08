import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_outlined_icon_button.dart';

class InvoiceFooterActions extends StatelessWidget {
  final bool canIssue;
  final bool isIssuing;
  final VoidCallback onSave;
  final VoidCallback onPrint;
  final VoidCallback onShareWhatsapp;

  const InvoiceFooterActions({
    super.key,
        required this.canIssue,
    required this.onSave,
    required this.onPrint,
    required this.onShareWhatsapp,
    this.isIssuing = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canIssue ? onSave : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                disabledBackgroundColor: colors.primary.withOpacity(0.35),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
              icon: isIssuing
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(Icons.save_alt_rounded,
                      color: Colors.white, size: 20.sp),
              label: Text(
                isIssuing ? 'جاري الإصدار...' : 'حفظ وإصدار الفاتورة',
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: Colors.white, fontSize: 13.sp),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          InvoiceOutlinedIconButton(
            icon: Icon(
              Icons.print_outlined,
              color: colors.text,
              size: 22.sp,
            ),
            color: colors.text,
            onTap: onPrint,
          ),
          SizedBox(width: 8.w),
          InvoiceOutlinedIconButton(
            icon: FaIcon(
              FontAwesomeIcons.whatsapp,
              color: const Color(0xFF25D366),
              size: 22.sp,
            ),
            color: const Color(0xFF25D366),
            onTap: onShareWhatsapp,
          ),
        ],
      ),
    );
  }
}

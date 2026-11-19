import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class InvoiceDetailFooterActions extends StatelessWidget {
  final VoidCallback onPrint;
  final VoidCallback onShare;
  final VoidCallback? onDelete;

  const InvoiceDetailFooterActions({
    super.key,
    required this.onPrint,
    required this.onShare,
    this.onDelete,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPrint,
                  icon: Icon(Icons.print_outlined, size: 18.sp),
                  label: const Text('طباعة'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onShare,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.whatsappGreen,
                  ),
                  icon: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'مشاركة',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          if (onDelete != null) ...[
            SizedBox(height: 8.h),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: colors.statusNotReached,
                ),
                icon: Icon(Icons.delete_outline_rounded, size: 18.sp),
                label: const Text('حذف الفاتورة'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

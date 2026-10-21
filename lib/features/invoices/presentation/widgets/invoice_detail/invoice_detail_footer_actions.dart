import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class InvoiceDetailFooterActions extends StatelessWidget {
  final VoidCallback onPrint;
  final VoidCallback onShare;

  const InvoiceDetailFooterActions({
    super.key,
    required this.onPrint,
    required this.onShare,
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
                backgroundColor: const Color(0xFF25D366),
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
    );
  }
}

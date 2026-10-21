import 'package:flutter/material.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class InvoiceOutlinedIconButton extends StatelessWidget {
  final Widget icon;
  final Color color;
  final VoidCallback onTap;

  const InvoiceOutlinedIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: 14.h,
          ),
          child: icon,
        ),
      ),
    );
  }
}

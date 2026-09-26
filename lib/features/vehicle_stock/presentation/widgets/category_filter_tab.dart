import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class CategoryFilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CategoryFilterTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  bool get _manageable => onEdit != null && onDelete != null;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : context.colors.text;

    return Material(
      color: selected ? context.colors.primary : context.colors.surface,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: _manageable ? 10.w : 14.w,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: selected ? Colors.transparent : context.colors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.cairoMedium16.copyWith(
                  color: foreground,
                  fontSize: 12.sp,
                ),
              ),
              if (_manageable)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  splashRadius: 14.r,
                  // تم إزالة BoxConstraints ليأخذ الـ PopupMenu الحجم الطبيعي للـ Items
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 16.sp,
                    color: foreground,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('تعديل التصنيف'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('حذف التصنيف'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

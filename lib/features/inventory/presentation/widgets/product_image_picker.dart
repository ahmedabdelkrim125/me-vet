import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class ProductImagePicker extends StatelessWidget {
  final String? imagePath;
  final ValueChanged<String?> onChanged;

  const ProductImagePicker({
    super.key,
    required this.imagePath,
    required this.onChanged,
  });

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );

    if (picked != null) {
      onChanged(picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    return Row(
      children: [
        GestureDetector(
          onTap: () => _pickImage(context),
          child: Container(
            width: 72.w,
            height: 72.w,
            decoration: BoxDecoration(
              color: context.colors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: context.colors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? Image.file(File(imagePath!), fit: BoxFit.cover)
                : Icon(Icons.add_photo_alternate_outlined,
                    color: context.colors.primary, size: 26.sp),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'صورة المنتج (اختياري)',
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: context.colors.text, fontSize: 12.sp),
              ),
              SizedBox(height: 4.h),
              GestureDetector(
                onTap: () => _pickImage(context),
                child: Text(
                  hasImage ? 'تغيير الصورة' : 'إضافة صورة من المعرض',
                  style: AppTextStyles.almaraiRegular14
                      .copyWith(color: context.colors.primary, fontSize: 11.sp),
                ),
              ),
              if (hasImage) ...[
                SizedBox(height: 4.h),
                GestureDetector(
                  onTap: () => onChanged(null),
                  child: Text(
                    'إزالة الصورة',
                    style: AppTextStyles.almaraiRegular14.copyWith(
                        color: context.colors.statusNotReached,
                        fontSize: 11.sp),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

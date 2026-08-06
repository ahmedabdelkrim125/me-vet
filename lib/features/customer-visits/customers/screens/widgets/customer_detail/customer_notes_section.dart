import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class CustomerNotesSection extends StatefulWidget {
  final String initialNotes;

  const CustomerNotesSection({super.key, required this.initialNotes});

  @override
  State<CustomerNotesSection> createState() => _CustomerNotesSectionState();
}

class _CustomerNotesSectionState extends State<CustomerNotesSection> {
  late final TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('ملاحظات المندوب',
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: AppColors.primary, fontSize: 13.sp)),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _editing = !_editing),
                child: Text(
                  _editing ? 'حفظ' : 'تعديل',
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: AppColors.primaryGreen, fontSize: 12.sp),
                ),
              ),
            ],
          ),
          if (_editing)
            TextField(
              controller: _controller,
              maxLines: 4,
              textAlign: TextAlign.right,
              style: AppTextStyles.cairoRegular14
                  .copyWith(color: AppColors.primary),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.backgroundLight,
                contentPadding: EdgeInsets.all(12.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            )
          else
            Text(
              _controller.text.isEmpty ? 'لا توجد ملاحظات' : _controller.text,
              style: AppTextStyles.almaraiRegular14.copyWith(
                  color: AppColors.navInactive, fontSize: 12.sp, height: 1.6),
            ),
        ],
      ),
    );
  }
}

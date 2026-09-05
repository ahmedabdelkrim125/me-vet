import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../data/customers_repository.dart';

class CustomerNotesSection extends StatefulWidget {
  final String customerId;
  final String initialNotes;

  const CustomerNotesSection({
    super.key,
    required this.customerId,
    required this.initialNotes,
  });

  @override
  State<CustomerNotesSection> createState() => _CustomerNotesSectionState();
}

class _CustomerNotesSectionState extends State<CustomerNotesSection> {
  late final TextEditingController _controller;
  bool _editing = false;
  bool _saving = false;

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

  Future<void> _toggleEditOrSave() async {
    if (!_editing) {
      setState(() => _editing = true);
      return;
    }

    setState(() => _saving = true);
    try {
      await CustomersRepository.instance
          .updateCustomerNotes(widget.customerId, _controller.text.trim());
      if (!mounted) return;
      setState(() {
        _editing = false;
        _saving = false;
      });
      showAppSuccess(context, 'تم حفظ الملاحظات');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('ملاحظات المندوب',
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.text, fontSize: 13.sp)),
              const Spacer(),
              _saving
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: colors.primary),
                    )
                  : TextButton(
                      onPressed: _toggleEditOrSave,
                      child: Text(
                        _editing ? 'حفظ' : 'تعديل',
                        style: AppTextStyles.cairoMedium16
                            .copyWith(color: colors.primary, fontSize: 12.sp),
                      ),
                    ),
            ],
          ),
          if (_editing)
            TextField(
              controller: _controller,
              maxLines: 4,
              textAlign: TextAlign.right,
              style: AppTextStyles.cairoRegular14.copyWith(color: colors.text),
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.background,
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
                  color: colors.textMuted, fontSize: 12.sp, height: 1.6),
            ),
        ],
      ),
    );
  }
}

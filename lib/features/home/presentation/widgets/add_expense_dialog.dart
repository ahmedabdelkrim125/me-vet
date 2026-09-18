import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_color_scheme_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_extension.dart';
import '../../data/expense_repository.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/expense_state.dart';

class AddExpenseDialog extends StatelessWidget {
  const AddExpenseDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExpenseCubit(sl<ExpenseRepository>()),
      child: const _AddExpenseDialogView(),
    );
  }
}

class _AddExpenseDialogView extends StatefulWidget {
  const _AddExpenseDialogView();

  @override
  State<_AddExpenseDialogView> createState() => _AddExpenseDialogViewState();
}

class _AddExpenseDialogViewState extends State<_AddExpenseDialogView> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedPaymentMethod = 'cash';

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      context.read<ExpenseCubit>().submitExpense(
            amount: amount,
            category: _categoryController.text.trim(),
            paymentMethod: _selectedPaymentMethod,
            notes: _notesController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocListener<ExpenseCubit, ExpenseState>(
      listener: (context, state) {
        if (state is ExpenseSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة المصروف بنجاح', style: TextStyle(color: Colors.white)),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state is ExpenseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: const TextStyle(color: Colors.white)),
              backgroundColor: AppColors.statusNotReached,
            ),
          );
        }
      },
      child: Dialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('إضافة مصروف',
                        style: AppTextStyles.cairoBold18.copyWith(color: colors.text)),
                    IconButton(
                      icon: Icon(Icons.close, color: colors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'المبلغ',
                    labelStyle: AppTextStyles.cairoMedium16.copyWith(color: colors.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'يرجى إدخال المبلغ';
                    if (double.tryParse(value) == null) return 'قيمة غير صالحة';
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'التصنيف',
                    labelStyle: AppTextStyles.cairoMedium16.copyWith(color: colors.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'يرجى إدخال التصنيف' : null,
                ),
                SizedBox(height: 16.h),
                DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
                  decoration: InputDecoration(
                    labelText: 'طريقة الدفع',
                    labelStyle: AppTextStyles.cairoMedium16.copyWith(color: colors.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('كاش')),
                    DropdownMenuItem(value: 'vodafone_cash', child: Text('فودافون كاش')),
                    DropdownMenuItem(value: 'instapay', child: Text('InstaPay')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPaymentMethod = value);
                    }
                  },
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    labelStyle: AppTextStyles.cairoMedium16.copyWith(color: colors.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
                SizedBox(height: 32.h),
                BlocBuilder<ExpenseCubit, ExpenseState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      onPressed: state is ExpenseLoading ? null : _submit,
                      child: state is ExpenseLoading
                          ? SizedBox(
                              width: 24.w,
                              height: 24.w,
                              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text('حفظ المصروف',
                              style: AppTextStyles.cairoBold18.copyWith(color: Colors.white)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
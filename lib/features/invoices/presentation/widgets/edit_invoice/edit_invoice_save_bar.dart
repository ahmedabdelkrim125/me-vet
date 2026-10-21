import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/invoices/presentation/cubit/edit_invoice_cubit.dart';
import 'package:mivet_app/features/invoices/presentation/cubit/edit_invoice_state.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/edit_invoice/edit_invoice_actions.dart';

class EditInvoiceSaveBar extends StatelessWidget {
  const EditInvoiceSaveBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48.h,
        child: BlocSelector<EditInvoiceCubit, EditInvoiceState, bool>(
          selector: (state) => state.saving,
          builder: (context, saving) => ElevatedButton(
            onPressed: saving ? null : () => requestSaveInvoice(context),
            child: saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('حفظ التعديلات'),
          ),
        ),
      ),
    );
  }
}

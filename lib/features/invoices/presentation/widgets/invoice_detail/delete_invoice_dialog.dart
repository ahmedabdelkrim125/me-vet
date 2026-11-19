import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/features/invoices/data/invoice_deletion_service.dart';
import 'package:mivet_app/features/invoices/data/invoices_repository.dart';

class DeleteInvoiceDialog extends StatefulWidget {
  final InvoiceFullDetail detail;
  final String customerName;
  final double paidAmount;

  const DeleteInvoiceDialog({
    super.key,
    required this.detail,
    required this.customerName,
    required this.paidAmount,
  });

  @override
  State<DeleteInvoiceDialog> createState() => _DeleteInvoiceDialogState();
}

class _DeleteInvoiceDialogState extends State<DeleteInvoiceDialog> {
  final TextEditingController _password = TextEditingController();
  final TextEditingController _reason = TextEditingController();
  bool _obscure = true;
  bool _deleting = false;
  String? _passwordError;

  String _format(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  @override
  void dispose() {
    _password.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_deleting || _password.text.isEmpty) return;
    setState(() {
      _deleting = true;
      _passwordError = null;
    });
    try {
      final deleted = await InvoiceDeletionService.instance.deleteInvoice(
        invoiceId: widget.detail.id,
        ownerPassword: _password.text,
        reason: _reason.text,
      );
      if (!mounted) return;
      if (!deleted) {
        setState(() => _passwordError = 'باسورد الأونر غير صحيح');
        return;
      }
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showAppError(context, error);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final mutedStyle = TextStyle(fontSize: 12, color: colors.textMuted);
    final hasPayment = widget.paidAmount > 0;

    return AlertDialog(
      title: Text('حذف الفاتورة ${widget.detail.code}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'العميل: ${widget.customerName}\nإجمالي الفاتورة: ${_format(widget.detail.totalAmount)} ج.م',
            ),
            const SizedBox(height: 8),
            Text(
              'هتتمسح الفاتورة وأصنافها نهائيًا، والكميات هترجع لمخزن العربية، ومديونية العميل هتتعدل.',
              style: mutedStyle,
            ),
            if (hasPayment) ...[
              const SizedBox(height: 8),
              Text(
                'المدفوع على الفاتورة (${_format(widget.paidAmount)} ج.م) مش هيتمسح، هيفضل للعميل كرصيد دائن تقدر ترجعهوله أو تخصمه من فاتورة تانية.',
                style: mutedStyle.copyWith(color: colors.statusNotReached),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _password,
              obscureText: _obscure,
              autofocus: true,
              enabled: !_deleting,
              onChanged: (_) => setState(() => _passwordError = null),
              decoration: InputDecoration(
                labelText: 'باسورد الأونر',
                errorText: _passwordError,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              enabled: !_deleting,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'سبب الحذف (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _deleting || _password.text.isEmpty ? null : _delete,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.statusNotReached,
            foregroundColor: Colors.white,
          ),
          child: _deleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('حذف نهائي'),
        ),
      ],
    );
  }
}

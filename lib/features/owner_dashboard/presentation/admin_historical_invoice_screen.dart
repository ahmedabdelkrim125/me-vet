import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../customer-visits/customers/domain/models/customer_model.dart';
import '../../customer_account/domain/entities/payment_method.dart';
import '../../inventory/data/products_repository.dart';
import '../../inventory/domain/models/product_model.dart';

class AdminHistoricalInvoiceScreen extends StatefulWidget {
  final CustomerModel customer;

  const AdminHistoricalInvoiceScreen({super.key, required this.customer});

  @override
  State<AdminHistoricalInvoiceScreen> createState() =>
      _AdminHistoricalInvoiceScreenState();
}

class _LineItem {
  final ProductModel product;
  int quantity;
  double unitPrice;

  _LineItem(
      {required this.product, required this.quantity, required this.unitPrice});

  double get total => quantity * unitPrice;
}

class _AdminHistoricalInvoiceScreenState
    extends State<AdminHistoricalInvoiceScreen> {
  final _discountController = TextEditingController(text: '0');
  final _paidNowController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  DateTime _invoiceDate = DateTime.now();
  bool _isCashSale = false;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final List<_LineItem> _lines = [];
  List<ProductModel> _catalog = [];
  bool _loadingCatalog = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _discountController.dispose();
    _paidNowController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    try {
      final products = await ProductsRepository.instance.getProducts();
      if (!mounted) return;
      setState(() {
        _catalog = products;
        _loadingCatalog = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCatalog = false);
      showAppError(context, e);
    }
  }

  double get _subtotal => _lines.fold(0, (sum, l) => sum + l.total);
  double get _discountAmount =>
      double.tryParse(_discountController.text.trim()) ?? 0;
  double get _total => _subtotal - _discountAmount;
  double get _paidNow => double.tryParse(_paidNowController.text.trim()) ?? 0;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _invoiceDate = picked);
  }

  Future<void> _addProduct() async {
    final product = await showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductPickerSheet(catalog: _catalog),
    );
    if (product == null) return;

    final existing = _lines.indexWhere((l) => l.product.id == product.id);
    if (existing != -1) {
      setState(() => _lines[existing].quantity += 1);
      return;
    }

    final line =
        _LineItem(product: product, quantity: 1, unitPrice: product.basePrice);
    final edited = await _editLine(line);
    if (edited == true) setState(() => _lines.add(line));
  }

  Future<bool?> _editLine(_LineItem line) {
    final qtyController = TextEditingController(text: '${line.quantity}');
    final priceController =
        TextEditingController(text: line.unitPrice.toStringAsFixed(2));

    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(line.product.name,
            style: AppTextStyles.cairoMedium16.copyWith(fontSize: 14.sp)),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'الكمية'),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: TextField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'السعر'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(qtyController.text.trim()) ?? 0;
              final price = double.tryParse(priceController.text.trim()) ?? 0;
              if (qty <= 0 || price < 0) return;
              line.quantity = qty;
              line.unitPrice = price;
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen),
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_lines.isEmpty) {
      showAppInfo(context, 'ضيف صنف واحد على الأقل قبل الحفظ');
      return;
    }
    if (_discountAmount < 0) {
      showAppInfo(context, 'قيمة الخصم غير صحيحة');
      return;
    }
    if (_discountAmount > _subtotal) {
      showAppInfo(context, 'قيمة الخصم أكبر من إجمالي الفاتورة');
      return;
    }
    if (_paidNow > _total) {
      showAppInfo(context, 'المدفوع أكبر من إجمالي الفاتورة');
      return;
    }

    setState(() => _submitting = true);
    try {
      await Supabase.instance.client.rpc(
        'admin_issue_historical_invoice_v2',
        params: {
          'p_customer_id': widget.customer.id,
          'p_items': _lines
              .map((l) => {
                    'product_id': l.product.id,
                    'product_name': l.product.name,
                    'unit_price': l.unitPrice,
                    'quantity': l.quantity,
                  })
              .toList(),
          'p_invoice_date': _invoiceDate.toIso8601String(),
          'p_discount_amount': _discountAmount,
          'p_sale_type': _isCashSale ? 'cash' : 'credit',
          'p_paid_now': _paidNow,
          'p_payment_method': _paidNow > 0 ? _paymentMethod.backendValue : null,
          'p_notes': _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        },
      );

      if (!mounted) return;
      showAppInfo(context, 'اتسجلت الفاتورة التاريخية بنجاح');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showAppError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'فاتورة تاريخية — ${widget.customer.name}',
          style: AppTextStyles.cairoBold18
              .copyWith(color: Colors.white, fontSize: 15.sp),
        ),
      ),
      body: _loadingCatalog
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 100.h),
              children: [
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration:
                        const InputDecoration(labelText: 'تاريخ الفاتورة'),
                    child: Text(
                      '${_invoiceDate.year}/${_invoiceDate.month.toString().padLeft(2, '0')}/${_invoiceDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: _SaleTypeButton(
                        label: 'آجل',
                        selected: !_isCashSale,
                        onTap: () => setState(() => _isCashSale = false),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _SaleTypeButton(
                        label: 'نقدي',
                        selected: _isCashSale,
                        onTap: () => setState(() => _isCashSale = true),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                Row(
                  children: [
                    Text('الأصناف (${_lines.length})',
                        style: AppTextStyles.cairoBold18.copyWith(
                            color: AppColors.primary, fontSize: 14.sp)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addProduct,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('إضافة منتج'),
                    ),
                  ],
                ),
                for (final line in _lines)
                  _LineRow(
                    line: line,
                    onTap: () async {
                      final changed = await _editLine(line);
                      if (changed == true) setState(() {});
                    },
                    onRemove: () => setState(() => _lines.remove(line)),
                  ),
                SizedBox(height: 14.h),
                TextField(
                  controller: _discountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textDirection: TextDirection.ltr,
                  onChanged: (_) => setState(() {}),
                  decoration:
                      const InputDecoration(labelText: 'قيمة الخصم (ج.م)'),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: _paidNowController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textDirection: TextDirection.ltr,
                  onChanged: (_) => setState(() {}),
                  decoration:
                      const InputDecoration(labelText: 'المدفوع الآن (ج.م)'),
                ),
                if (_paidNow > 0) ...[
                  SizedBox(height: 12.h),
                  DropdownButtonFormField<PaymentMethod>(
                    value: _paymentMethod,
                    decoration: const InputDecoration(labelText: 'طريقة الدفع'),
                    items: PaymentMethod.values
                        .map((m) => DropdownMenuItem(
                            value: m, child: Text(m.displayLabel)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _paymentMethod = v);
                    },
                  ),
                ],
                SizedBox(height: 12.h),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'ملاحظات (اختياري)'),
                ),
                SizedBox(height: 18.h),
                _TotalsCard(
                    subtotal: _subtotal,
                    discountAmount: _discountAmount,
                    total: _total),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
            ),
            child: _submitting
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('حفظ الفاتورة التاريخية',
                    style: AppTextStyles.cairoMedium16
                        .copyWith(color: Colors.white, fontSize: 14.sp)),
          ),
        ),
      ),
    );
  }
}

class _SaleTypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SaleTypeButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryGreen : Colors.white,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
                color:
                    selected ? AppColors.primaryGreen : AppColors.cardBorder),
          ),
          child: Text(
            label,
            style: AppTextStyles.cairoMedium16.copyWith(
              color: selected ? Colors.white : AppColors.primary,
              fontSize: 13.sp,
            ),
          ),
        ),
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  final _LineItem line;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _LineRow(
      {required this.line, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cairoMedium16
                          .copyWith(fontSize: 12.5.sp)),
                  SizedBox(height: 2.h),
                  Text(
                      '${line.quantity} × ${line.unitPrice.toStringAsFixed(2)} ج.م',
                      style: AppTextStyles.almaraiRegular14.copyWith(
                          color: AppColors.navInactive, fontSize: 11.sp)),
                ],
              ),
            ),
            Text('${line.total.toStringAsFixed(0)} ج.م',
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: AppColors.primary, fontSize: 12.5.sp)),
            IconButton(
              onPressed: onRemove,
              icon: Icon(Icons.close_rounded,
                  color: AppColors.statusNotReached, size: 18.sp),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final double subtotal;
  final double discountAmount;
  final double total;

  const _TotalsCard(
      {required this.subtotal,
      required this.discountAmount,
      required this.total});

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, {bool bold = false}) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 3.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: AppColors.navInactive, fontSize: 12.sp)),
            Text(value,
                style: bold
                    ? AppTextStyles.cairoBold18
                        .copyWith(color: AppColors.primary, fontSize: 15.sp)
                    : AppTextStyles.cairoMedium16.copyWith(fontSize: 12.sp)),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          row('الإجمالي قبل الخصم', '${subtotal.toStringAsFixed(0)} ج.م'),
          row('الخصم', '${discountAmount.toStringAsFixed(0)} ج.م'),
          const Divider(),
          row('الإجمالي النهائي', '${total.toStringAsFixed(0)} ج.م',
              bold: true),
        ],
      ),
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  final List<ProductModel> catalog;

  const _ProductPickerSheet({required this.catalog});

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final visible = _query.trim().isEmpty
        ? widget.catalog
        : widget.catalog.where((p) => p.name.contains(_query.trim())).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 10.h),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final p = visible[index];
                    return ListTile(
                      title: Text(p.name,
                          style: AppTextStyles.cairoMedium16
                              .copyWith(fontSize: 13.sp)),
                      trailing: Text('${p.basePrice.toStringAsFixed(0)} ج.م',
                          style: const TextStyle(color: AppColors.primary)),
                      onTap: () => Navigator.pop(context, p),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

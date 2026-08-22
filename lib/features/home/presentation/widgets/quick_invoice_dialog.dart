import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:printing/printing.dart';
import '../../../customer-visits/customers/domain/mock_customers_repository.dart';
import '../../../customer-visits/customers/domain/models/collection_record_model.dart';
import '../../../customer-visits/customers/domain/models/invoice_record_model.dart';
import '../../../inventory/domain/mock_inventory_repository.dart';
import '../../../inventory/domain/models/product_model.dart';
import '../../../inventory/domain/models/product_unit.dart';
import '../../../invoices/domain/invoice_pdf_builder.dart';
import '../../domain/models/quick_invoice_models.dart';

/// ---------------------------------------------------------------------
/// Repository-backed data sources
/// ---------------------------------------------------------------------

const _currentRepName = 'أحمد محمود';

List<InvoiceCustomerModel> _customersFromRepository() {
  return MockCustomersRepository.instance.customers
      .map((c) => InvoiceCustomerModel(customer: c))
      .toList();
}

InvoiceProductModel _invoiceProductFromInventory(ProductModel product) {
  return InvoiceProductModel(
    id: product.id,
    name: product.name,
    price: product.basePrice,
    unit: product.unit.label,
  );
}

List<PastInvoiceSummaryModel> _statementFor(InvoiceCustomerModel invoice) {
  final records = MockCustomersRepository.instance
      .getInvoices(invoice.customer.id)
      .take(6)
      .toList();
  return records
      .map((r) => PastInvoiceSummaryModel(
            invoiceNumber: r.code,
            date: r.date,
            total: r.amount,
            status: r.status.label,
          ))
      .toList();
}

/// ---------------------------------------------------------------------
/// Formatting helpers
/// ---------------------------------------------------------------------

String _money(double value) {
  final negative = value < 0;
  final whole = value.abs().truncate();
  final decimals = (value.abs() - whole);
  final digits = whole.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  var out = buffer.toString();
  if (decimals > 0.005)
    out += '.${(decimals * 100).round().toString().padLeft(2, '0')}';
  return '${negative ? '-' : ''}$out ج.م';
}

String _date(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// ---------------------------------------------------------------------
/// Main dialog
/// ---------------------------------------------------------------------

class QuickInvoiceDialog extends StatefulWidget {
  /// If a customer is already known (e.g. opened from a customer profile),
  /// pass it here to skip the picker step.
  final InvoiceCustomerModel? initialCustomer;
  final ValueChanged<IssuedInvoiceInfo>? onIssued;

  const QuickInvoiceDialog({super.key, this.initialCustomer, this.onIssued});

  @override
  State<QuickInvoiceDialog> createState() => _QuickInvoiceDialogState();
}

class _QuickInvoiceDialogState extends State<QuickInvoiceDialog> {
  late final String invoiceNumber;
  DateTime now = DateTime.now();
  late DateTime invoiceDate = DateTime(now.year, now.month, now.day);
  String saleType = 'آجل';

  InvoiceCustomerModel? customer;
  final List<InvoiceLineItemModel> lineItems = [];
  double discountPercent = 0;
  final notesController = TextEditingController();
  final paidNowController = TextEditingController(text: '0');
  bool _isIssuing = false;

  @override
  void initState() {
    super.initState();
    invoiceNumber = 'INV-${invoiceDate.year}-${100 + Random().nextInt(900)}';
    customer = widget.initialCustomer;
    MockInventoryRepository.instance.init();
    MockCustomersRepository.instance.initialize();
  }

  @override
  void dispose() {
    notesController.dispose();
    paidNowController.dispose();
    super.dispose();
  }

  double get subtotal => lineItems.fold(0, (sum, item) => sum + item.total);
  double get discountAmount => subtotal * (discountPercent / 100);
  double get grandTotal => subtotal - discountAmount;

  double get previousBalance => customer?.customer.currentBalance ?? 0;
  double get paidNow => double.tryParse(paidNowController.text) ?? 0;
  double get totalDue => previousBalance + grandTotal;
  double get remainingBalance {
    final value = totalDue - paidNow;
    return value < 0 ? 0 : value;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: invoiceDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => invoiceDate = picked);
  }

  Future<void> _pickCustomer() async {
    await MockCustomersRepository.instance.initialize();
    if (!mounted) return;
    final picked = await showModalBottomSheet<InvoiceCustomerModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _CustomerPickerSheet(customers: _customersFromRepository()),
    );
    if (picked != null) {
      setState(() {
        customer = picked;
        lineItems.clear();
        paidNowController.text = '0';
      });
    }
  }

  Future<void> _openAddProducts() async {
    await MockInventoryRepository.instance.init();
    if (!mounted) return;
    final added = await showModalBottomSheet<List<InvoiceLineItemModel>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductPickerSheet(existing: lineItems),
    );
    if (added != null)
      setState(() => lineItems
        ..clear()
        ..addAll(added));
  }

  void _openStatement() {
    if (customer == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StatementSheet(
        invoice: customer!,
        entries: _statementFor(customer!),
      ),
    );
  }

  Future<void> _issueInvoice() async {
    final colors = context.colors;
    if (customer == null) {
      _toast('اختر العميل أولًا');
      return;
    }
    if (lineItems.isEmpty) {
      _toast('أضف صنفًا واحدًا على الأقل للفاتورة');
      return;
    }
    final total = grandTotal;
    final isDeferredSale = saleType != 'نقدي';
    if (isDeferredSale && total > customer!.availableCredit) {
      _toast('قيمة الفاتورة الآجلة تتجاوز حد الائتمان المتاح');
      return;
    }

    for (final item in lineItems) {
      final stock = MockInventoryRepository.instance.stockOf(item.product.id);
      final available = stock?.quantity ?? 0;
      if (item.quantity > available) {
        _toast(
          'الكمية المطلوبة من "${item.product.name}" أكبر من المتاح في العربية (متاح $available ${item.product.unit})',
        );
        return;
      }
    }

    setState(() => _isIssuing = true);

    for (final item in lineItems) {
      await MockInventoryRepository.instance
          .consumeFromVehicle(item.product.id, item.quantity);
    }

    final paid = paidNow;
    final customerId = customer!.customer.id;

    await MockCustomersRepository.instance.adjustBalance(
      customerId,
      total - paid,
      isCollection: paid > 0,
      collectedAmount: paid > 0 ? paid : null,
      collectionSource: CollectionSource.newInvoicePayment,
    );

    final status = paid >= total
        ? InvoiceStatus.paid
        : paid > 0
            ? InvoiceStatus.partial
            : InvoiceStatus.deferred;

    await MockCustomersRepository.instance.addInvoice(
      customerId,
      InvoiceRecordModel(
        code: invoiceNumber,
        date: invoiceDate,
        amount: total,
        status: status,
      ),
    );

    if (!mounted) return;

    widget.onIssued?.call(IssuedInvoiceInfo(
      invoiceNumber: invoiceNumber,
      amount: total,
      saleType: saleType,
      date: invoiceDate,
    ));

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colors.primary,
        content: Text(
          'تم إصدار الفاتورة $invoiceNumber بإجمالي ${_money(total)} — المتبقي على العميل ${_money(remainingBalance)}',
          style: AppTextStyles.cairoMedium16
              .copyWith(color: Colors.white, fontSize: 13.sp),
        ),
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _canBuildPdf() {
    if (customer == null) {
      _toast('اختر العميل أولًا');
      return false;
    }
    if (lineItems.isEmpty) {
      _toast('أضف صنفًا واحدًا على الأقل للفاتورة');
      return false;
    }
    return true;
  }

  Future<Uint8List> _buildInvoicePdfBytes() {
    return InvoicePdfBuilder.build(
      InvoicePdfData(
        invoiceNumber: invoiceNumber,
        date: invoiceDate,
        customerName: customer?.customer.name ?? '',
        repName: _currentRepName,
        items: lineItems
            .map((item) => InvoicePdfLineItem(
                  name: item.product.name,
                  quantity: item.quantity,
                  price: item.product.price,
                  total: item.total,
                ))
            .toList(),
        invoiceTotal: grandTotal,
        previousBalance: previousBalance,
        totalDue: totalDue,
        paidNow: paidNow,
        remaining: remainingBalance,
      ),
    );
  }

  Future<void> _printInvoice() async {
    if (!_canBuildPdf()) return;
    final bytes = await _buildInvoicePdfBytes();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _shareInvoiceOnWhatsapp() async {
    if (!_canBuildPdf()) return;
    final bytes = await _buildInvoicePdfBytes();
    await Printing.sharePdf(bytes: bytes, filename: '$invoiceNumber.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      backgroundColor: colors.surface,
      insetPadding: EdgeInsets.symmetric(
        horizontal: context.isMobile ? 12.w : context.screenWidth * 0.18,
        vertical: 24.h,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: context.screenHeight * 0.9),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(invoiceNumber: invoiceNumber),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(18.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _RepChip(name: _currentRepName),
                      SizedBox(height: 14.h),
                      _SectionCard(
                        child: customer == null
                            ? _CustomerEmptyState(onPick: _pickCustomer)
                            : _CustomerInfo(
                                invoice: customer!,
                                onChange: _pickCustomer,
                              ),
                      ),
                      if (customer != null) ...[
                        SizedBox(height: 14.h),
                        _SectionCard(
                          child: _InvoiceMetaSection(
                            date: invoiceDate,
                            onPickDate: _pickDate,
                            invoiceNumber: invoiceNumber,
                            saleType: saleType,
                            onSaleTypeChanged: (v) =>
                                setState(() => saleType = v),
                          ),
                        ),
                        SizedBox(height: 14.h),
                        _FinancialSummaryRow(invoice: customer!),
                        SizedBox(height: 14.h),
                        _StatementTile(onTap: _openStatement),
                        SizedBox(height: 14.h),
                        _SectionCard(
                          child: _ProductsSection(
                            items: lineItems,
                            onAdd: _openAddProducts,
                            onQuantityChanged: (item, qty) => setState(() {
                              if (qty <= 0) {
                                lineItems.remove(item);
                              } else {
                                item.quantity = qty;
                              }
                            }),
                            onRemove: (item) =>
                                setState(() => lineItems.remove(item)),
                            subtotal: subtotal,
                            discountPercent: discountPercent,
                            onDiscountChanged: (v) =>
                                setState(() => discountPercent = v),
                            discountAmount: discountAmount,
                            grandTotal: grandTotal,
                          ),
                        ),
                        if (lineItems.isNotEmpty) ...[
                          SizedBox(height: 14.h),
                          _SectionCard(
                            child: _AccountSummarySection(
                              previousBalance: previousBalance,
                              invoiceTotal: grandTotal,
                              paidController: paidNowController,
                              onPaidChanged: (_) => setState(() {}),
                              remaining: remainingBalance,
                            ),
                          ),
                        ],
                        SizedBox(height: 14.h),
                        _SectionCard(
                          child: _NotesField(controller: notesController),
                        ),
                        if (customer!.topPurchasedProducts.isNotEmpty ||
                            customer!.notPurchasedRecently.isNotEmpty) ...[
                          SizedBox(height: 14.h),
                          _PurchaseAnalysisSection(customer: customer!),
                        ],
                      ] else
                        SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),
              _FooterActions(
                canIssue:
                    customer != null && lineItems.isNotEmpty && !_isIssuing,
                isIssuing: _isIssuing,
                onSave: _issueInvoice,
                onPrint: _printInvoice,
                onShareWhatsapp: _shareInvoiceOnWhatsapp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Header
/// ---------------------------------------------------------------------

class _Header extends StatelessWidget {
  final String invoiceNumber;
  const _Header({required this.invoiceNumber});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.heroBackground, colors.secondary],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'MIVET',
              style: AppTextStyles.cairoBold18
                  .copyWith(color: Colors.white, fontSize: 14.sp),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'فاتورة جديدة',
                  style:
                      AppTextStyles.cairoBold18.copyWith(color: Colors.white),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(Icons.qr_code_2_rounded,
                        size: 13.sp, color: Colors.white70),
                    SizedBox(width: 4.w),
                    Text(
                      invoiceNumber,
                      style: AppTextStyles.almaraiRegular14.copyWith(
                        color: Colors.white70,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: Colors.white, size: 24.sp),
          ),
        ],
      ),
    );
  }
}

class _RepChip extends StatelessWidget {
  final String name;
  const _RepChip({required this.name});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(Icons.badge_outlined, size: 15.sp, color: colors.textMuted),
        SizedBox(width: 6.w),
        Text(
          'المندوب: $name',
          style: AppTextStyles.almaraiRegular14.copyWith(
            color: colors.textMuted,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// Shared section wrapper
/// ---------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.subtleShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SectionTitle({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: colors.primary),
        SizedBox(width: 8.w),
        Text(
          title,
          style: AppTextStyles.cairoMedium16.copyWith(
            color: colors.text,
            fontSize: 13.sp,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// Customer section: empty state, picker sheet, selected info
/// ---------------------------------------------------------------------

class _CustomerEmptyState extends StatelessWidget {
  final VoidCallback onPick;
  const _CustomerEmptyState({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
            icon: Icons.storefront_outlined, title: 'بيانات العميل'),
        SizedBox(height: 12.h),
        Material(
          color: colors.background,
          borderRadius: BorderRadius.circular(14.r),
          child: InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(14.r),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 14.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: colors.primary.withOpacity(0.35),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.person_search_rounded,
                        color: colors.primary, size: 20.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'اختر العميل لبدء إصدار الفاتورة',
                      style: AppTextStyles.cairoMedium16.copyWith(
                        color: colors.text,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_left_rounded,
                      color: colors.primary, size: 20.sp),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomerInfo extends StatelessWidget {
  final InvoiceCustomerModel invoice;
  final VoidCallback onChange;

  const _CustomerInfo({required this.invoice, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                invoice.customer.name,
                style: AppTextStyles.cairoBold18
                    .copyWith(color: colors.text, fontSize: 15.sp),
              ),
            ),
            TextButton(
              onPressed: onChange,
              child: Text(
                'تغيير',
                style: AppTextStyles.cairoMedium16.copyWith(
                  color: colors.primary,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Row(
          children: [
            Icon(Icons.location_on_outlined,
                size: 14.sp, color: colors.textMuted),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                invoice.customer.address,
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: colors.textMuted, fontSize: 12.sp),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Icon(Icons.call_outlined, size: 14.sp, color: colors.textMuted),
            SizedBox(width: 4.w),
            Text(
              invoice.customer.phone,
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: colors.textMuted, fontSize: 12.sp),
            ),
          ],
        ),
      ],
    );
  }
}

class _CustomerPickerSheet extends StatefulWidget {
  final List<InvoiceCustomerModel> customers;
  const _CustomerPickerSheet({required this.customers});

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filtered = widget.customers
        .where(
            (c) => c.customer.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return _BottomSheetShell(
      title: 'اختر العميل',
      icon: Icons.storefront_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: (v) => setState(() => query = v),
            style: TextStyle(color: colors.text),
            decoration: InputDecoration(
              hintText: 'ابحث باسم العميل...',
              hintStyle: TextStyle(color: colors.textMuted),
              prefixIcon: Icon(Icons.search_rounded,
                  size: 20.sp, color: colors.textMuted),
              filled: true,
              fillColor: colors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
            ),
          ),
          SizedBox(height: 12.h),
          ...filtered.map(
            (c) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Material(
                color: colors.background,
                borderRadius: BorderRadius.circular(14.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14.r),
                  onTap: () => Navigator.pop(context, c),
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Row(
                      children: [
                        Container(
                          width: 38.w,
                          height: 38.w,
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(Icons.storefront_outlined,
                              color: colors.primary, size: 18.sp),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.customer.name,
                                style: AppTextStyles.cairoMedium16.copyWith(
                                  color: colors.text,
                                  fontSize: 13.sp,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                c.customer.address,
                                style: AppTextStyles.almaraiRegular14.copyWith(
                                  color: colors.textMuted,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_left_rounded,
                            color: colors.textMuted, size: 18.sp),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (filtered.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Text(
                  'لا يوجد عملاء مطابقين',
                  style: AppTextStyles.almaraiRegular14
                      .copyWith(color: colors.textMuted),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Invoice meta: date, invoice number, sale type toggle
/// ---------------------------------------------------------------------

class _InvoiceMetaSection extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPickDate;
  final String invoiceNumber;
  final String saleType;
  final ValueChanged<String> onSaleTypeChanged;

  const _InvoiceMetaSection({
    required this.date,
    required this.onPickDate,
    required this.invoiceNumber,
    required this.saleType,
    required this.onSaleTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
            icon: Icons.receipt_long_outlined, title: 'بيانات الفاتورة'),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _TappableField(
                label: 'التاريخ',
                value: _date(date),
                icon: Icons.calendar_today_outlined,
                onTap: onPickDate,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _StaticField(
                label: 'رقم الفاتورة',
                value: invoiceNumber,
                icon: Icons.tag_rounded,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Text(
          'نوع البيع',
          style: AppTextStyles.almaraiRegular14
              .copyWith(color: colors.textMuted, fontSize: 12.sp),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _SaleTypeOption(
                label: 'نقدي',
                icon: Icons.payments_outlined,
                selected: saleType == 'نقدي',
                onTap: () => onSaleTypeChanged('نقدي'),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _SaleTypeOption(
                label: 'آجل',
                icon: Icons.schedule_outlined,
                selected: saleType == 'آجل',
                onTap: () => onSaleTypeChanged('آجل'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TappableField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _TappableField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: colors.textMuted, fontSize: 11.sp)),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(icon, size: 15.sp, color: colors.text),
                SizedBox(width: 6.w),
                Text(value,
                    style: AppTextStyles.cairoMedium16
                        .copyWith(color: colors.text, fontSize: 13.sp)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StaticField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StaticField(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: colors.textMuted, fontSize: 11.sp)),
          SizedBox(height: 4.h),
          Row(
            children: [
              Icon(icon, size: 15.sp, color: colors.text),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.text, fontSize: 13.sp),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaleTypeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SaleTypeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected ? colors.primary : colors.background,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15.sp,
                  color: selected ? Colors.white : colors.textMuted),
              SizedBox(width: 6.w),
              Text(
                label,
                style: AppTextStyles.cairoMedium16.copyWith(
                  color: selected ? Colors.white : colors.text,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Financial summary (from the selected customer — admin controlled)
/// ---------------------------------------------------------------------

class _FinancialSummaryRow extends StatelessWidget {
  final InvoiceCustomerModel invoice;
  const _FinancialSummaryRow({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final nearLimit =
        invoice.customer.currentBalance > invoice.customer.creditLimit * 0.8;
    return Row(
      children: [
        Expanded(
          child: _FinancialCard(
            title: 'حد الائتمان',
            value: _money(invoice.customer.creditLimit),
            icon: Icons.verified_user_outlined,
            color: colors.statBlue,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _FinancialCard(
            title: 'الرصيد الحالي',
            value: _money(invoice.customer.currentBalance),
            icon: Icons.account_balance_wallet_outlined,
            color: nearLimit ? colors.statusNotReached : colors.statOrange,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _FinancialCard(
            title: 'آخر سداد',
            value: _date(
                invoice.customer.lastCollectionDate ?? DateTime(2024, 6, 6)),
            icon: Icons.event_available_outlined,
            color: colors.primary,
          ),
        ),
      ],
    );
  }
}

class _FinancialCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _FinancialCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTextStyles.cairoBold18
                .copyWith(color: color, fontSize: 13.sp),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: AppTextStyles.almaraiRegular14
                .copyWith(color: color.withOpacity(0.85), fontSize: 10.sp),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Statement — كشف حساب آخر 6 شهور
/// ---------------------------------------------------------------------

class _StatementTile extends StatelessWidget {
  final VoidCallback onTap;
  const _StatementTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            children: [
              Icon(Icons.receipt_long_outlined,
                  color: colors.text, size: 20.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'كشف الحساب — آخر 6 شهور',
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.text, fontSize: 13.sp),
                ),
              ),
              Icon(Icons.chevron_left_rounded,
                  color: colors.textMuted, size: 20.sp),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatementSheet extends StatelessWidget {
  final InvoiceCustomerModel invoice;
  final List<PastInvoiceSummaryModel> entries;

  const _StatementSheet({required this.invoice, required this.entries});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _BottomSheetShell(
      title: 'كشف حساب — ${invoice.customer.name}',
      icon: Icons.receipt_long_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: entries
            .map(
              (e) => Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.invoiceNumber,
                              style: AppTextStyles.cairoMedium16.copyWith(
                                  color: colors.text, fontSize: 12.sp)),
                          SizedBox(height: 2.h),
                          Text(_date(e.date),
                              style: AppTextStyles.almaraiRegular14.copyWith(
                                  color: colors.textMuted, fontSize: 11.sp)),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: (e.status == 'مدفوعة'
                                ? colors.primary
                                : colors.statOrange)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        e.status,
                        style: AppTextStyles.almaraiRegular14.copyWith(
                          color: e.status == 'مدفوعة'
                              ? colors.primary
                              : colors.statOrange,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(_money(e.total),
                        style: AppTextStyles.cairoBold18
                            .copyWith(color: colors.text, fontSize: 13.sp)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Products section
/// ---------------------------------------------------------------------

class _ProductsSection extends StatelessWidget {
  final List<InvoiceLineItemModel> items;
  final VoidCallback onAdd;
  final void Function(InvoiceLineItemModel, int) onQuantityChanged;
  final void Function(InvoiceLineItemModel) onRemove;
  final double subtotal;
  final double discountPercent;
  final ValueChanged<double> onDiscountChanged;
  final double discountAmount;
  final double grandTotal;

  const _ProductsSection({
    required this.items,
    required this.onAdd,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.subtotal,
    required this.discountPercent,
    required this.onDiscountChanged,
    required this.discountAmount,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          icon: Icons.inventory_2_outlined,
          title: 'الأصناف (${items.length})',
          trailing: TextButton.icon(
            onPressed: onAdd,
            icon: Icon(Icons.add_circle_outline_rounded,
                size: 16.sp, color: colors.primary),
            label: Text(
              'إضافة صنف',
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: colors.primary, fontSize: 12.sp),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        if (items.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'لم تتم إضافة أصناف بعد',
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: colors.textMuted, fontSize: 12.sp),
            ),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _LineItemTile(
                item: item,
                onQuantityChanged: (q) => onQuantityChanged(item, q),
                onRemove: () => onRemove(item),
              ),
            ),
          ),
        if (items.isNotEmpty) ...[
          SizedBox(height: 10.h),
          Divider(height: 1, color: colors.border),
          SizedBox(height: 10.h),
          _TotalsRow(label: 'الإجمالي الفرعي', value: _money(subtotal)),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(
                'خصم %',
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: colors.textMuted, fontSize: 12.sp),
              ),
              const Spacer(),
              _DiscountStepper(
                  value: discountPercent, onChanged: onDiscountChanged),
            ],
          ),
          SizedBox(height: 8.h),
          _TotalsRow(
              label: 'قيمة الخصم',
              value: '- ${_money(discountAmount)}',
              muted: true),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Text(
                  'إجمالي الفاتورة',
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.text, fontSize: 13.sp),
                ),
                const Spacer(),
                Text(
                  _money(grandTotal),
                  style: AppTextStyles.cairoBold18
                      .copyWith(color: colors.primary, fontSize: 17.sp),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TotalsRow extends StatelessWidget {
  final String label;
  final String value;
  final bool muted;
  const _TotalsRow(
      {required this.label, required this.value, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Text(label,
            style: AppTextStyles.almaraiRegular14
                .copyWith(color: colors.textMuted, fontSize: 12.sp)),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.cairoMedium16.copyWith(
            color: muted ? colors.statOrange : colors.text,
            fontSize: 13.sp,
          ),
        ),
      ],
    );
  }
}

class _DiscountStepper extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _DiscountStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        _StepButton(
            icon: Icons.remove_rounded,
            onTap: () => onChanged((value - 5).clamp(0, 50))),
        Container(
          width: 44.w,
          alignment: Alignment.center,
          child: Text(
            '${value.toStringAsFixed(0)}%',
            style: AppTextStyles.cairoMedium16
                .copyWith(color: colors.text, fontSize: 13.sp),
          ),
        ),
        _StepButton(
            icon: Icons.add_rounded,
            onTap: () => onChanged((value + 5).clamp(0, 50))),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.background,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Icon(icon, size: 14.sp, color: colors.text),
        ),
      ),
    );
  }
}

class _LineItemTile extends StatelessWidget {
  final InvoiceLineItemModel item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const _LineItemTile({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Material(
            color: colors.statusNotReached.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(8.r),
              onTap: onRemove,
              child: Padding(
                padding: EdgeInsets.all(6.w),
                child: Icon(Icons.close_rounded,
                    size: 14.sp, color: colors.statusNotReached),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.text, fontSize: 12.5.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  '${_money(item.product.price)} / ${item.product.unit}',
                  style: AppTextStyles.almaraiRegular14
                      .copyWith(color: colors.textMuted, fontSize: 10.5.sp),
                ),
              ],
            ),
          ),
          _StepButton(
              icon: Icons.remove_rounded,
              onTap: () => onQuantityChanged(item.quantity - 1)),
          Container(
            width: 30.w,
            alignment: Alignment.center,
            child: Text('${item.quantity}',
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: colors.text, fontSize: 12.sp)),
          ),
          _StepButton(
              icon: Icons.add_rounded,
              onTap: () => onQuantityChanged(item.quantity + 1)),
          SizedBox(width: 10.w),
          SizedBox(
            width: 62.w,
            child: Text(
              _money(item.total),
              textAlign: TextAlign.end,
              style: AppTextStyles.cairoBold18
                  .copyWith(color: colors.primary, fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  final List<InvoiceLineItemModel> existing;
  const _ProductPickerSheet({required this.existing});

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  late List<InvoiceLineItemModel> cart;
  String query = '';

  @override
  void initState() {
    super.initState();
    cart = widget.existing
        .map((e) =>
            InvoiceLineItemModel(product: e.product, quantity: e.quantity))
        .toList();
  }

  int _quantityFor(InvoiceProductModel p) {
    final match = cart.where((c) => c.product.id == p.id);
    return match.isEmpty ? 0 : match.first.quantity;
  }

  int _availableFor(InvoiceProductModel p) {
    return MockInventoryRepository.instance.stockOf(p.id)?.quantity ?? 0;
  }

  void _setQuantity(InvoiceProductModel p, int qty) {
    final available = _availableFor(p);
    if (qty > available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الكمية المتاحة في العربية $available فقط')),
      );
      return;
    }
    setState(() {
      cart.removeWhere((c) => c.product.id == p.id);
      if (qty > 0) cart.add(InvoiceLineItemModel(product: p, quantity: qty));
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filtered = MockInventoryRepository.instance.products.value
        .map(_invoiceProductFromInventory)
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return _BottomSheetShell(
      title: 'إضافة أصناف',
      icon: Icons.inventory_2_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: (v) => setState(() => query = v),
            style: TextStyle(color: colors.text),
            decoration: InputDecoration(
              hintText: 'ابحث عن منتج...',
              hintStyle: TextStyle(color: colors.textMuted),
              prefixIcon: Icon(Icons.search_rounded,
                  size: 20.sp, color: colors.textMuted),
              filled: true,
              fillColor: colors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
            ),
          ),
          SizedBox(height: 12.h),
          ...filtered.map((p) {
            final qty = _quantityFor(p);
            final available = _availableFor(p);
            final isOut = available == 0;
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: qty > 0
                      ? colors.primary.withOpacity(0.08)
                      : colors.background,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: qty > 0
                        ? colors.primary.withOpacity(0.35)
                        : Colors.transparent,
                  ),
                ),
                child: Opacity(
                  opacity: isOut ? 0.5 : 1,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                style: AppTextStyles.cairoMedium16.copyWith(
                                    color: colors.text, fontSize: 12.5.sp)),
                            SizedBox(height: 2.h),
                            Text(
                              isOut
                                  ? '${_money(p.price)} / ${p.unit} · غير متوفر بالعربية'
                                  : '${_money(p.price)} / ${p.unit} · المتاح: $available',
                              style: AppTextStyles.almaraiRegular14.copyWith(
                                color: isOut
                                    ? colors.statusNotReached
                                    : colors.textMuted,
                                fontSize: 10.5.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (qty == 0)
                        Material(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(10.r),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10.r),
                            onTap: isOut ? null : () => _setQuantity(p, 1),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 8.h),
                              child: Text('إضافة',
                                  style: AppTextStyles.cairoMedium16.copyWith(
                                      color: Colors.white, fontSize: 11.sp)),
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            _StepButton(
                                icon: Icons.remove_rounded,
                                onTap: () => _setQuantity(p, qty - 1)),
                            Container(
                              width: 28.w,
                              alignment: Alignment.center,
                              child: Text('$qty',
                                  style: AppTextStyles.cairoMedium16.copyWith(
                                      color: colors.text, fontSize: 12.sp)),
                            ),
                            _StepButton(
                                icon: Icons.add_rounded,
                                onTap: () => _setQuantity(p, qty + 1)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          SizedBox(height: 6.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, cart),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text(
                'تم — ${cart.length} صنف',
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: Colors.white, fontSize: 13.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Account summary (previous balance + invoice total + paid now)
/// ---------------------------------------------------------------------

class _AccountSummarySection extends StatelessWidget {
  final double previousBalance;
  final double invoiceTotal;
  final TextEditingController paidController;
  final ValueChanged<String> onPaidChanged;
  final double remaining;

  const _AccountSummarySection({
    required this.previousBalance,
    required this.invoiceTotal,
    required this.paidController,
    required this.onPaidChanged,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalDue = previousBalance + invoiceTotal;
    final isSettled = remaining <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          icon: Icons.account_balance_wallet_outlined,
          title: 'ملخص الحساب',
        ),
        SizedBox(height: 12.h),
        _TotalsRow(label: 'قيمة الفاتورة الحالية', value: _money(invoiceTotal)),
        SizedBox(height: 8.h),
        _TotalsRow(label: 'حساب سابق', value: _money(previousBalance)),
        SizedBox(height: 10.h),
        Divider(height: 1, color: colors.border),
        SizedBox(height: 10.h),
        _TotalsRow(label: 'إجمالي المستحق على العميل', value: _money(totalDue)),
        SizedBox(height: 14.h),
        Text('المدفوع الآن',
            style: AppTextStyles.almaraiRegular14
                .copyWith(color: colors.textMuted, fontSize: 12.sp)),
        SizedBox(height: 6.h),
        TextField(
          controller: paidController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onPaidChanged,
          style: AppTextStyles.cairoMedium16.copyWith(color: colors.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.background,
            prefixIcon: Icon(Icons.payments_outlined,
                size: 18.sp, color: colors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          ),
        ),
        SizedBox(height: 14.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: (isSettled ? colors.primary : colors.statusNotReached)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Text('المتبقي على العميل',
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.text, fontSize: 13.sp)),
              const Spacer(),
              Text(
                _money(remaining),
                style: AppTextStyles.cairoBold18.copyWith(
                  color: isSettled ? colors.primary : colors.statusNotReached,
                  fontSize: 17.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// Notes
/// ---------------------------------------------------------------------

class _NotesField extends StatelessWidget {
  final TextEditingController controller;
  const _NotesField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
            icon: Icons.edit_note_rounded, title: 'ملاحظات المندوب'),
        SizedBox(height: 10.h),
        TextField(
          controller: controller,
          maxLines: 3,
          style: TextStyle(color: colors.text),
          decoration: InputDecoration(
            hintText: '📝 اكتب ملاحظاتك على الزيارة أو الفاتورة...',
            hintStyle: AppTextStyles.almaraiRegular14
                .copyWith(color: colors.textMuted),
            filled: true,
            fillColor: colors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.all(16.w),
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// Purchase analysis — always the last section before the footer
/// ---------------------------------------------------------------------

class _PurchaseAnalysisSection extends StatelessWidget {
  final InvoiceCustomerModel customer;
  const _PurchaseAnalysisSection({required this.customer});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
              icon: Icons.insights_rounded, title: 'تحليل مشتريات العميل'),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (customer.topPurchasedProducts.isNotEmpty)
                Expanded(
                  child: _InsightBadge(
                    title: 'أكثر المنتجات شراءً',
                    items: customer.topPurchasedProducts,
                    color: colors.primary,
                    icon: Icons.trending_up_rounded,
                  ),
                ),
              if (customer.topPurchasedProducts.isNotEmpty &&
                  customer.notPurchasedRecently.isNotEmpty)
                SizedBox(width: 12.w),
              if (customer.notPurchasedRecently.isNotEmpty)
                Expanded(
                  child: _InsightBadge(
                    title: 'لم يشترها منذ فترة',
                    items: customer.notPurchasedRecently,
                    color: colors.statOrange,
                    icon: Icons.history_rounded,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightBadge extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  final IconData icon;

  const _InsightBadge({
    required this.title,
    required this.items,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14.sp),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: color, fontSize: 12.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 4.w,
                    decoration: BoxDecoration(
                        color: colors.textMuted, shape: BoxShape.circle),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTextStyles.almaraiRegular14
                          .copyWith(color: colors.text, fontSize: 11.sp),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Footer actions
/// ---------------------------------------------------------------------

class _FooterActions extends StatelessWidget {
  final bool canIssue;
  final bool isIssuing;
  final VoidCallback onSave;
  final VoidCallback onPrint;
  final VoidCallback onShareWhatsapp;

  const _FooterActions({
    required this.canIssue,
    required this.onSave,
    required this.onPrint,
    required this.onShareWhatsapp,
    this.isIssuing = false,
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
            child: ElevatedButton.icon(
              onPressed: canIssue ? onSave : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                disabledBackgroundColor: colors.primary.withOpacity(0.35),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
              icon: isIssuing
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(Icons.save_alt_rounded,
                      color: Colors.white, size: 20.sp),
              label: Text(
                isIssuing ? 'جاري الحفظ...' : 'حفظ وإصدار الفاتورة',
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: Colors.white, fontSize: 13.sp),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          _OutlinedIconButton(
            icon: Icon(
              Icons.print_outlined,
              color: colors.text,
              size: 22.sp,
            ),
            color: colors.text,
            onTap: onPrint,
          ),
          SizedBox(width: 8.w),
          _OutlinedIconButton(
            icon: FaIcon(
              FontAwesomeIcons.whatsapp,
              color: const Color(0xFF25D366),
              size: 22.sp,
            ),
            color: const Color(0xFF25D366),
            onTap: onShareWhatsapp,
          ),
        ],
      ),
    );
  }
}

class _OutlinedIconButton extends StatelessWidget {
  final Widget icon;
  final Color color;
  final VoidCallback onTap;

  const _OutlinedIconButton({
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

/// ---------------------------------------------------------------------
/// Shared bottom-sheet shell used by both picker sheets
/// ---------------------------------------------------------------------

class _BottomSheetShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _BottomSheetShell(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          ),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Icon(icon, color: colors.primary, size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.cairoBold18
                            .copyWith(color: colors.text, fontSize: 15.sp),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded,
                          size: 20.sp, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

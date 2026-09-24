import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:printing/printing.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/di/service_locator.dart';
import 'package:mivet_app/features/inventory/presentation/cubit/vehicle_stock_cubit.dart';
import '../../../customer-visits/customers/data/customers_repository.dart';
import '../../../customer-visits/customers/data/invoices_repository.dart';
import '../../../customer-visits/customers/domain/models/invoice_line_input.dart';
import '../../../inventory/domain/models/product_model.dart';
import '../../../inventory/presentation/cubit/vehicle_stock_state.dart';
import '../../../invoices/domain/invoice_pdf_builder.dart';
import '../../../invoices/domain/invoice_draft.dart';
import '../../domain/models/quick_invoice_models.dart';
import '../../../customer_account/domain/entities/payment_method.dart';
import '../../../customer_account/presentation/widgets/payment_method_selector.dart';
import 'package:mivet_app/features/auth/presentation/cubit/auth_cubit.dart';

List<InvoiceCustomerModel> _customersFromRepository() {
  return CustomersRepository.instance.customers
      .map((c) => InvoiceCustomerModel(customer: c))
      .toList();
}

InvoiceProductModel _invoiceProductFromInventory(ProductModel product) {
  return InvoiceProductModel(
    id: product.id,
    name: product.name,
    price: product.basePrice,
  );
}

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
  if (decimals > 0.005) {
    out += '.${(decimals * 100).round().toString().padLeft(2, '0')}';
  }
  return '${negative ? '-' : ''}$out ج.م';
}

String _date(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class _VehicleStockInfo {
  final bool known;
  final Map<String, int> quantities;

  /// Products that are physically on THIS rep's vehicle right now (quantity > 0).
  /// This is the only list the invoice product picker is allowed to show: the
  /// `products` table is one shared catalog for every rep.
  final List<ProductModel> products;
  final String? errorMessage;

  const _VehicleStockInfo({
    required this.known,
    required this.quantities,
    this.products = const [],
    this.errorMessage,
  });

  int availableFor(String productId) => quantities[productId] ?? 0;
}

_VehicleStockInfo _resolveVehicleStockInfo(VehicleStockState state) {
  final known = state.selectedVehicleId != null &&
      state.status != VehicleStockStatus.initial &&
      state.status != VehicleStockStatus.loading &&
      state.status != VehicleStockStatus.error;

  if (!known) {
    return _VehicleStockInfo(
      known: false,
      quantities: const {},
      errorMessage:
          state.status == VehicleStockStatus.error ? state.errorMessage : null,
    );
  }

  final quantities = <String, int>{};
  final products = <ProductModel>[];
  for (final stock in state.vehicleStock) {
    final quantity = stock.quantity > 0 ? stock.quantity : 0;
    quantities[stock.productId] = quantity;
    final product = stock.product;
    if (quantity > 0 && product != null && !product.isDeleted) {
      products.add(product);
    }
  }
  return _VehicleStockInfo(
    known: true,
    quantities: quantities,
    products: products,
  );
}

class QuickInvoiceDialog extends StatefulWidget {
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
  Map<String, CustomerProductPrice> _customerPrices = {};
  int _customerPricesRequestId = 0;
  int _currentPage = 1;
  bool _loadingCustomerPrices = false;
  double discountPercent = 0;
  final notesController = TextEditingController();
  final paidNowController = TextEditingController(text: '0');
  bool _isIssuing = false;
  PaymentMethod? _paymentMethod;
  final VehicleStockCubit _vehicleStockCubit = sl<VehicleStockCubit>();

  @override
  void initState() {
    super.initState();
    invoiceNumber = 'INV-${invoiceDate.year}-${100 + Random().nextInt(900)}';
    customer = widget.initialCustomer;
    CustomersRepository.instance.initialize();
    if (customer != null) _loadCustomerPrices(customer!.customer.id);
    if (_vehicleStockCubit.state.status == VehicleStockStatus.initial) {
      _vehicleStockCubit.loadVehicles();
    }
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
    await CustomersRepository.instance.initialize();
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
        _customerPrices = {};
        _currentPage = 1;
        paidNowController.text = '0';
        _paymentMethod = null;
      });
      await _loadCustomerPrices(picked.customer.id);
    }
  }

  Future<void> _loadCustomerPrices(String customerId) async {
    final requestId = ++_customerPricesRequestId;
    setState(() {
      _loadingCustomerPrices = true;
      _customerPrices = {};
    });
    try {
      final prices = await InvoicesRepository.instance
          .getCustomerProductPrices(customerId);
      if (!mounted || requestId != _customerPricesRequestId) return;
      setState(() {
        _customerPrices = prices;
        _loadingCustomerPrices = false;
      });
    } catch (error) {
      if (!mounted || requestId != _customerPricesRequestId) return;
      setState(() => _loadingCustomerPrices = false);
      showAppError(context, error);
    }
  }

  int _applyStockGuard({
    required _VehicleStockInfo stockInfo,
    required InvoiceProductModel product,
    required int currentQuantity,
    required int desiredQuantity,
  }) {
    if (desiredQuantity <= currentQuantity) {
      return desiredQuantity < 0 ? 0 : desiredQuantity;
    }
    if (!stockInfo.known) {
      _toast('تعذر تعديل الكمية، جاري التأكد من مخزون العربية');
      return currentQuantity;
    }
    final available = stockInfo.availableFor(product.id);
    if (available <= currentQuantity) {
      _toast('لا يوجد مخزون إضافي متاح لهذا المنتج في العربية');
      return currentQuantity;
    }
    final clamped = desiredQuantity > available ? available : desiredQuantity;
    if (clamped == currentQuantity) {
      _toast('لا يوجد مخزون إضافي متاح لهذا المنتج في العربية');
    }
    return clamped;
  }

  Future<void> _openAddProducts(_VehicleStockInfo stockInfo) async {
    if (!mounted) return;
    if (!stockInfo.known) {
      _toast(stockInfo.errorMessage ??
          'جاري تحميل بيانات مخزون العربية، حاول بعد قليل');
      return;
    }
    // This customer's prices may still be loading (they are fetched right after
    // picking the customer): give them a moment, otherwise the picker would
    // open with the list price only.
    var waited = 0;
    while (_loadingCustomerPrices && waited < 40 && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      waited++;
    }
    if (!mounted) return;

    // The vehicle stock already comes with each product's data, so the picker
    // opens instantly (no catalog download) and only ever lists the products
    // of this rep's own vehicle.
    final added = await showModalBottomSheet<List<InvoiceLineItemModel>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductPickerSheet(
        existing: lineItems,
        products: stockInfo.products,
        customerPrices: _customerPrices,
        stockByProductId: stockInfo.quantities,
      ),
    );
    if (added != null) {
      setState(() {
        lineItems
          ..clear()
          ..addAll(added);
        _currentPage = lineItems.isEmpty
            ? 1
            : _currentPage.clamp(1, (lineItems.length / 15).ceil());
      });
    }
  }

  Future<void> _issueInvoice() async {
    if (customer == null) {
      _toast('الرجاء اختيار العميل أولاً');
      return;
    }
    if (lineItems.isEmpty) {
      _toast('أضف منتجات للفاتورة');
      return;
    }
    final total = grandTotal;
    final isDeferredSale = saleType != 'نقدي';
    if (isDeferredSale && total > customer!.availableCredit) {
      _toast('العميل تجاوز الحد الائتماني المسموح به');
      return;
    }

    final paid = paidNow;
    if (paid < 0) {
      _toast('المبلغ المدفوع غير صحيح');
      return;
    }
    if (!isDeferredSale && (paid - total).abs() > 0.01) {
      _toast('المبلغ المدفوع في حالة الدفع النقدي يجب أن يطابق الإجمالي');
      return;
    }
    if (isDeferredSale && paid > totalDue + 0.01) {
      _toast('المبلغ المدفوع يتجاوز الرصيد المستحق');
      return;
    }
    if (paid > 0 && _paymentMethod == null) {
      _toast('اختر طريقة الدفع');
      return;
    }

    for (final item in lineItems) {
      if (item.product.name.trim().isEmpty ||
          item.quantity <= 0 ||
          item.unitPrice < 0) {
        _toast('يرجى التحقق من كمية وسعر جميع المنتجات');
        return;
      }
    }

    setState(() => _isIssuing = true);

    try {
      final customerId = customer!.customer.id;

      await InvoicesRepository.instance.issueInvoice(
        customerId: customerId,
        items: lineItems
            .map((item) => InvoiceLineInput(
                  productId: item.product.id,
                  productName: item.product.name,
                  unitPrice: item.unitPrice,
                  quantity: item.quantity,
                ))
            .toList(),
        discountPercent: discountPercent,
        isCashSale: !isDeferredSale,
        paidNow: paid,
        paymentMethod: paid > 0 ? _paymentMethod : null,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );

      await CustomersRepository.instance.refresh();

      try {
        await sl<VehicleStockCubit>().refresh();
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        setState(() => _isIssuing = false);
        showAppError(context, e);
      }
      return;
    }

    if (!mounted) return;

    widget.onIssued?.call(IssuedInvoiceInfo(
      invoiceNumber: invoiceNumber,
      amount: total,
      saleType: saleType,
      date: invoiceDate,
    ));

    Navigator.pop(context);
    showAppSuccess(
      context,
      'تم إصدار الفاتورة بنجاح: $invoiceNumber',
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _canBuildPdf() {
    if (customer == null) {
      _toast('الرجاء اختيار العميل');
      return false;
    }
    if (lineItems.isEmpty) {
      _toast('أضف منتجات للفاتورة');
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
        repName: context.read<AuthCubit>().state.user?.name ?? 'غير معروف',
        items: lineItems
            .map((item) => InvoicePdfLineItem(
                  name: item.product.name,
                  quantity: item.quantity,
                  price: item.unitPrice,
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
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
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
                    _RepChip(
                      name: context.watch<AuthCubit>().state.user?.name ??
                          'غير معروف',
                    ),
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
                      BlocBuilder<VehicleStockCubit, VehicleStockState>(
                        bloc: _vehicleStockCubit,
                        builder: (context, vehicleStockState) {
                          final stockInfo =
                              _resolveVehicleStockInfo(vehicleStockState);
                          return _SectionCard(
                            child: _ProductsSection(
                              items: lineItems,
                              currentPage: _currentPage,
                              loadingCustomerPrices: _loadingCustomerPrices,
                              stockKnown: stockInfo.known,
                              stockErrorMessage: stockInfo.errorMessage,
                              onPageChanged: (page) =>
                                  setState(() => _currentPage = page),
                              onAdd: () => _openAddProducts(stockInfo),
                              onPriceChanged: (item, price) =>
                                  setState(() => item.unitPrice = price),
                              onQuantityChanged: (item, qty) => setState(() {
                                final applied = _applyStockGuard(
                                  stockInfo: stockInfo,
                                  product: item.product,
                                  currentQuantity: item.quantity,
                                  desiredQuantity: qty,
                                );
                                if (applied <= 0) {
                                  lineItems.remove(item);
                                  _currentPage = _currentPage.clamp(
                                    1,
                                    lineItems.isEmpty
                                        ? 1
                                        : (lineItems.length / 15).ceil(),
                                  );
                                } else {
                                  item.quantity = applied;
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
                          );
                        },
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
                            saleType: saleType,
                          ),
                        ),
                        if (paidNow > 0) ...[
                          SizedBox(height: 14.h),
                          _SectionCard(
                            child: PaymentMethodSelector(
                              value: _paymentMethod,
                              onChanged: (method) =>
                                  setState(() => _paymentMethod = method),
                            ),
                          ),
                        ],
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
              canIssue: customer != null && lineItems.isNotEmpty && !_isIssuing,
              isIssuing: _isIssuing,
              onSave: _issueInvoice,
              onPrint: _printInvoice,
              onShareWhatsapp: _shareInvoiceOnWhatsapp,
            ),
          ],
        ),
      ),
    );
  }
}

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
                  'إنشاء فاتورة جديدة',
                  style:
                      AppTextStyles.cairoBold18.copyWith(color: Colors.white),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(Icons.qr_code_2_rounded,
                        size: 13.sp, color: Colors.white70),
                    SizedBox(width: 4.w),
                    Flexible(
                        child: Text(invoiceNumber,
                            style: AppTextStyles.almaraiRegular14.copyWith(
                              color: Colors.white70,
                              fontSize: 12.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
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
        Flexible(
            child: Text('المندوب الحالي: $name',
                style: AppTextStyles.almaraiRegular14.copyWith(
                  color: colors.textMuted,
                  fontSize: 12.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

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
        Expanded(
            child: Text(title,
                style: AppTextStyles.cairoMedium16.copyWith(
                  color: colors.text,
                  fontSize: 13.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
        if (trailing != null) trailing!,
      ],
    );
  }
}

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
                      'اختر العميل للإصدار الفاتورة',
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
            Flexible(
                child: Text(invoice.customer.phone,
                    style: AppTextStyles.almaraiRegular14
                        .copyWith(color: colors.textMuted, fontSize: 12.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
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
                  'لا يوجد عملاء مطابقين للبحث',
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
            title: 'الحد الائتماني',
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
            title: 'تاريخ آخر سداد',
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

class _ProductsSection extends StatelessWidget {
  final List<InvoiceLineItemModel> items;
  final int currentPage;
  final bool loadingCustomerPrices;
  final bool stockKnown;
  final String? stockErrorMessage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onAdd;
  final void Function(InvoiceLineItemModel, double) onPriceChanged;
  final void Function(InvoiceLineItemModel, int) onQuantityChanged;
  final void Function(InvoiceLineItemModel) onRemove;
  final double subtotal;
  final double discountPercent;
  final ValueChanged<double> onDiscountChanged;
  final double discountAmount;
  final double grandTotal;

  const _ProductsSection({
    required this.items,
    required this.currentPage,
    required this.loadingCustomerPrices,
    required this.stockKnown,
    this.stockErrorMessage,
    required this.onPageChanged,
    required this.onAdd,
    required this.onPriceChanged,
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
            onPressed: stockKnown ? onAdd : null,
            icon: Icon(Icons.add_circle_outline_rounded,
                size: 16.sp, color: colors.primary),
            label: Text(
              'إضافة منتج',
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: colors.primary, fontSize: 12.sp),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        if (!stockKnown)
          Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: colors.statusNotReached.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline,
                    size: 14.sp, color: colors.statusNotReached),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    stockErrorMessage ?? 'جاري تحميل مخزون العربية...',
                    style: AppTextStyles.almaraiRegular14.copyWith(
                        color: colors.statusNotReached, fontSize: 11.sp),
                  ),
                ),
              ],
            ),
          ),
        if (items.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'لا يوجد منتجات مضافة للفاتورة حتى الآن',
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: colors.textMuted, fontSize: 12.sp),
            ),
          )
        else
          ...items.skip((currentPage - 1) * 15).take(15).map(
                (item) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: _LineItemTile(
                    item: item,
                    loadingCustomerPrices: loadingCustomerPrices,
                    onPriceChanged: (price) => onPriceChanged(item, price),
                    onQuantityChanged: (q) => onQuantityChanged(item, q),
                    onRemove: () => onRemove(item),
                  ),
                ),
              ),
        if (items.isNotEmpty) ...[
          _InvoicePagination(
            itemCount: items.length,
            currentPage: currentPage,
            onPageChanged: onPageChanged,
          ),
          SizedBox(height: 10.h),
          Divider(height: 1, color: colors.border),
          SizedBox(height: 10.h),
          _TotalsRow(label: 'الإجمالي قبل الخصم', value: _money(subtotal)),
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
        SizedBox(width: 8.w),
        Expanded(
            child: Text(value,
                style: AppTextStyles.cairoMedium16.copyWith(
                  color: muted ? colors.statOrange : colors.text,
                  fontSize: 13.sp,
                ),
                textAlign: TextAlign.end)),
      ],
    );
  }
}

class _InvoicePagination extends StatelessWidget {
  final int itemCount;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _InvoicePagination({
    required this.itemCount,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pageCount = (itemCount / 15).ceil();
    final start = (currentPage - 1) * 15 + 1;
    final end = (currentPage * 15).clamp(0, itemCount);
    return Padding(
      padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
      child: Column(
        children: [
          Text(
            'الأصناف $start - $end من $itemCount',
            style: AppTextStyles.almaraiRegular14.copyWith(
              color: colors.textMuted,
              fontSize: 11.sp,
            ),
          ),
          if (pageCount > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: currentPage > 1
                      ? () => onPageChanged(currentPage - 1)
                      : null,
                  child: const Text('السابق'),
                ),
                for (var page = 1; page <= pageCount; page++)
                  TextButton(
                    onPressed:
                        page == currentPage ? null : () => onPageChanged(page),
                    child: Text('$page'),
                  ),
                TextButton(
                  onPressed: currentPage < pageCount
                      ? () => onPageChanged(currentPage + 1)
                      : null,
                  child: const Text('التالي'),
                ),
              ],
            ),
        ],
      ),
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
  final bool loadingCustomerPrices;
  final ValueChanged<double> onPriceChanged;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const _LineItemTile({
    required this.item,
    required this.loadingCustomerPrices,
    required this.onPriceChanged,
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
                  item.previousCustomerPrice == null
                      ? 'سعر الأساسي: ${_money(item.product.price)}'
                      : 'السعر السابق للعميل: ${_money(item.previousCustomerPrice!)}',
                  style: AppTextStyles.almaraiRegular14
                      .copyWith(color: colors.textMuted, fontSize: 10.5.sp),
                ),
                SizedBox(height: 5.h),
                SizedBox(
                  height: 36.h,
                  width: 120.w,
                  child: TextFormField(
                    initialValue: item.unitPrice.toStringAsFixed(2),
                    enabled: !loadingCustomerPrices,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onChanged: (value) {
                      final price = double.tryParse(value);
                      if (price != null && price >= 0) onPriceChanged(price);
                    },
                    decoration: const InputDecoration(
                      labelText: 'سعر البيع',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
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

/// Lowercases and unifies Arabic letter variants so "اتكو" finds "إتكو",
/// "موكس" finds "مُوكس", etc.
String _normalizeArabic(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .trim();
}

/// Product picker of the invoice.
///
///  * Lists ONLY the products on the rep's own vehicle (see
///    [_VehicleStockInfo.products]).
///  * Shows the price on every row — the customer's own last price when he
///    bought the product before — so the rep can answer "بكام ده؟" without
///    adding anything.
///  * The "تم" button is pinned at the bottom; the list is lazy, so it stays
///    fast with thousands of products.
class _ProductPickerSheet extends StatefulWidget {
  final List<InvoiceLineItemModel> existing;
  final List<ProductModel> products;
  final Map<String, CustomerProductPrice> customerPrices;
  final Map<String, int> stockByProductId;
  const _ProductPickerSheet({
    required this.existing,
    required this.products,
    required this.customerPrices,
    required this.stockByProductId,
  });

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  late List<InvoiceLineItemModel> cart;
  late final List<InvoiceProductModel> _allProducts;
  late final Map<String, String> _searchKeys;
  String query = '';

  @override
  void initState() {
    super.initState();
    cart = widget.existing
        .map((e) => InvoiceLineItemModel(
              product: e.product,
              quantity: e.quantity,
              unitPrice: e.unitPrice,
              previousCustomerPrice: e.previousCustomerPrice,
            ))
        .toList();

    final products = widget.products.map(_invoiceProductFromInventory).toList();
    // A line that is already on the invoice must stay editable even if its
    // stock ran out in the meantime.
    final knownIds = products.map((p) => p.id).toSet();
    for (final line in widget.existing) {
      if (!knownIds.contains(line.product.id)) products.add(line.product);
    }
    // Products this customer bought before come first, then A-Z.
    products.sort((a, b) {
      final aBought = widget.customerPrices.containsKey(a.id);
      final bBought = widget.customerPrices.containsKey(b.id);
      if (aBought != bBought) return aBought ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    _allProducts = products;
    _searchKeys = {for (final p in products) p.id: _normalizeArabic(p.name)};
  }

  List<InvoiceProductModel> get _visibleProducts {
    final words = _normalizeArabic(query).split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return _allProducts;
    return _allProducts.where((p) {
      final key = _searchKeys[p.id] ?? '';
      return words.every(key.contains);
    }).toList();
  }

  int _quantityFor(InvoiceProductModel p) {
    final match = cart.where((c) => c.product.id == p.id);
    return match.isEmpty ? 0 : match.first.quantity;
  }

  int _availableStockFor(InvoiceProductModel p) =>
      widget.stockByProductId[p.id] ?? 0;

  double get _cartTotal => cart.fold(0.0, (sum, line) => sum + line.total);

  void _setQuantity(InvoiceProductModel p, int qty) {
    final available = _availableStockFor(p);
    final clamped = qty < 0 ? 0 : (qty > available ? available : qty);
    setState(() {
      final existingIndex = cart.indexWhere((c) => c.product.id == p.id);
      final existingPrice =
          existingIndex == -1 ? null : cart[existingIndex].unitPrice;
      cart.removeWhere((c) => c.product.id == p.id);
      if (clamped > 0) {
        final previous = widget.customerPrices[p.id]?.lastPrice;
        cart.add(InvoiceLineItemModel(
          product: p,
          quantity: clamped,
          unitPrice: existingPrice ?? previous ?? p.price,
          previousCustomerPrice: previous,
        ));
      }
    });
    if (clamped < qty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('الكمية المتاحة في العربية أقل من المطلوب')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final visible = _visibleProducts;

    // Moves the whole sheet (including the pinned button) above the keyboard.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
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
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 8.w, 4.h),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          color: colors.primary, size: 18.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'منتجات عربيتك',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cairoBold18
                              .copyWith(color: colors.text, fontSize: 15.sp),
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
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                  child: TextField(
                    onChanged: (v) => setState(() => query = v),
                    style: TextStyle(color: colors.text),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن منتج لمعرفة سعره...',
                      hintStyle: TextStyle(color: colors.textMuted),
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 20.sp, color: colors.textMuted),
                      filled: true,
                      fillColor: colors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 12.h, horizontal: 12.w),
                    ),
                  ),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? _PickerEmptyState(hasStock: _allProducts.isNotEmpty)
                      : ListView.builder(
                          controller: scrollController,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                          itemCount: visible.length,
                          itemBuilder: (context, index) =>
                              _buildProductRow(context, visible[index]),
                        ),
                ),
                _buildFooter(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductRow(BuildContext context, InvoiceProductModel p) {
    final colors = context.colors;
    final qty = _quantityFor(p);
    final available = _availableStockFor(p);
    final outOfStock = available <= 0 && qty == 0;
    final previous = widget.customerPrices[p.id]?.lastPrice;
    final price = previous ?? p.price;
    final differsFromList =
        previous != null && (previous - p.price).abs() > 0.005;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: qty > 0 ? colors.primary.withOpacity(0.08) : colors.background,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                qty > 0 ? colors.primary.withOpacity(0.35) : Colors.transparent,
          ),
        ),
        child: Opacity(
          opacity: outOfStock ? 0.5 : 1,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cairoMedium16
                          .copyWith(color: colors.text, fontSize: 12.5.sp),
                    ),
                    SizedBox(height: 4.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 2.h,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: (previous != null
                                    ? colors.primary
                                    : colors.textMuted)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '${previous != null ? 'سعر العميل' : 'سعر البيع'}: ${_money(price)}',
                            style: AppTextStyles.cairoMedium16.copyWith(
                              color: previous != null
                                  ? colors.primary
                                  : colors.text,
                              fontSize: 11.5.sp,
                            ),
                          ),
                        ),
                        if (differsFromList)
                          Text(
                            'العادي: ${_money(p.price)}',
                            style: AppTextStyles.almaraiRegular14.copyWith(
                              color: colors.textMuted,
                              fontSize: 10.5.sp,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      outOfStock
                          ? 'غير متاح في مخزون العربية'
                          : 'المتاح بالعربية: $available',
                      style: AppTextStyles.almaraiRegular14.copyWith(
                        color: outOfStock
                            ? colors.statusNotReached
                            : colors.textMuted,
                        fontSize: 10.5.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              if (outOfStock)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: colors.textMuted.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text('غير متاح',
                      style: AppTextStyles.cairoMedium16
                          .copyWith(color: colors.textMuted, fontSize: 11.sp)),
                )
              else if (qty == 0)
                Material(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(10.r),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10.r),
                    onTap: () => _setQuantity(p, 1),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      child: Text('إضافة',
                          style: AppTextStyles.cairoMedium16
                              .copyWith(color: Colors.white, fontSize: 11.sp)),
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
                          style: AppTextStyles.cairoMedium16
                              .copyWith(color: colors.text, fontSize: 12.sp)),
                    ),
                    _StepButton(
                      icon: Icons.add_rounded,
                      onTap: qty >= available
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'الكمية المتاحة في العربية أقل من المطلوب')),
                              );
                            }
                          : () => _setQuantity(p, qty + 1),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Always visible, no matter how long the list is.
  Widget _buildFooter(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16.w,
        10.h,
        16.w,
        12.h + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, cart),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text(
                'تم (${cart.length} أصناف)',
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: Colors.white, fontSize: 13.sp),
              ),
            ),
          ),
          if (cart.isNotEmpty) ...[
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('الإجمالي',
                    style: AppTextStyles.almaraiRegular14
                        .copyWith(color: colors.textMuted, fontSize: 10.sp)),
                Text(_money(_cartTotal),
                    style: AppTextStyles.cairoBold18
                        .copyWith(color: colors.text, fontSize: 13.sp)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PickerEmptyState extends StatelessWidget {
  /// false: nothing is on the vehicle at all. true: the search found nothing.
  final bool hasStock;

  const _PickerEmptyState({required this.hasStock});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Text(
          hasStock
              ? 'مفيش منتج بالاسم ده في عربيتك'
              : 'مفيش منتجات في مخزون عربيتك دلوقتي',
          textAlign: TextAlign.center,
          style: AppTextStyles.almaraiRegular14
              .copyWith(color: colors.textMuted, fontSize: 12.sp),
        ),
      ),
    );
  }
}

class _AccountSummarySection extends StatelessWidget {
  final double previousBalance;
  final double invoiceTotal;
  final TextEditingController paidController;
  final ValueChanged<String> onPaidChanged;
  final double remaining;
  final String saleType;

  const _AccountSummarySection({
    required this.previousBalance,
    required this.invoiceTotal,
    required this.paidController,
    required this.onPaidChanged,
    required this.remaining,
    required this.saleType,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalDue = previousBalance + invoiceTotal;
    final isSettled = remaining <= 0;
    final paid = double.tryParse(paidController.text) ?? 0;
    final isCash = saleType == 'نقدي';

    final String? warning = isCash && (paid - invoiceTotal).abs() > 0.01
        ? 'المبلغ المدفوع في حالة الدفع النقدي يجب أن يطابق إجمالي الفاتورة (${_money(invoiceTotal)}) تماماً'
        : !isCash && paid > totalDue + 0.01
            ? 'المبلغ المدفوع يتجاوز إجمالي المستحق على العميل'
            : null;

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
        Row(
          children: [
            Text('المدفوع الآن',
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: colors.textMuted, fontSize: 12.sp)),
            if (isCash) ...[
              SizedBox(width: 8.w),
              Text('(نقدي - ملزم بتسديد كامل الفاتورة)',
                  style: AppTextStyles.almaraiRegular14
                      .copyWith(color: colors.statOrange, fontSize: 10.sp)),
            ],
          ],
        ),
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
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: warning != null
                    ? colors.statusNotReached
                    : Colors.transparent,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color:
                    warning != null ? colors.statusNotReached : colors.primary,
              ),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            suffixIcon: isCash
                ? TextButton(
                    onPressed: () {
                      paidController.text = invoiceTotal.toStringAsFixed(2);
                      onPaidChanged(paidController.text);
                    },
                    child: Text('تعبئة كاملة',
                        style: AppTextStyles.cairoMedium16
                            .copyWith(color: colors.primary, fontSize: 11.sp)),
                  )
                : null,
          ),
        ),
        if (warning != null) ...[
          SizedBox(height: 6.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline,
                  size: 14.sp, color: colors.statusNotReached),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  warning,
                  style: AppTextStyles.almaraiRegular14.copyWith(
                      color: colors.statusNotReached, fontSize: 11.sp),
                ),
              ),
            ],
          ),
        ],
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
            icon: Icons.edit_note_rounded, title: 'ملاحظات إضافية'),
        SizedBox(height: 10.h),
        TextField(
          controller: controller,
          maxLines: 3,
          style: TextStyle(color: colors.text),
          decoration: InputDecoration(
            hintText: 'اكتب ملاحظاتك على الزيارة أو الفاتورة...',
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
              icon: Icons.insights_rounded, title: 'تحليل المشتريات للعميل'),
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
                    title: 'لم يشتريها منذ فترة',
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
                isIssuing ? 'جاري الإصدار...' : 'حفظ وإصدار الفاتورة',
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

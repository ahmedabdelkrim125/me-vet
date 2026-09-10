import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:printing/printing.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import '../../../customer-visits/customers/data/customers_repository.dart';
import '../../../customer-visits/customers/data/invoices_repository.dart';
import '../../../customer-visits/customers/domain/models/invoice_line_input.dart';
import '../../../inventory/data/products_repository.dart';
import '../../../inventory/domain/models/product_model.dart';
import '../../../invoices/domain/invoice_pdf_builder.dart';
import '../../../invoices/domain/invoice_draft.dart';
import '../../domain/models/quick_invoice_models.dart';
import '../../../customer_account/domain/entities/payment_method.dart';
import '../../../customer_account/presentation/widgets/payment_method_selector.dart';

const _currentRepName =
    'ط·آ·ط¢آ£ط·آ·ط¢آ­ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ¯ ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ­ط·آ¸أ¢â‚¬آ¦ط·آ¸ط«â€ ط·آ·ط¢آ¯';

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
    unit: product.unit,
  );
}

List<PastInvoiceSummaryModel> _statementFor(InvoiceCustomerModel invoice) {
  return const [];
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
  if (decimals > 0.005)
    out += '.${(decimals * 100).round().toString().padLeft(2, '0')}';
  return '${negative ? '-' : ''}$out ط·آ·ط¢آ¬.ط·آ¸أ¢â‚¬آ¦';
}

String _date(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
  String saleType = 'ط·آ·ط¢آ¢ط·آ·ط¢آ¬ط·آ¸أ¢â‚¬â€چ';

  InvoiceCustomerModel? customer;
  final List<InvoiceLineItemModel> lineItems = [];
  Map<String, CustomerProductPrice> _customerPrices = {};
  int _currentPage = 1;
  bool _loadingCustomerPrices = false;
  double discountPercent = 0;
  final notesController = TextEditingController();
  final paidNowController = TextEditingController(text: '0');
  bool _isIssuing = false;
  PaymentMethod? _paymentMethod;

  @override
  void initState() {
    super.initState();
    invoiceNumber = 'INV-${invoiceDate.year}-${100 + Random().nextInt(900)}';
    customer = widget.initialCustomer;
    CustomersRepository.instance.initialize();
    if (customer != null) _loadCustomerPrices(customer!.customer.id);
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
    setState(() {
      _loadingCustomerPrices = true;
      _customerPrices = {};
    });
    try {
      final prices = await InvoicesRepository.instance
          .getCustomerProductPrices(customerId);
      if (mounted && customer?.customer.id == customerId) {
        setState(() => _customerPrices = prices);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingCustomerPrices = false);
    }
  }

  Future<void> _openAddProducts() async {
    if (!mounted) return;
    List<ProductModel> products;
    try {
      products = await ProductsRepository.instance.getProducts();
    } catch (error) {
      if (mounted) showAppError(context, error);
      return;
    }
    if (!mounted) return;
    final added = await showModalBottomSheet<List<InvoiceLineItemModel>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductPickerSheet(
        existing: lineItems,
        products: products,
        customerPrices: _customerPrices,
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
    if (customer == null) {
      _toast(
          'ط·آ·ط¢آ§ط·آ·ط¢آ®ط·آ·ط¹آ¾ط·آ·ط¢آ± ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¹ط·آ¸أ¢â‚¬آ¦ط·آ¸ط¸آ¹ط·آ¸أ¢â‚¬â€چ ط·آ·ط¢آ£ط·آ¸ط«â€ ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¹ط·آ·ط¢آ§');
      return;
    }
    if (lineItems.isEmpty) {
      _toast(
          'ط·آ·ط¢آ£ط·آ·ط¢آ¶ط·آ¸ط¸آ¾ ط·آ·ط¢آµط·آ¸أ¢â‚¬آ ط·آ¸ط¸آ¾ط·آ¸أ¢â‚¬آ¹ط·آ·ط¢آ§ ط·آ¸ط«â€ ط·آ·ط¢آ§ط·آ·ط¢آ­ط·آ·ط¢آ¯ط·آ¸أ¢â‚¬آ¹ط·آ·ط¢آ§ ط·آ·ط¢آ¹ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ° ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ£ط·آ¸أ¢â‚¬ع‘ط·آ¸أ¢â‚¬â€چ ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¾ط·آ·ط¢آ§ط·آ·ط¹آ¾ط·آ¸ط«â€ ط·آ·ط¢آ±ط·آ·ط¢آ©');
      return;
    }
    final total = grandTotal;
    final isDeferredSale = saleType != 'ط·آ¸أ¢â‚¬آ ط·آ¸أ¢â‚¬ع‘ط·آ·ط¢آ¯ط·آ¸ط¸آ¹';
    if (isDeferredSale && total > customer!.availableCredit) {
      _toast(
          'ط·آ¸أ¢â‚¬ع‘ط·آ¸ط¸آ¹ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ© ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¾ط·آ·ط¢آ§ط·آ·ط¹آ¾ط·آ¸ط«â€ ط·آ·ط¢آ±ط·آ·ط¢آ© ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¢ط·آ·ط¢آ¬ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ© ط·آ·ط¹آ¾ط·آ·ط¹آ¾ط·آ·ط¢آ¬ط·آ·ط¢آ§ط·آ¸ط«â€ ط·آ·ط¢آ² ط·آ·ط¢آ­ط·آ·ط¢آ¯ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ§ط·آ·ط¢آ¦ط·آ·ط¹آ¾ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ§ط·آ¸أ¢â‚¬آ  ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ·ط¹آ¾ط·آ·ط¢آ§ط·آ·ط¢آ­');
      return;
    }

    final paid = paidNow;
    if (paid < 0) {
      _toast(
          'ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ¨ط·آ¸أ¢â‚¬â€چط·آ·ط·â€؛ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ¯ط·آ¸ط¸آ¾ط·آ¸ط«â€ ط·آ·ط¢آ¹ ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ§ط·آ·ط¢آ²ط·آ¸أ¢â‚¬آ¦ ط·آ¸ط¸آ¹ط·آ¸ط¦â€™ط·آ¸ط«â€ ط·آ¸أ¢â‚¬آ  ط·آ·ط¢آ±ط·آ¸أ¢â‚¬ع‘ط·آ¸أ¢â‚¬آ¦ ط·آ¸أ¢â‚¬آ¦ط·آ¸ط«â€ ط·آ·ط¢آ¬ط·آ·ط¢آ¨');
      return;
    }
    if (!isDeferredSale && (paid - total).abs() > 0.01) {
      _toast(
        'ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¾ط·آ·ط¢آ§ط·آ·ط¹آ¾ط·آ¸ط«â€ ط·آ·ط¢آ±ط·آ·ط¢آ© ط·آ¸أ¢â‚¬آ ط·آ¸أ¢â‚¬ع‘ط·آ·ط¢آ¯ط·آ¸ط¸آ¹ط·آ·ط¥â€™ ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ§ط·آ·ط¢آ²ط·آ¸أ¢â‚¬آ¦ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ¯ط·آ¸ط¸آ¾ط·آ¸ط«â€ ط·آ·ط¢آ¹ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¢ط·آ¸أ¢â‚¬آ  ط·آ¸ط¸آ¹ط·آ·ط¢آ³ط·آ·ط¢آ§ط·آ¸ط«â€ ط·آ¸ط¸آ¹ ط·آ·ط¢آ¥ط·آ·ط¢آ¬ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¹ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¾ط·آ·ط¢آ§ط·آ·ط¹آ¾ط·آ¸ط«â€ ط·آ·ط¢آ±ط·آ·ط¢آ© (${_money(total)}) ط·آ·ط¢آ¨ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¸ط·آ·ط¢آ¨ط·آ·ط¢آ·',
      );
      return;
    }
    if (isDeferredSale && paid > totalDue + 0.01) {
      _toast(
          'ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ¨ط·آ¸أ¢â‚¬â€چط·آ·ط·â€؛ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ¯ط·آ¸ط¸آ¾ط·آ¸ط«â€ ط·آ·ط¢آ¹ ط·آ·ط¢آ£ط·آ¸ط¦â€™ط·آ·ط¢آ¨ط·آ·ط¢آ± ط·آ¸أ¢â‚¬آ¦ط·آ¸أ¢â‚¬آ  ط·آ·ط¢آ¥ط·آ·ط¢آ¬ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¹ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ³ط·آ·ط¹آ¾ط·آ·ط¢آ­ط·آ¸أ¢â‚¬ع‘ ط·آ·ط¢آ¹ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ° ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¹ط·آ¸أ¢â‚¬آ¦ط·آ¸ط¸آ¹ط·آ¸أ¢â‚¬â€چ');
      return;
    }
    if (paid > 0 && _paymentMethod == null) {
      _toast(
          'ط·آ·ط¢آ§ط·آ·ط¢آ®ط·آ·ط¹آ¾ط·آ·ط¢آ± ط·آ·ط¢آ·ط·آ·ط¢آ±ط·آ¸ط¸آ¹ط·آ¸أ¢â‚¬ع‘ط·آ·ط¢آ© ط·آ·ط¢آ¯ط·آ¸ط¸آ¾ط·آ·ط¢آ¹ ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ¨ط·آ¸أ¢â‚¬â€چط·آ·ط·â€؛ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ¯ط·آ¸ط¸آ¾ط·آ¸ط«â€ ط·آ·ط¢آ¹ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¢ط·آ¸أ¢â‚¬آ ');
      return;
    }

    for (final item in lineItems) {
      if (item.product.name.trim().isEmpty ||
          item.quantity <= 0 ||
          item.unitPrice < 0) {
        _toast(
            'ط·آ·ط¢آ±ط·آ·ط¢آ§ط·آ·ط¢آ¬ط·آ·ط¢آ¹ ط·آ·ط¢آ§ط·آ·ط¢آ³ط·آ¸أ¢â‚¬آ¦ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آµط·آ¸أ¢â‚¬آ ط·آ¸ط¸آ¾ ط·آ¸ط«â€ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¦â€™ط·آ¸أ¢â‚¬آ¦ط·آ¸ط¸آ¹ط·آ·ط¢آ© ط·آ¸ط«â€ ط·آ·ط¢آ³ط·آ·ط¢آ¹ط·آ·ط¢آ± ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¨ط·آ¸ط¸آ¹ط·آ·ط¢آ¹');
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
      'ط·آ·ط¹آ¾ط·آ¸أ¢â‚¬آ¦ ط·آ·ط¢آ¥ط·آ·ط¢آµط·آ·ط¢آ¯ط·آ·ط¢آ§ط·آ·ط¢آ± ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¾ط·آ·ط¢آ§ط·آ·ط¹آ¾ط·آ¸ط«â€ ط·آ·ط¢آ±ط·آ·ط¢آ© $invoiceNumber ط·آ·ط¢آ¨ط·آ·ط¢آ¥ط·آ·ط¢آ¬ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¹ ${_money(total)} ط£آ¢أ¢â€ڑآ¬أ¢â‚¬â€Œ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ·ط¹آ¾ط·آ·ط¢آ¨ط·آ¸أ¢â‚¬ع‘ط·آ¸ط¸آ¹ ط·آ·ط¢آ¹ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ° ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¹ط·آ¸أ¢â‚¬آ¦ط·آ¸ط¸آ¹ط·آ¸أ¢â‚¬â€چ ${_money(remainingBalance)}',
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _canBuildPdf() {
    if (customer == null) {
      _toast(
          'ط·آ·ط¢آ§ط·آ·ط¢آ®ط·آ·ط¹آ¾ط·آ·ط¢آ± ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¹ط·آ¸أ¢â‚¬آ¦ط·آ¸ط¸آ¹ط·آ¸أ¢â‚¬â€چ ط·آ·ط¢آ£ط·آ¸ط«â€ ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¹ط·آ·ط¢آ§');
      return false;
    }
    if (lineItems.isEmpty) {
      _toast(
          'ط·آ·ط¢آ£ط·آ·ط¢آ¶ط·آ¸ط¸آ¾ ط·آ·ط¢آµط·آ¸أ¢â‚¬آ ط·آ¸ط¸آ¾ط·آ¸أ¢â‚¬آ¹ط·آ·ط¢آ§ ط·آ¸ط«â€ ط·آ·ط¢آ§ط·آ·ط¢آ­ط·آ·ط¢آ¯ط·آ¸أ¢â‚¬آ¹ط·آ·ط¢آ§ ط·آ·ط¢آ¹ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ° ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ£ط·آ¸أ¢â‚¬ع‘ط·آ¸أ¢â‚¬â€چ ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¾ط·آ·ط¢آ§ط·آ·ط¹آ¾ط·آ¸ط«â€ ط·آ·ط¢آ±ط·آ·ط¢آ©');
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
                          currentPage: _currentPage,
                          loadingCustomerPrices: _loadingCustomerPrices,
                          onPageChanged: (page) =>
                              setState(() => _currentPage = page),
                          onAdd: _openAddProducts,
                          onPriceChanged: (item, price) =>
                              setState(() => item.unitPrice = price),
                          onQuantityChanged: (item, qty) => setState(() {
                            if (qty <= 0) {
                              lineItems.remove(item);
                              _currentPage = _currentPage.clamp(
                                1,
                                lineItems.isEmpty
                                    ? 1
                                    : (lineItems.length / 15).ceil(),
                              );
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
                  'ط·آ¸ط¸آ¾ط·آ·ط¢آ§ط·آ·ط¹آ¾ط·آ¸ط«â€ ط·آ·ط¢آ±ط·آ·ط¢آ© ط·آ·ط¢آ¬ط·آ·ط¢آ¯ط·آ¸ط¸آ¹ط·آ·ط¢آ¯ط·آ·ط¢آ©',
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
          'ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ¸أ¢â‚¬آ ط·آ·ط¢آ¯ط·آ¸ط«â€ ط·آ·ط¢آ¨: $name',
          style: AppTextStyles.almaraiRegular14.copyWith(
            color: colors.textMuted,
            fontSize: 12.sp,
          ),
        ),
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
            icon: Icons.storefront_outlined,
            title:
                'ط·آ·ط¢آ¨ط·آ¸ط¸آ¹ط·آ·ط¢آ§ط·آ¸أ¢â‚¬آ ط·آ·ط¢آ§ط·آ·ط¹آ¾ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¹ط·آ¸أ¢â‚¬آ¦ط·آ¸ط¸آ¹ط·آ¸أ¢â‚¬â€چ'),
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
                      'ط·آ·ط¢آ§ط·آ·ط¢آ®ط·آ·ط¹آ¾ط·آ·ط¢آ± ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¹ط·آ¸أ¢â‚¬آ¦ط·آ¸ط¸آ¹ط·آ¸أ¢â‚¬â€چ ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¨ط·آ·ط¢آ¯ط·آ·ط·إ’ ط·آ·ط¢آ¥ط·آ·ط¢آµط·آ·ط¢آ¯ط·آ·ط¢آ§ط·آ·ط¢آ± ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¾ط·آ·ط¢آ§ط·آ·ط¹آ¾ط·آ¸ط«â€ ط·آ·ط¢آ±ط·آ·ط¢آ©',
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
                'ط·آ·ط¹آ¾ط·آ·ط·â€؛ط·آ¸ط¸آ¹ط·آ¸ط¸آ¹ط·آ·ط¢آ±',
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
      title:
          'ط·آ·ط¢آ§ط·آ·ط¢آ®ط·آ·ط¹آ¾ط·آ·ط¢آ± ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¹ط·آ¸أ¢â‚¬آ¦ط·آ¸ط¸آ¹ط·آ¸أ¢â‚¬â€چ',
      icon: Icons.storefront_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: (v) => setState(() => query = v),
            style: TextStyle(color: colors.text),
            decoration: InputDecoration(
              hintText:
                  'ط·آ·ط¢آ§ط·آ·ط¢آ¨ط·آ·ط¢آ­ط·آ·ط¢آ« ط·آ·ط¢آ¨ط·آ·ط¢آ§ط·آ·ط¢آ³ط·آ¸أ¢â‚¬آ¦ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¹ط·آ¸أ¢â‚¬آ¦ط·آ¸ط¸آ¹ط·آ¸أ¢â‚¬â€چ...',
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
                  'ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ§ ط·آ¸ط¸آ¹ط·آ¸ط«â€ ط·آ·ط¢آ¬ط·آ·ط¢آ¯ ط·آ·ط¢آ¹ط·آ¸أ¢â‚¬آ¦ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ§ط·آ·ط·إ’ ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ·ط·آ·ط¢آ§ط·آ·ط¢آ¨ط·آ¸أ¢â‚¬ع‘ط·آ¸ط¸آ¹ط·آ¸أ¢â‚¬آ ',
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
            icon: Icons.receipt_long_outlined,
            title:
                'ط·آ·ط¢آ¨ط·آ¸ط¸آ¹ط·آ·ط¢آ§ط·آ¸أ¢â‚¬آ ط·آ·ط¢آ§ط·آ·ط¹آ¾ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¾ط·آ·ط¢آ§ط·آ·ط¹آ¾ط·آ¸ط«â€ ط·آ·ط¢آ±ط·آ·ط¢آ©'),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _TappableField(
                label:
                    'ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¹آ¾ط·آ·ط¢آ§ط·آ·ط¢آ±ط·آ¸ط¸آ¹ط·آ·ط¢آ®',
                value: _date(date),
                icon: Icons.calendar_today_outlined,
                onTap: onPickDate,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _StaticField(
                label:
                    'ط·آ·ط¢آ±ط·آ¸أ¢â‚¬ع‘ط·آ¸أ¢â‚¬آ¦ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¾ط·آ·ط¢آ§ط·آ·ط¹آ¾ط·آ¸ط«â€ ط·آ·ط¢آ±ط·آ·ط¢آ©',
                value: invoiceNumber,
                icon: Icons.tag_rounded,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Text(
          'ط·آ¸أ¢â‚¬آ ط·آ¸ط«â€ ط·آ·ط¢آ¹ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¨ط·آ¸ط¸آ¹ط·آ·ط¢آ¹',
          style: AppTextStyles.almaraiRegular14
              .copyWith(color: colors.textMuted, fontSize: 12.sp),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _SaleTypeOption(
                label: 'ط·آ¸أ¢â‚¬آ ط·آ¸أ¢â‚¬ع‘ط·آ·ط¢آ¯ط·آ¸ط¸آ¹',
                icon: Icons.payments_outlined,
                selected: saleType == 'ط·آ¸أ¢â‚¬آ ط·آ¸أ¢â‚¬ع‘ط·آ·ط¢آ¯ط·آ¸ط¸آ¹',
                onTap: () =>
                    onSaleTypeChanged('ط·آ¸أ¢â‚¬آ ط·آ¸أ¢â‚¬ع‘ط·آ·ط¢آ¯ط·آ¸ط¸آ¹'),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _SaleTypeOption(
                label: 'ط·آ·ط¢آ¢ط·آ·ط¢آ¬ط·آ¸أ¢â‚¬â€چ',
                icon: Icons.schedule_outlined,
                selected: saleType == 'ط·آ·ط¢آ¢ط·آ·ط¢آ¬ط·آ¸أ¢â‚¬â€چ',
                onTap: () => onSaleTypeChanged('ط·آ·ط¢آ¢ط·آ·ط¢آ¬ط·آ¸أ¢â‚¬â€چ'),
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
            title:
                'ط·آ·ط¢آ­ط·آ·ط¢آ¯ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ§ط·آ·ط¢آ¦ط·آ·ط¹آ¾ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ§ط·آ¸أ¢â‚¬آ ',
            value: _money(invoice.customer.creditLimit),
            icon: Icons.verified_user_outlined,
            color: colors.statBlue,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _FinancialCard(
            title:
                'ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ±ط·آ·ط¢آµط·آ¸ط¸آ¹ط·آ·ط¢آ¯ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ­ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¹',
            value: _money(invoice.customer.currentBalance),
            icon: Icons.account_balance_wallet_outlined,
            color: nearLimit ? colors.statusNotReached : colors.statOrange,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _FinancialCard(
            title: 'ط·آ·ط¢آ¢ط·آ·ط¢آ®ط·آ·ط¢آ± ط·آ·ط¢آ³ط·آ·ط¢آ¯ط·آ·ط¢آ§ط·آ·ط¢آ¯',
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
                  'ط·آ¸ط¦â€™ط·آ·ط¢آ´ط·آ¸ط¸آ¾ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ­ط·آ·ط¢آ³ط·آ·ط¢آ§ط·آ·ط¢آ¨ ط£آ¢أ¢â€ڑآ¬أ¢â‚¬â€Œ ط·آ·ط¢آ¢ط·آ·ط¢آ®ط·آ·ط¢آ± 6 ط·آ·ط¢آ´ط·آ¸أ¢â‚¬طŒط·آ¸ط«â€ ط·آ·ط¢آ±',
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
      title:
          'ط·آ¸ط¦â€™ط·آ·ط¢آ´ط·آ¸ط¸آ¾ ط·آ·ط¢آ­ط·آ·ط¢آ³ط·آ·ط¢آ§ط·آ·ط¢آ¨ ط£آ¢أ¢â€ڑآ¬أ¢â‚¬â€Œ ${invoice.customer.name}',
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
                        color: (e.status ==
                                    'ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ¯ط·آ¸ط¸آ¾ط·آ¸ط«â€ ط·آ·ط¢آ¹ط·آ·ط¢آ©'
                                ? colors.primary
                                : colors.statOrange)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        e.status,
                        style: AppTextStyles.almaraiRegular14.copyWith(
                          color: e.status ==
                                  'ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ¯ط·آ¸ط¸آ¾ط·آ¸ط«â€ ط·آ·ط¢آ¹ط·آ·ط¢آ©'
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

class _ProductsSection extends StatelessWidget {
  final List<InvoiceLineItemModel> items;
  final int currentPage;
  final bool loadingCustomerPrices;
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
          title:
              'ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ£ط·آ·ط¢آµط·آ¸أ¢â‚¬آ ط·آ·ط¢آ§ط·آ¸ط¸آ¾ (${items.length})',
          trailing: TextButton.icon(
            onPressed: onAdd,
            icon: Icon(Icons.add_circle_outline_rounded,
                size: 16.sp, color: colors.primary),
            label: Text(
              'ط·آ·ط¢آ¥ط·آ·ط¢آ¶ط·آ·ط¢آ§ط·آ¸ط¸آ¾ط·آ·ط¢آ© ط·آ·ط¢آµط·آ¸أ¢â‚¬آ ط·آ¸ط¸آ¾',
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
              'ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ ط·آ·ط¹آ¾ط·آ·ط¹آ¾ط·آ¸أ¢â‚¬آ¦ ط·آ·ط¢آ¥ط·آ·ط¢آ¶ط·آ·ط¢آ§ط·آ¸ط¸آ¾ط·آ·ط¢آ© ط·آ·ط¢آ£ط·آ·ط¢آµط·آ¸أ¢â‚¬آ ط·آ·ط¢آ§ط·آ¸ط¸آ¾ ط·آ·ط¢آ¨ط·آ·ط¢آ¹ط·آ·ط¢آ¯',
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
          _TotalsRow(
              label:
                  'ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¥ط·آ·ط¢آ¬ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¹ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¾ط·آ·ط¢آ±ط·آ·ط¢آ¹ط·آ¸ط¸آ¹',
              value: _money(subtotal)),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(
                'ط·آ·ط¢آ®ط·آ·ط¢آµط·آ¸أ¢â‚¬آ¦ %',
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
              label:
                  'ط·آ¸أ¢â‚¬ع‘ط·آ¸ط¸آ¹ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ© ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ®ط·آ·ط¢آµط·آ¸أ¢â‚¬آ¦',
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
                  'ط·آ·ط¢آ¥ط·آ·ط¢آ¬ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¹ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¾ط·آ·ط¢آ§ط·آ·ط¹آ¾ط·آ¸ط«â€ ط·آ·ط¢آ±ط·آ·ط¢آ©',
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
            'ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ£ط·آ·ط¢آµط·آ¸أ¢â‚¬آ ط·آ·ط¢آ§ط·آ¸ط¸آ¾ $start - $end ط·آ¸أ¢â‚¬آ¦ط·آ¸أ¢â‚¬آ  $itemCount',
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
                  child: const Text(
                      'ط£آ¢أ¢â€ڑآ¬ط¢آ¹ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ³ط·آ·ط¢آ§ط·آ·ط¢آ¨ط·آ¸أ¢â‚¬ع‘'),
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
                  child: const Text(
                      'ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¹آ¾ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¹ ط£آ¢أ¢â€ڑآ¬ط·â€؛'),
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
                      ? 'ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ³ط·آ·ط¢آ¹ط·آ·ط¢آ± ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ£ط·آ·ط¢آ³ط·آ·ط¢آ§ط·آ·ط¢آ³ط·آ¸ط¸آ¹: ${_money(item.product.price)}'
                      : 'ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ³ط·آ·ط¢آ¹ط·آ·ط¢آ± ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ³ط·آ·ط¢آ§ط·آ·ط¢آ¨ط·آ¸أ¢â‚¬ع‘ ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¹ط·آ¸أ¢â‚¬آ¦ط·آ¸ط¸آ¹ط·آ¸أ¢â‚¬â€چ: ${_money(item.previousCustomerPrice!)}',
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
                      labelText:
                          'ط·آ·ط¢آ³ط·آ·ط¢آ¹ط·آ·ط¢آ± ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¨ط·آ¸ط¸آ¹ط·آ·ط¢آ¹',
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

class _ProductPickerSheet extends StatefulWidget {
  final List<InvoiceLineItemModel> existing;
  final List<ProductModel> products;
  final Map<String, CustomerProductPrice> customerPrices;
  const _ProductPickerSheet({
    required this.existing,
    required this.products,
    required this.customerPrices,
  });

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
        .map((e) => InvoiceLineItemModel(
              product: e.product,
              quantity: e.quantity,
              unitPrice: e.unitPrice,
              previousCustomerPrice: e.previousCustomerPrice,
            ))
        .toList();
  }

  int _quantityFor(InvoiceProductModel p) {
    final match = cart.where((c) => c.product.id == p.id);
    return match.isEmpty ? 0 : match.first.quantity;
  }

  void _setQuantity(InvoiceProductModel p, int qty) {
    setState(() {
      cart.removeWhere((c) => c.product.id == p.id);
      if (qty > 0) {
        final previous = widget.customerPrices[p.id]?.lastPrice;
        cart.add(InvoiceLineItemModel(
          product: p,
          quantity: qty,
          unitPrice: previous ?? p.price,
          previousCustomerPrice: previous,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filtered = widget.products
        .map(_invoiceProductFromInventory)
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return _BottomSheetShell(
      title:
          'ط·آ·ط¢آ¥ط·آ·ط¢آ¶ط·آ·ط¢آ§ط·آ¸ط¸آ¾ط·آ·ط¢آ© ط·آ·ط¢آ£ط·آ·ط¢آµط·آ¸أ¢â‚¬آ ط·آ·ط¢آ§ط·آ¸ط¸آ¾',
      icon: Icons.inventory_2_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: (v) => setState(() => query = v),
            style: TextStyle(color: colors.text),
            decoration: InputDecoration(
              hintText:
                  'ط·آ·ط¢آ§ط·آ·ط¢آ¨ط·آ·ط¢آ­ط·آ·ط¢آ« ط·آ·ط¢آ¹ط·آ¸أ¢â‚¬آ  ط·آ¸أ¢â‚¬آ¦ط·آ¸أ¢â‚¬آ ط·آ·ط¹آ¾ط·آ·ط¢آ¬...',
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
                  opacity: 1,
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
                              ' / ',
                              style: AppTextStyles.almaraiRegular14.copyWith(
                                color: colors.textMuted,
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
                            onTap: () => _setQuantity(p, 1),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 8.h),
                              child: Text(
                                  'ط·آ·ط¢آ¥ط·آ·ط¢آ¶ط·آ·ط¢آ§ط·آ¸ط¸آ¾ط·آ·ط¢آ©',
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
                'ط·آ·ط¹آ¾ط·آ¸أ¢â‚¬آ¦ ط£آ¢أ¢â€ڑآ¬أ¢â‚¬â€Œ ${cart.length} ط·آ·ط¢آµط·آ¸أ¢â‚¬آ ط·آ¸ط¸آ¾',
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
    final isCash = saleType == 'ط·آ¸أ¢â‚¬آ ط·آ¸أ¢â‚¬ع‘ط·آ·ط¢آ¯ط·آ¸ط¸آ¹';

    final String? warning = isCash && (paid - invoiceTotal).abs() > 0.01
        ? 'ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¾ط·آ·ط¢آ§ط·آ·ط¹آ¾ط·آ¸ط«â€ ط·آ·ط¢آ±ط·آ·ط¢آ© ط·آ¸أ¢â‚¬آ ط·آ¸أ¢â‚¬ع‘ط·آ·ط¢آ¯ط·آ¸ط¸آ¹ط·آ·ط¥â€™ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ¸ط¸آ¾ط·آ·ط¢آ±ط·آ¸ط«â€ ط·آ·ط¢آ¶ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ¯ط·آ¸ط¸آ¾ط·آ¸ط«â€ ط·آ·ط¢آ¹ ط·آ¸ط¸آ¹ط·آ·ط¢آ³ط·آ·ط¢آ§ط·آ¸ط«â€ ط·آ¸ط¸آ¹ ط·آ¸أ¢â‚¬ع‘ط·آ¸ط¸آ¹ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ© ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¾ط·آ·ط¢آ§ط·آ·ط¹آ¾ط·آ¸ط«â€ ط·آ·ط¢آ±ط·آ·ط¢آ© (${_money(invoiceTotal)}) ط·آ·ط¢آ¨ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¸ط·آ·ط¢آ¨ط·آ·ط¢آ·'
        : !isCash && paid > totalDue + 0.01
            ? 'ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ¨ط·آ¸أ¢â‚¬â€چط·آ·ط·â€؛ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ¯ط·آ¸ط¸آ¾ط·آ¸ط«â€ ط·آ·ط¢آ¹ ط·آ·ط¢آ£ط·آ¸ط¦â€™ط·آ·ط¢آ¨ط·آ·ط¢آ± ط·آ¸أ¢â‚¬آ¦ط·آ¸أ¢â‚¬آ  ط·آ·ط¢آ¥ط·آ·ط¢آ¬ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¹ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ³ط·آ·ط¹آ¾ط·آ·ط¢آ­ط·آ¸أ¢â‚¬ع‘ ط·آ·ط¢آ¹ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ° ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¹ط·آ¸أ¢â‚¬آ¦ط·آ¸ط¸آ¹ط·آ¸أ¢â‚¬â€چ'
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          icon: Icons.account_balance_wallet_outlined,
          title:
              'ط·آ¸أ¢â‚¬آ¦ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ®ط·آ·ط¢آµ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ­ط·آ·ط¢آ³ط·آ·ط¢آ§ط·آ·ط¢آ¨',
        ),
        SizedBox(height: 12.h),
        _TotalsRow(
            label:
                'ط·آ¸أ¢â‚¬ع‘ط·آ¸ط¸آ¹ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ© ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¾ط·آ·ط¢آ§ط·آ·ط¹آ¾ط·آ¸ط«â€ ط·آ·ط¢آ±ط·آ·ط¢آ© ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ­ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¹ط·آ·ط¢آ©',
            value: _money(invoiceTotal)),
        SizedBox(height: 8.h),
        _TotalsRow(
            label:
                'ط·آ·ط¢آ­ط·آ·ط¢آ³ط·آ·ط¢آ§ط·آ·ط¢آ¨ ط·آ·ط¢آ³ط·آ·ط¢آ§ط·آ·ط¢آ¨ط·آ¸أ¢â‚¬ع‘',
            value: _money(previousBalance)),
        SizedBox(height: 10.h),
        Divider(height: 1, color: colors.border),
        SizedBox(height: 10.h),
        _TotalsRow(
            label:
                'ط·آ·ط¢آ¥ط·آ·ط¢آ¬ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¹ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ³ط·آ·ط¹آ¾ط·آ·ط¢آ­ط·آ¸أ¢â‚¬ع‘ ط·آ·ط¢آ¹ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ° ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¹ط·آ¸أ¢â‚¬آ¦ط·آ¸ط¸آ¹ط·آ¸أ¢â‚¬â€چ',
            value: _money(totalDue)),
        SizedBox(height: 14.h),
        Row(
          children: [
            Text(
                'ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ¯ط·آ¸ط¸آ¾ط·آ¸ط«â€ ط·آ·ط¢آ¹ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¢ط·آ¸أ¢â‚¬آ ',
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: colors.textMuted, fontSize: 12.sp)),
            if (isCash) ...[
              SizedBox(width: 8.w),
              Text(
                  '(ط·آ¸أ¢â‚¬آ ط·آ¸أ¢â‚¬ع‘ط·آ·ط¢آ¯ط·آ¸ط¸آ¹ ط£آ¢أ¢â€ڑآ¬أ¢â‚¬â€Œ ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ§ط·آ·ط¢آ²ط·آ¸أ¢â‚¬آ¦ ط·آ¸ط¸آ¹ط·آ·ط¹آ¾ط·آ·ط¢آ³ط·آ·ط¢آ§ط·آ¸ط«â€ ط·آ¸أ¢â‚¬آ° ط·آ·ط¢آ¨ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¥ط·آ·ط¢آ¬ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¹)',
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
                    child: Text(
                        'ط·آ·ط¹آ¾ط·آ·ط¢آ¹ط·آ·ط¢آ¨ط·آ·ط¢آ¦ط·آ·ط¢آ© ط·آ¸ط¦â€™ط·آ·ط¢آ§ط·آ¸أ¢â‚¬آ¦ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ©',
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
              Text(
                  'ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ·ط¹آ¾ط·آ·ط¢آ¨ط·آ¸أ¢â‚¬ع‘ط·آ¸ط¸آ¹ ط·آ·ط¢آ¹ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ° ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¹ط·آ¸أ¢â‚¬آ¦ط·آ¸ط¸آ¹ط·آ¸أ¢â‚¬â€چ',
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
            icon: Icons.edit_note_rounded,
            title:
                'ط·آ¸أ¢â‚¬آ¦ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ§ط·آ·ط¢آ­ط·آ·ط¢آ¸ط·آ·ط¢آ§ط·آ·ط¹آ¾ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ¸أ¢â‚¬آ ط·آ·ط¢آ¯ط·آ¸ط«â€ ط·آ·ط¢آ¨'),
        SizedBox(height: 10.h),
        TextField(
          controller: controller,
          maxLines: 3,
          style: TextStyle(color: colors.text),
          decoration: InputDecoration(
            hintText:
                'ط¸â€¹ط¹ط›أ¢â‚¬إ“أ¢â‚¬إ’ ط·آ·ط¢آ§ط·آ¸ط¦â€™ط·آ·ط¹آ¾ط·آ·ط¢آ¨ ط·آ¸أ¢â‚¬آ¦ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ§ط·آ·ط¢آ­ط·آ·ط¢آ¸ط·آ·ط¢آ§ط·آ·ط¹آ¾ط·آ¸ط¦â€™ ط·آ·ط¢آ¹ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ° ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ²ط·آ¸ط¸آ¹ط·آ·ط¢آ§ط·آ·ط¢آ±ط·آ·ط¢آ© ط·آ·ط¢آ£ط·آ¸ط«â€  ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¾ط·آ·ط¢آ§ط·آ·ط¹آ¾ط·آ¸ط«â€ ط·آ·ط¢آ±ط·آ·ط¢آ©...',
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
              icon: Icons.insights_rounded,
              title:
                  'ط·آ·ط¹آ¾ط·آ·ط¢آ­ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¹ط·آ¸أ¢â‚¬â€چ ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ´ط·آ·ط¹آ¾ط·آ·ط¢آ±ط·آ¸ط¸آ¹ط·آ·ط¢آ§ط·آ·ط¹آ¾ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¹ط·آ¸أ¢â‚¬آ¦ط·آ¸ط¸آ¹ط·آ¸أ¢â‚¬â€چ'),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (customer.topPurchasedProducts.isNotEmpty)
                Expanded(
                  child: _InsightBadge(
                    title:
                        'ط·آ·ط¢آ£ط·آ¸ط¦â€™ط·آ·ط¢آ«ط·آ·ط¢آ± ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ¸أ¢â‚¬آ ط·آ·ط¹آ¾ط·آ·ط¢آ¬ط·آ·ط¢آ§ط·آ·ط¹آ¾ ط·آ·ط¢آ´ط·آ·ط¢آ±ط·آ·ط¢آ§ط·آ·ط·إ’ط·آ¸أ¢â‚¬آ¹',
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
                    title:
                        'ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ ط·آ¸ط¸آ¹ط·آ·ط¢آ´ط·آ·ط¹آ¾ط·آ·ط¢آ±ط·آ¸أ¢â‚¬طŒط·آ·ط¢آ§ ط·آ¸أ¢â‚¬آ¦ط·آ¸أ¢â‚¬آ ط·آ·ط¢آ° ط·آ¸ط¸آ¾ط·آ·ط¹آ¾ط·آ·ط¢آ±ط·آ·ط¢آ©',
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
                isIssuing
                    ? 'ط·آ·ط¢آ¬ط·آ·ط¢آ§ط·آ·ط¢آ±ط·آ¸ط¸آ¹ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ­ط·آ¸ط¸آ¾ط·آ·ط¢آ¸...'
                    : 'ط·آ·ط¢آ­ط·آ¸ط¸آ¾ط·آ·ط¢آ¸ ط·آ¸ط«â€ ط·آ·ط¢آ¥ط·آ·ط¢آµط·آ·ط¢آ¯ط·آ·ط¢آ§ط·آ·ط¢آ± ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¾ط·آ·ط¢آ§ط·آ·ط¹آ¾ط·آ¸ط«â€ ط·آ·ط¢آ±ط·آ·ط¢آ©',
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

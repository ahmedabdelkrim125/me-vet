# MeVetApp - Task 2 - Customer Specific Pricing

This file contains the Dart source files discovered by searching for
customer-specific pricing, customer_product_prices, invoice pricing,
invoice creation/editing, and Quick Invoice related code.

The AI agent must inspect the actual architecture in these files before
making any changes.



============================================================
FILE: .\lib\core\notifications\notification_navigator.dart
============================================================

import 'package:flutter/material.dart';
import '../di/service_locator.dart';
import '../../features/customer-visits/customers/data/customers_repository.dart';
import '../../features/customer-visits/customers/screens/customer_detail_screen.dart';
import '../../features/inventory/data/products_repository.dart';
import '../../features/inventory/domain/models/product_catalog.dart';
import '../../features/inventory/domain/models/product_model.dart';
import '../../features/inventory/presentation/cubit/vehicle_stock_cubit.dart';
import '../../features/inventory/presentation/widgets/product_detail_sheet.dart';
import '../../features/notification/domain/models/notification_type.dart';
import '../routing/routes.dart';

class NotificationNavigator {
  NotificationNavigator._();

  static final instance = NotificationNavigator._();

  static const int _vehicleStockTabIndex = 2;

  GlobalKey<NavigatorState>? _navigatorKey;
  Map<String, dynamic>? _pendingPayload;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  void setPendingPayload(Map<String, dynamic> payload) {
    _pendingPayload = payload;
  }

  Future<void> consumePending() async {
    if (_pendingPayload == null) return;

    final key = _navigatorKey;
    if (key == null) return;

    if (key.currentContext != null && key.currentContext!.mounted) {
      final payload = _pendingPayload!;
      _pendingPayload = null;
      await navigate(payload, context: key.currentContext!);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_pendingPayload == null) return;
      final ctx = key.currentContext;
      if (ctx == null || !ctx.mounted) return;
      final payload = _pendingPayload!;
      _pendingPayload = null;
      await navigate(payload, context: ctx);
    });
  }

  Future<void> navigate(
    Map<String, dynamic> payload, {
    BuildContext? context,
  }) async {
    final typeStr = payload['type']?.toString();
    final relatedId = payload['related_id']?.toString();

    if (typeStr == null || typeStr.isEmpty) {
      debugPrint('[NotificationNavigator] type is null or empty');
      return;
    }

    final type = notificationTypeFromDb(typeStr);

    final targetContext = context ?? _navigatorKey?.currentContext;
    if (targetContext == null || !targetContext.mounted) {
      debugPrint('[NotificationNavigator] no valid context available');
      return;
    }

    switch (type) {
      case NotificationType.visitReminder:
      case NotificationType.customerStalled:
      case NotificationType.customerDebt:
      case NotificationType.creditLimitWarning:
      case NotificationType.creditLimitExceeded:
        await _navigateToCustomer(targetContext, relatedId);
        break;

      case NotificationType.mainStockLow:
      case NotificationType.productExpiringSoon:
      case NotificationType.productExpired:
        await _navigateToProduct(targetContext, relatedId);
        break;

      case NotificationType.vehicleStockLow:
        await _navigateToVehicleStock(targetContext, relatedId);
        break;

      case NotificationType.dailyReportReminder:
        debugPrint(
            '[NotificationNavigator] dailyReportReminder: no navigation');
        break;

      case NotificationType.unknown:
        debugPrint(
            '[NotificationNavigator] unknown notification type: no navigation');
        break;
    }
  }

  Future<void> _navigateToCustomer(
    BuildContext context,
    String? customerId,
  ) async {
    if (customerId == null || customerId.isEmpty) {
      debugPrint('[NotificationNavigator] customerId is null or empty');
      return;
    }

    final customer =
        await CustomersRepository.instance.fetchCustomerById(customerId);
    if (customer == null) {
      debugPrint('[NotificationNavigator] customer not found: $customerId');
      return;
    }

    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(customer: customer),
      ),
    );
  }

  Future<void> _navigateToProduct(
    BuildContext context,
    String? productId,
  ) async {
    if (productId == null || productId.isEmpty) {
      debugPrint('[NotificationNavigator] productId is null or empty');
      return;
    }

    ProductModel? product;
    try {
      product = await ProductsRepository.instance.getProductById(productId);
    } catch (e) {
      debugPrint('[NotificationNavigator] getProductById error: $e');
      return;
    }

    if (product == null) {
      debugPrint('[NotificationNavigator] product not found: $productId');
      return;
    }

    if (!context.mounted) return;

    ProductCatalog catalog = ProductCatalog.empty;
    try {
      final results = await Future.wait([
        ProductsRepository.instance.getCategories(),
        ProductsRepository.instance.getUnits(),
      ]);
      catalog = ProductCatalog(categories: results[0], units: results[1]);
    } catch (e) {
      debugPrint('[NotificationNavigator] catalog load error: $e');
    }

    if (!context.mounted) return;

    await showProductDetailSheet(context, product, catalog: catalog);
  }

  Future<void> _navigateToVehicleStock(
    BuildContext context,
    String? relatedId,
  ) async {
    if (relatedId == null || relatedId.isEmpty) {
      debugPrint(
          '[NotificationNavigator] vehicle_stock_low: relatedId is null');
      return;
    }

    final parts = relatedId.split(':');
    if (parts.length != 2) {
      debugPrint(
          '[NotificationNavigator] vehicle_stock_low: malformed relatedId: $relatedId');
      return;
    }

    final vehicleId = parts[0];
    final productId = parts[1];

    if (vehicleId.isEmpty || productId.isEmpty) {
      debugPrint(
          '[NotificationNavigator] vehicle_stock_low: empty vehicleId or productId');
      return;
    }

    if (!context.mounted) return;

    try {
      final cubit = sl<VehicleStockCubit>();
      await cubit.loadVehicles();

      final vehicleExists = cubit.state.vehicles.any((v) => v.id == vehicleId);
      if (!vehicleExists) {
        debugPrint(
            '[NotificationNavigator] vehicle_stock_low: vehicle not found: $vehicleId');
        return;
      }

      cubit.selectVehicle(vehicleId);

      if (!context.mounted) return;

      await Navigator.of(context).pushNamed(
        Routes.mainScreen,
        arguments: _vehicleStockTabIndex,
      );
    } catch (e) {
      debugPrint(
          '[NotificationNavigator] vehicle_stock_low navigation error: $e');
    }
  }
}



============================================================
FILE: .\lib\features\customer_account\presentation\screens\customer_account_screen.dart
============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/di/service_locator.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer-visits/customers/data/customers_repository.dart';
import 'package:mivet_app/features/home/domain/models/quick_invoice_models.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice_dialog.dart';
import '../../presentation/cubit/customer_account_cubit.dart';
import '../../presentation/cubit/customer_account_state.dart';
import '../widgets/account_summary_card.dart';
import '../widgets/collection_receipt_preview.dart';
import '../widgets/payment_dialog.dart';
import '../widgets/transaction_list.dart';
import 'sales_return_screen.dart';

class CustomerAccountScreen extends StatelessWidget {
  final String customerId;
  final String customerName;
  final double? fallbackBalance;

  const CustomerAccountScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    this.fallbackBalance,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CustomerAccountCubit>()
        ..init(
          customerId: customerId,
          customerName: customerName,
          fallbackBalance: fallbackBalance,
        ),
      child: const _CustomerAccountView(),
    );
  }
}

class _CustomerAccountView extends StatelessWidget {
  const _CustomerAccountView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: BlocConsumer<CustomerAccountCubit, CustomerAccountState>(
          listenWhen: (p, c) =>
              p.actionStatus != c.actionStatus ||
              p.ledgerError != c.ledgerError,
          listener: (context, state) {
            final cubit = context.read<CustomerAccountCubit>();

            if (state.ledgerError != null) {
              showAppError(context, state.ledgerError!);
              cubit.acknowledgeLedgerError();
            } else if (state.actionStatus ==
                    CustomerAccountActionStatus.success &&
                state.actionSuccessMessage != null) {
              showAppSuccess(context, state.actionSuccessMessage!);
              cubit.acknowledgeAction();
            } else if (state.actionStatus ==
                    CustomerAccountActionStatus.failure &&
                state.actionError != null) {
              showAppError(context, state.actionError!);
              cubit.acknowledgeAction();
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                _Header(customerName: state.customerName),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        context.read<CustomerAccountCubit>().refresh(),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 30.h),
                      children: [
                        AccountSummaryCard(
                          customerName: state.customerName,
                          balance: state.balance,
                        ),
                        SizedBox(height: 14.h),
                        _ActionsBar(
                          customerId: state.customerId,
                          customerName: state.customerName,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'ط­ط±ظƒط© ط§ظ„ط­ط³ط§ط¨',
                          style: AppTextStyles.cairoMedium16.copyWith(
                            color: colors.text,
                            fontSize: 13.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TransactionList(
                          transactions: state.ledger?.transactions ?? const [],
                          isLoading: state.isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String customerName;

  const _Header({required this.customerName});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: colors.surface,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 16.w, 16.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_forward,
              color: colors.primary,
              size: 22.sp,
            ),
          ),
          Expanded(
            child: Text(
              'ط§ظ„ط­ط³ط§ط¨ ظˆط§ظ„ظ…ط¹ط§ظ…ظ„ط§طھ â€” $customerName',
              style: AppTextStyles.cairoBold18.copyWith(
                color: colors.primary,
                fontSize: 15.sp,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsBar extends StatelessWidget {
  final String customerId;
  final String customerName;

  const _ActionsBar({
    required this.customerId,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomerAccountCubit>();

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _collect(context, cubit),
            child: const Text('طھط­طµظٹظ„'),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: SalesReturnScreen(
                        customerId: customerId,
                        customerName: customerName,
                      ),
                    ),
                  ),
                )
                .then((_) => cubit.refresh()),
            child: const Text('ظ…ط±طھط¬ط¹ ظ…ط¨ظٹط¹ط§طھ'),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _openNewInvoice(context),
            child: const Text('ظپط§طھظˆط±ط© ط¬ط¯ظٹط¯ط©'),
          ),
        ),
      ],
    );
  }

  Future<void> _collect(
    BuildContext context,
    CustomerAccountCubit cubit,
  ) async {
    await showPaymentDialog(context);
    if (!context.mounted) return;

    final state = cubit.state;

    if (state.receipt != null) {
      await showCollectionReceiptPreview(context, state.receipt!);
      cubit.acknowledgeReceipt();
    } else if (state.receiptError != null) {
      if (context.mounted) showAppError(context, state.receiptError!);
      cubit.acknowledgeReceipt();
    }
  }

  Future<void> _openNewInvoice(BuildContext context) async {
    try {
      final repository = CustomersRepository.instance;
      await repository.initialize();
      final customer = repository.getCustomerById(customerId);
      if (customer == null || !context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuickInvoiceDialog(
            initialCustomer: InvoiceCustomerModel(customer: customer),
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) showAppError(context, error);
    }
  }
}



============================================================
FILE: .\lib\features\customer_account\presentation\screens\sales_return_screen.dart
============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/core/di/service_locator.dart';
import 'package:mivet_app/features/customer-visits/customers/data/invoices_repository.dart';
import 'package:mivet_app/features/customer-visits/customers/domain/models/invoice_record_model.dart';
import 'package:mivet_app/features/inventory/presentation/cubit/vehicle_stock_cubit.dart';

import '../../domain/entities/sales_return.dart';
import '../cubit/customer_account_cubit.dart';
import '../cubit/customer_account_state.dart';
import '../widgets/return_item_selector.dart';
import '../widgets/return_summary.dart';

class SalesReturnScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const SalesReturnScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends State<SalesReturnScreen> {
  List<InvoiceRecordModel>? _invoices;
  InvoiceFullDetail? _selectedInvoice;
  bool _loadingInvoices = true;
  bool _loadingDetail = false;
  final Map<String, int> _selectedQuantities = {};
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    try {
      final invoices = await InvoicesRepository.instance
          .getInvoicesForCustomer(widget.customerId);
      if (!mounted) return;
      setState(() {
        _invoices = invoices;
        _loadingInvoices = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingInvoices = false);
      showAppError(context, e);
    }
  }

  Future<void> _selectInvoice(InvoiceRecordModel invoice) async {
    setState(() => _loadingDetail = true);
    try {
      final detail = await InvoicesRepository.instance
          .getInvoiceDetailByCode(invoice.code);
      if (!mounted) return;

      await context
          .read<CustomerAccountCubit>()
          .fetchReturnedQuantities(detail.id);

      if (!mounted) return;
      setState(() {
        _selectedInvoice = detail;
        _loadingDetail = false;
        _selectedQuantities.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDetail = false);
      showAppError(context, e);
    }
  }

  double get _returnTotal {
    final invoice = _selectedInvoice;
    if (invoice == null) return 0;
    var total = 0.0;
    for (final item in invoice.items) {
      final qty = _selectedQuantities[item.id] ?? 0;
      if (qty > 0) total += item.unitPrice * qty;
    }

    if (invoice.discountPercent > 0) {
      total = total * (1 - (invoice.discountPercent / 100));
    }
    return total;
  }

  void _submit() {
    final invoice = _selectedInvoice;
    if (invoice == null) return;
    final items = _selectedQuantities.entries
        .where((e) => e.value > 0)
        .map((e) =>
            SalesReturnItemInput(invoiceItemId: e.key, quantity: e.value))
        .toList();
    if (items.isEmpty) return;
    context.read<CustomerAccountCubit>().submitSalesReturn(
          invoiceId: invoice.id,
          items: items,
          reason: _reasonController.text.trim().isEmpty
              ? 'ظ…ط±طھط¬ط¹ ظ…ظ† ط§ظ„ط¹ظ…ظٹظ„'
              : _reasonController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('ظ…ط±طھط¬ط¹ ظ…ط¨ظٹط¹ط§طھ'),
        backgroundColor: colors.surface,
        foregroundColor: colors.primary,
      ),
      body: BlocConsumer<CustomerAccountCubit, CustomerAccountState>(
        listenWhen: (p, c) => p.actionStatus != c.actionStatus,
        listener: (context, state) {
          final cubit = context.read<CustomerAccountCubit>();
          if (state.actionStatus == CustomerAccountActionStatus.success) {
            showAppSuccess(context, state.actionSuccessMessage ?? 'طھظ… ط§ظ„ط­ظپط¸');
            cubit.acknowledgeAction();
            try {
              sl<VehicleStockCubit>().refresh();
            } catch (_) {}
            Navigator.of(context).pop();
          } else if (state.actionStatus ==
                  CustomerAccountActionStatus.failure &&
              state.actionError != null) {
            showAppError(context, state.actionError!);
            cubit.acknowledgeAction();
          }
        },
        builder: (context, state) {
          final isSubmitting =
              state.actionStatus == CustomerAccountActionStatus.submitting;
          if (_selectedInvoice == null) {
            return _InvoicePicker(
              invoices: _invoices,
              isLoading: _loadingInvoices || _loadingDetail,
              onSelect: _selectInvoice,
            );
          }

          final returnedQs = state.returnedQuantities ?? {};

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'ظپط§طھظˆط±ط© ${_selectedInvoice!.code}',
                            style: AppTextStyles.cairoMedium16
                                .copyWith(color: colors.text, fontSize: 13.sp),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _selectedInvoice = null),
                          child: const Text('طھط؛ظٹظٹط± ط§ظ„ظپط§طھظˆط±ط©'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    for (final item in _selectedInvoice!.items)
                      ReturnItemSelector(
                        item: item,
                        quantity: _selectedQuantities[item.id] ?? 0,
                        returnedQuantity: returnedQs[item.id] ?? 0,
                        onChanged: (qty) =>
                            setState(() => _selectedQuantities[item.id] = qty),
                      ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: _reasonController,
                      decoration:
                          const InputDecoration(labelText: 'ط³ط¨ط¨ ط§ظ„ط¥ط±ط¬ط§ط¹'),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration:
                          const InputDecoration(labelText: 'ظ…ظ„ط§ط­ط¸ط§طھ (ط§ط®طھظٹط§ط±ظٹ)'),
                    ),
                    SizedBox(height: 12.h),
                    ReturnSummary(total: _returnTotal),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.w),
                child: ElevatedButton(
                  onPressed: isSubmitting || _returnTotal <= 0 ? null : _submit,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('طھط£ظƒظٹط¯ ط§ظ„ظ…ط±طھط¬ط¹'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InvoicePicker extends StatelessWidget {
  final List<InvoiceRecordModel>? invoices;
  final bool isLoading;
  final ValueChanged<InvoiceRecordModel> onSelect;

  const _InvoicePicker({
    required this.invoices,
    required this.isLoading,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final list = invoices ?? const [];
    if (list.isEmpty) {
      return Center(
        child: Text('ظ„ط§ طھظˆط¬ط¯ ظپظˆط§طھظٹط± ظ„ظ‡ط°ط§ ط§ظ„ط¹ظ…ظٹظ„',
            style: AppTextStyles.almaraiRegular14
                .copyWith(color: colors.textMuted)),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final invoice = list[index];
        return Card(
          child: ListTile(
            title: Text(invoice.code),
            subtitle: Text(
              '${invoice.date.year}/${invoice.date.month.toString().padLeft(2, '0')}/${invoice.date.day.toString().padLeft(2, '0')} â€” ${invoice.amount.toStringAsFixed(0)} ط¬.ظ…',
            ),
            trailing: Text(invoice.status.label),
            onTap: () => onSelect(invoice),
          ),
        );
      },
    );
  }
}



============================================================
FILE: .\lib\features\customer_account\presentation\widgets\return_item_selector.dart
============================================================

// import 'package:flutter/material.dart';
// import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
// import 'package:mivet_app/core/theme/app_text_styles.dart';
// import 'package:mivet_app/core/utils/responsive_extension.dart';
// import 'package:mivet_app/features/customer-visits/customers/data/invoices_repository.dart';

// /// The quantity stepper is capped at the invoice line's original quantity.
// /// The backend also enforces the true remaining-returnable quantity
// /// (original minus previous returns) inside `create_sales_return` â€” that
// /// number isn't exposed by any verified RPC, so Flutter cannot pre-filter
// /// against it and relies on the server rejecting an over-return.
// class ReturnItemSelector extends StatelessWidget {
//   final InvoiceItemRow item;
//   final int quantity;
//   final ValueChanged<int> onChanged;

//   const ReturnItemSelector({
//     super.key,
//     required this.item,
//     required this.quantity,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;
//     return Container(
//       margin: EdgeInsets.only(bottom: 8.h),
//       padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(12.r),
//         border: Border.all(color: colors.border),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(item.productName,
//                     style: AppTextStyles.cairoMedium16
//                         .copyWith(color: colors.text, fontSize: 12.sp)),
//                 Text(
//                   'ط§ظ„ظƒظ…ظٹط© ط§ظ„ط£طµظ„ظٹط©: ${item.quantity} â€” ط§ظ„ط³ط¹ط±: ${item.unitPrice.toStringAsFixed(0)} ط¬.ظ…',
//                   style: AppTextStyles.almaraiRegular14
//                       .copyWith(color: colors.textMuted, fontSize: 10.sp),
//                 ),
//               ],
//             ),
//           ),
//           IconButton(
//             onPressed: quantity > 0 ? () => onChanged(quantity - 1) : null,
//             icon: const Icon(Icons.remove_circle_outline),
//           ),
//           Text('$quantity',
//               style: AppTextStyles.cairoMedium16
//                   .copyWith(color: colors.text, fontSize: 13.sp)),
//           IconButton(
//             onPressed:
//                 quantity < item.quantity ? () => onChanged(quantity + 1) : null,
//             icon: const Icon(Icons.add_circle_outline),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer-visits/customers/data/invoices_repository.dart';

class ReturnItemSelector extends StatelessWidget {
  final InvoiceItemRow item;
  final int quantity;
  final int returnedQuantity;
  final ValueChanged<int> onChanged;

  const ReturnItemSelector({
    super.key,
    required this.item,
    required this.quantity,
    required this.returnedQuantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final remainingQuantity = item.quantity - returnedQuantity;
    final isFullyReturned = remainingQuantity <= 0;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color:
            isFullyReturned ? colors.surface.withOpacity(0.6) : colors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
            color: isFullyReturned
                ? colors.border.withOpacity(0.5)
                : colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTextStyles.cairoMedium16.copyWith(
                      color: isFullyReturned ? colors.textMuted : colors.text,
                      fontSize: 12.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  'ط§ظ„ظ…ط¨ط§ط¹: ${item.quantity} â€” ط§ظ„ط³ط¹ط±: ${item.unitPrice.toStringAsFixed(0)} ط¬.ظ…',
                  style: AppTextStyles.almaraiRegular14
                      .copyWith(color: colors.textMuted, fontSize: 10.sp),
                ),
                Text(
                  'ظ…ط±طھط¬ط¹ ط³ط§ط¨ظ‚ط§ظ‹: $returnedQuantity â€” ط§ظ„ظ…طھط§ط­: $remainingQuantity',
                  style: AppTextStyles.almaraiRegular14.copyWith(
                      color: remainingQuantity > 0
                          ? colors.primary
                          : AppColors.statusNotReached,
                      fontSize: 10.sp),
                ),
                if (isFullyReturned)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      'طھظ… ط¥ط±ط¬ط§ط¹ ظ‡ط°ط§ ط§ظ„ظ…ظ†طھط¬ ط¨ط§ظ„ظƒط§ظ…ظ„',
                      style: AppTextStyles.almaraiRegular14.copyWith(
                          color: AppColors.statusNotReached, fontSize: 10.sp),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: (!isFullyReturned && quantity > 0)
                ? () => onChanged(quantity - 1)
                : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            '$quantity',
            style: AppTextStyles.cairoMedium16.copyWith(
                color: isFullyReturned ? colors.textMuted : colors.text,
                fontSize: 13.sp),
          ),
          IconButton(
            onPressed: (!isFullyReturned && quantity < remainingQuantity)
                ? () => onChanged(quantity + 1)
                : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}



============================================================
FILE: .\lib\features\customer-visits\customers\data\invoices_repository.dart
============================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../customer_account/domain/entities/payment_method.dart';
import '../domain/models/invoice_line_input.dart';
import '../domain/models/invoice_record_model.dart';
import '../../../invoices/domain/invoice_draft.dart';

class InvoiceItemRow {
  final String id;
  final String? productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  const InvoiceItemRow({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });
}

class InvoiceFullDetail {
  final String id;
  final String code;
  final String customerId;
  final DateTime date;
  final double subtotal;
  final double discountPercent;
  final double totalAmount;
  final double paidNow;
  final String saleType;
  final String statusLabel;
  final String? notes;
  final List<InvoiceItemRow> items;

  const InvoiceFullDetail({
    required this.id,
    required this.code,
    required this.customerId,
    required this.date,
    required this.subtotal,
    required this.discountPercent,
    required this.totalAmount,
    required this.paidNow,
    required this.saleType,
    required this.statusLabel,
    required this.notes,
    required this.items,
  });

  double get remaining => totalAmount - paidNow;
}

class ProductPurchaseStat {
  final String productId;
  final String productName;
  final double lastPrice;
  final DateTime lastPurchaseDate;
  final int timesPurchased;
  final bool isDeleted;

  const ProductPurchaseStat({
    required this.productId,
    required this.productName,
    required this.lastPrice,
    required this.lastPurchaseDate,
    required this.timesPurchased,
    this.isDeleted = false,
  });
}

class InvoicesRepository {
  InvoicesRepository._internal();

  static final InvoicesRepository instance = InvoicesRepository._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<Map<String, CustomerProductPrice>> getCustomerProductPrices(
    String customerId,
  ) async {
    final rows = await _supabase.rpc(
      'get_customer_product_prices',
      params: {
        'p_customer_id': customerId,
      },
    );

    return {
      for (final row in (rows as List))
        (row as Map<String, dynamic>)['product_id'] as String:
            CustomerProductPrice.fromJson(row),
    };
  }

  Future<InvoiceRecordModel> issueInvoice({
    required String customerId,
    required List<InvoiceLineInput> items,
    required double discountPercent,
    required bool isCashSale,
    required double paidNow,
    PaymentMethod? paymentMethod,
    String? notes,
  }) async {
    final row = await _supabase.rpc(
      'issue_invoice_v2',
      params: {
        'p_customer_id': customerId,
        'p_items': items.map((item) => item.toRpcJson()).toList(),
        'p_discount_percent': discountPercent,
        'p_sale_type': isCashSale ? 'cash' : 'credit',
        'p_paid_now': paidNow,
        'p_payment_method': paymentMethod?.backendValue,
        'p_notes': notes,
      },
    );

    return InvoiceRecordModel.fromSupabaseRow(
      row as Map<String, dynamic>,
    );
  }

  Future<void> editInvoice({
    required String invoiceId,
    required List<InvoiceItemDraft> items,
    required double discountPercent,
    required String reason,
    String? notes,
  }) async {
    await _supabase.rpc(
      'edit_invoice',
      params: {
        'p_invoice_id': invoiceId,
        'p_items': items.map((item) => item.toRpcJson()).toList(),
        'p_discount_percent': discountPercent,
        'p_notes': notes,
        'p_reason': reason,
      },
    );
  }

  Future<List<InvoiceRecordModel>> getInvoicesForCustomer(
    String customerId, {
    DateTime? since,
  }) async {
    var query =
        _supabase.from('invoices').select().eq('customer_id', customerId);

    if (since != null) {
      query = query.gte('invoice_date', since.toIso8601String());
    }

    final rows = await query.order(
      'invoice_date',
      ascending: false,
    );

    return (rows as List)
        .map(
          (row) => InvoiceRecordModel.fromSupabaseRow(
            row as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<List<InvoiceRecordModel>> getInvoicesInRange(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _supabase
        .from('invoices')
        .select()
        .gte('invoice_date', start.toIso8601String())
        .lt('invoice_date', end.toIso8601String())
        .order(
          'invoice_date',
          ascending: false,
        );

    return (rows as List)
        .map(
          (row) => InvoiceRecordModel.fromSupabaseRow(
            row as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<InvoiceFullDetail> getInvoiceDetailByCode(
    String code,
  ) async {
    final invoice =
        await _supabase.from('invoices').select().eq('code', code).single();

    final invoiceId = invoice['id'] as String;

    final itemRows = await _supabase
        .from('invoice_items')
        .select(
          'id, product_id, product_name, unit_price, quantity, line_total',
        )
        .eq('invoice_id', invoiceId);

    final items = (itemRows as List).map((row) {
      final item = row as Map<String, dynamic>;

      return InvoiceItemRow(
        id: item['id'] as String,
        productId: item['product_id'] as String?,
        productName: item['product_name'] as String? ?? '',
        unitPrice: (item['unit_price'] as num).toDouble(),
        quantity: (item['quantity'] as num).toInt(),
        lineTotal: (item['line_total'] as num).toDouble(),
      );
    }).toList();

    return InvoiceFullDetail(
      id: invoiceId,
      code: invoice['code'] as String,
      customerId: invoice['customer_id'] as String,
      date: DateTime.parse(invoice['invoice_date'] as String),
      subtotal: (invoice['subtotal'] as num).toDouble(),
      discountPercent: (invoice['discount_percent'] as num).toDouble(),
      totalAmount: (invoice['total_amount'] as num).toDouble(),
      paidNow: (invoice['paid_now'] as num).toDouble(),
      saleType: invoice['sale_type'] == 'cash' ? 'ظ†ظ‚ط¯ظٹ' : 'ط¢ط¬ظ„',
      statusLabel: _statusLabelFromDb(
        invoice['status'] as String?,
      ),
      notes: invoice['notes'] as String?,
      items: items,
    );
  }

  String _statusLabelFromDb(String? value) {
    switch (value) {
      case 'paid':
        return 'ظ…ط¯ظپظˆط¹ط©';
      case 'partial':
        return 'ط¬ط²ط¦ظٹ';
      default:
        return 'ط¢ط¬ظ„ط©';
    }
  }

  Future<List<ProductPurchaseStat>> getProductStatsForCustomer(
    String customerId,
  ) async {
    final rows = await _supabase
        .from('invoice_items')
        .select('product_id, product_name, unit_price, quantity, '
            'invoices!inner(id, customer_id, invoice_date), '
            'products(deleted_at)')
        .eq('invoices.customer_id', customerId);

    final byProduct = <String, List<Map<String, dynamic>>>{};
    final deletedProducts = <String>{};

    for (final row in rows as List) {
      final map = row as Map<String, dynamic>;
      final productId = map['product_id'] as String?;

      if (productId == null || productId.trim().isEmpty) {
        continue;
      }

      byProduct.putIfAbsent(productId, () => []).add(map);

      final productData = map['products'];
      if (productData is Map && productData['deleted_at'] != null) {
        deletedProducts.add(productId);
      }
    }

    final stats = <ProductPurchaseStat>[];

    byProduct.forEach((productId, items) {
      items.sort((a, b) {
        final da = DateTime.parse(
          (a['invoices'] as Map<String, dynamic>)['invoice_date'] as String,
        );
        final db = DateTime.parse(
          (b['invoices'] as Map<String, dynamic>)['invoice_date'] as String,
        );

        return db.compareTo(da);
      });

      final latest = items.first;

      final lastDate = DateTime.parse(
        (latest['invoices'] as Map<String, dynamic>)['invoice_date'] as String,
      );

      final distinctInvoiceIds = items
          .map((item) =>
              (item['invoices'] as Map<String, dynamic>)['id'] as String)
          .toSet();

      final productName = latest['product_name'] as String? ?? '';

      stats.add(
        ProductPurchaseStat(
          productId: productId,
          productName: productName,
          lastPrice: (latest['unit_price'] as num).toDouble(),
          lastPurchaseDate: lastDate,
          timesPurchased: distinctInvoiceIds.length,
          isDeleted: deletedProducts.contains(productId),
        ),
      );
    });

    return stats;
  }
}



============================================================
FILE: .\lib\features\customer-visits\customers\domain\models\customer_detail_model.dart
============================================================

import 'customer_model.dart';

class ProductPurchaseModel {
  final String name;
  final double price;
  final DateTime lastPurchaseDate;

  const ProductPurchaseModel({
    required this.name,
    required this.price,
    required this.lastPurchaseDate,
  });
}

class InvoiceSummaryModel {
  final String code;
  final DateTime date;
  final double amount;
  final String status;

  const InvoiceSummaryModel({
    required this.code,
    required this.date,
    required this.amount,
    required this.status,
  });
}

class CustomerDetailModel {
  final CustomerModel customer;
  final double currentBalance;
  final DateTime? lastCollectionDate;
  final double averageOrder;
  final List<ProductPurchaseModel> topProducts;
  final List<ProductPurchaseModel> notBoughtRecently;
  final List<String> seasonalSuggestions;
  final String notes;
  final List<InvoiceSummaryModel> invoices;

  const CustomerDetailModel({
    required this.customer,
    required this.currentBalance,
    required this.lastCollectionDate,
    required this.averageOrder,
    required this.topProducts,
    required this.notBoughtRecently,
    required this.seasonalSuggestions,
    required this.notes,
    required this.invoices,
  });

  factory CustomerDetailModel.mock(CustomerModel customer) {
    return CustomerDetailModel(
      customer: customer,
      currentBalance: customer.currentBalance,
      lastCollectionDate: customer.lastCollectionDate,
      averageOrder: 0,
      topProducts: const [],
      notBoughtRecently: const [],
      seasonalSuggestions: const [],
      notes: customer.notes,
      invoices: const [],
    );
  }
}



============================================================
FILE: .\lib\features\customer-visits\customers\domain\models\invoice_line_input.dart
============================================================

class InvoiceLineInput {
  final String? productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  const InvoiceLineInput({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  Map<String, dynamic> toRpcJson() => {
        if (productId != null) 'product_id': productId,
        'product_name': productName,
        'unit_price': unitPrice,
        'quantity': quantity,
      };
}



============================================================
FILE: .\lib\features\customer-visits\customers\domain\models\product_purchase_model.dart
============================================================

class ProductPurchaseModel {
  final String name;
  final double customerPrice;
  final DateTime lastPurchaseDate;

  const ProductPurchaseModel({
    required this.name,
    required this.customerPrice,
    required this.lastPurchaseDate,
  });
}



============================================================
FILE: .\lib\features\customer-visits\customers\presentation\cubit\customer_analysis_cubit.dart
============================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/invoices_repository.dart';
import '../../domain/models/customer_detail_model.dart';
import '../../domain/models/invoice_record_model.dart';
import 'customer_analysis_state.dart';

class CustomerAnalysisCubit extends Cubit<CustomerAnalysisState> {
  CustomerAnalysisCubit(this._customerId)
      : super(const CustomerAnalysisState());

  final String _customerId;

  static const int _notBoughtThresholdDays = 14;

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true));
    try {
      final stats = await InvoicesRepository.instance
          .getProductStatsForCustomer(_customerId);
      final invoices = await InvoicesRepository.instance
          .getInvoicesForCustomer(_customerId, since: _sixMonthsAgo());
      final allInvoices =
          await InvoicesRepository.instance.getInvoicesForCustomer(_customerId);

      final now = DateTime.now();

      final activeStats = stats.where((s) => !s.isDeleted).toList();

      final sorted = [...activeStats]
        ..sort((a, b) => b.timesPurchased.compareTo(a.timesPurchased));

      final top = sorted
          .take(5)
          .map((s) => ProductPurchaseModel(
                name: s.productName,
                price: s.lastPrice,
                lastPurchaseDate: s.lastPurchaseDate,
              ))
          .toList();

      final notBought = activeStats
          .where((s) =>
              now.difference(s.lastPurchaseDate).inDays >=
              _notBoughtThresholdDays)
          .toList()
        ..sort((a, b) => a.lastPurchaseDate.compareTo(b.lastPurchaseDate));

      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        topProducts: top,
        notBoughtRecently: notBought
            .map((s) => ProductPurchaseModel(
                  name: s.productName,
                  price: s.lastPrice,
                  lastPurchaseDate: s.lastPurchaseDate,
                ))
            .toList(),
        recentInvoices: invoices.map(_toSummary).toList(),
        allInvoices: allInvoices.map(_toSummary).toList(),
      ));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false));
    }
  }

  DateTime _sixMonthsAgo() {
    final now = DateTime.now();
    return DateTime(now.year, now.month - 6, now.day);
  }

  InvoiceSummaryModel _toSummary(InvoiceRecordModel invoice) {
    return InvoiceSummaryModel(
      code: invoice.code,
      date: invoice.date,
      amount: invoice.amount,
      status: invoice.status.label,
    );
  }
}



============================================================
FILE: .\lib\features\customer-visits\customers\presentation\cubit\customer_analysis_state.dart
============================================================

import 'package:equatable/equatable.dart';

import '../../domain/models/customer_detail_model.dart';

class CustomerAnalysisState extends Equatable {
  final bool isLoading;
  final List<ProductPurchaseModel> topProducts;
  final List<ProductPurchaseModel> notBoughtRecently;
  final List<InvoiceSummaryModel> recentInvoices;
  final List<InvoiceSummaryModel> allInvoices;

  const CustomerAnalysisState({
    this.isLoading = true,
    this.topProducts = const [],
    this.notBoughtRecently = const [],
    this.recentInvoices = const [],
    this.allInvoices = const [],
  });

  CustomerAnalysisState copyWith({
    bool? isLoading,
    List<ProductPurchaseModel>? topProducts,
    List<ProductPurchaseModel>? notBoughtRecently,
    List<InvoiceSummaryModel>? recentInvoices,
    List<InvoiceSummaryModel>? allInvoices,
  }) {
    return CustomerAnalysisState(
      isLoading: isLoading ?? this.isLoading,
      topProducts: topProducts ?? this.topProducts,
      notBoughtRecently: notBoughtRecently ?? this.notBoughtRecently,
      recentInvoices: recentInvoices ?? this.recentInvoices,
      allInvoices: allInvoices ?? this.allInvoices,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, topProducts, notBoughtRecently, recentInvoices, allInvoices];
}



============================================================
FILE: .\lib\features\customer-visits\customers\presentation\screens\customer_detail_screen.dart
============================================================

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:mivet_app/core/utils/responsive_extension.dart';
// import '../../../customer_account/presentation/screens/customer_account_screen.dart';
// import '../../../home/domain/models/quick_invoice_models.dart';
// import '../../../home/presentation/widgets/quick_invoice_dialog.dart';

// class CustomerDetailScreen extends StatelessWidget {
//   final CustomerModel customer;

//   const CustomerDetailScreen({super.key, required this.customer});

//   InvoiceCustomerModel _toInvoiceCustomer(
//     CustomerDetailModel detail,
//     CustomerAnalysisState analysis,
//   ) {
//     return InvoiceCustomerModel(
//       customer: detail.customer,
//       topPurchasedProducts: analysis.topProducts.map((p) => p.name).toList(),
//       notPurchasedRecently:
//           analysis.notBoughtRecently.map((p) => p.name).toList(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => CustomerAnalysisCubit(customer.id)..load(),
//       child: ValueListenableBuilder<List<CustomerModel>>(
//         valueListenable: CustomersRepository.instance.customersNotifier,
//         builder: (context, _, __) {
//           final currentCustomer =
//               CustomersRepository.instance.getCustomerById(customer.id) ??
//                   customer;
//           final detail = CustomerDetailModel.mock(currentCustomer);

//           return BlocBuilder<CustomerAnalysisCubit, CustomerAnalysisState>(
//             builder: (context, analysis) {
//               return Scaffold(
//                 body: SafeArea(
//                   child: Column(
//                     children: [
//                       CustomerDetailHeader(customer: currentCustomer),
//                       Expanded(
//                         child: ListView(
//                           padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 30.h),
//                           children: [
//                             CustomerQuickActionsBar(
//                               customer: currentCustomer,
//                               onInvoiceTap: () {
//                                 final cubit =
//                                     context.read<CustomerAnalysisCubit>();
//                                 Navigator.of(context)
//                                     .push(
//                                       MaterialPageRoute(
//                                         builder: (_) => QuickInvoiceDialog(
//                                           initialCustomer: _toInvoiceCustomer(
//                                               detail, analysis),
//                                         ),
//                                       ),
//                                     )
//                                     .then((_) => cubit.load());
//                               },
//                               // Was: showCustomerCollectPaymentSheet(context, detail: detail).
//                               // The old collection-only sheet is replaced by the full
//                               // customer financial account (invoices, payments, returns,
//                               // running balance). NOTE: the "ط§ظ„طھط­طµظٹظ„" button label lives
//                               // inside CustomerQuickActionsBar (not provided to us) â€” its
//                               // text should be updated there to "ط§ظ„ط­ط³ط§ط¨ ظˆط§ظ„ظ…ط¹ط§ظ…ظ„ط§طھ" or similar.
//                               onCollectTap: () {
//                                 final cubit =
//                                     context.read<CustomerAnalysisCubit>();
//                                 Navigator.of(context)
//                                     .push(
//                                       MaterialPageRoute(
//                                         builder: (_) => CustomerAccountScreen(
//                                           customerId: currentCustomer.id,
//                                           customerName: currentCustomer.name,
//                                           fallbackBalance:
//                                               currentCustomer.currentBalance,
//                                         ),
//                                       ),
//                                     )
//                                     .then((_) => cubit.load());
//                               },
//                             ),
//                             SizedBox(height: 16.h),
//                             CustomerFinancialInfoCard(detail: detail),
//                             SizedBox(height: 16.h),
//                             CustomerTopProductsSection(
//                               products: analysis.topProducts,
//                               isLoading: analysis.isLoading,
//                             ),
//                             SizedBox(height: 16.h),
//                             CustomerNotBoughtSection(
//                               products: analysis.notBoughtRecently,
//                               isLoading: analysis.isLoading,
//                             ),
//                             SizedBox(height: 16.h),
//                             CustomerNotesSection(
//                               customerId: currentCustomer.id,
//                               initialNotes: detail.notes,
//                             ),
//                             SizedBox(height: 16.h),
//                             CustomerVisitHistorySection(
//                                 customerId: currentCustomer.id),
//                             SizedBox(height: 16.h),
//                             CustomerAccountStatementSection(
//                               customerId: currentCustomer.id,
//                               recentInvoices: analysis.recentInvoices,
//                               allInvoices: analysis.allInvoices,
//                               customerName: currentCustomer.name,
//                               currentBalance: currentCustomer.currentBalance,
//                               isLoading: analysis.isLoading,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../../customer_account/presentation/screens/customer_account_screen.dart';
import '../../../../home/domain/models/quick_invoice_models.dart';
import '../../../../home/presentation/widgets/quick_invoice_dialog.dart';
import '../../data/customers_repository.dart';
import '../../domain/models/customer_detail_model.dart';
import '../../domain/models/customer_model.dart';
import '../../screens/widgets/customer_detail/customer_account_statement_section.dart';
import '../../screens/widgets/customer_detail/customer_detail_header.dart';
import '../../screens/widgets/customer_detail/customer_financial_info_card.dart';
import '../../screens/widgets/customer_detail/customer_notes_section.dart';
import '../../screens/widgets/customer_detail/customer_products_section.dart';
import '../../screens/widgets/customer_detail/customer_visit_history_section.dart';
import '../cubit/customer_analysis_cubit.dart';
import '../cubit/customer_analysis_state.dart';
import 'widgets/customer_detail/customer_quick_actions_bar.dart';

class CustomerDetailScreen extends StatelessWidget {
  final CustomerModel customer;

  const CustomerDetailScreen({super.key, required this.customer});

  InvoiceCustomerModel _toInvoiceCustomer(
    CustomerDetailModel detail,
    CustomerAnalysisState analysis,
  ) {
    return InvoiceCustomerModel(
      customer: detail.customer,
      topPurchasedProducts: analysis.topProducts.map((p) => p.name).toList(),
      notPurchasedRecently:
          analysis.notBoughtRecently.map((p) => p.name).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerAnalysisCubit(customer.id)..load(),
      child: ValueListenableBuilder<List<CustomerModel>>(
        valueListenable: CustomersRepository.instance.customersNotifier,
        builder: (context, _, __) {
          final currentCustomer =
              CustomersRepository.instance.getCustomerById(customer.id) ??
                  customer;
          final detail = CustomerDetailModel.mock(currentCustomer);

          return BlocBuilder<CustomerAnalysisCubit, CustomerAnalysisState>(
            builder: (context, analysis) {
              return Scaffold(
                body: SafeArea(
                  child: Column(
                    children: [
                      CustomerDetailHeader(customer: currentCustomer),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 30.h),
                          children: [
                            CustomerQuickActionsBar(
                              customer: currentCustomer,
                              onInvoiceTap: () {
                                final cubit =
                                    context.read<CustomerAnalysisCubit>();
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) => QuickInvoiceDialog(
                                          initialCustomer: _toInvoiceCustomer(
                                              detail, analysis),
                                        ),
                                      ),
                                    )
                                    .then((_) => cubit.load());
                              },
                              // Was: showCustomerCollectPaymentSheet(context, detail: detail).
                              // The old collection-only sheet is replaced by the full
                              // customer financial account (invoices, payments, returns,
                              // running balance). NOTE: the "ط§ظ„طھط­طµظٹظ„" button label lives
                              // inside CustomerQuickActionsBar (not provided to us) â€” its
                              // text should be updated there to "ط§ظ„ط­ط³ط§ط¨ ظˆط§ظ„ظ…ط¹ط§ظ…ظ„ط§طھ" or similar.
                              onCollectTap: () {
                                final cubit =
                                    context.read<CustomerAnalysisCubit>();
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) => CustomerAccountScreen(
                                          customerId: currentCustomer.id,
                                          customerName: currentCustomer.name,
                                          fallbackBalance:
                                              currentCustomer.currentBalance,
                                        ),
                                      ),
                                    )
                                    .then((_) => cubit.load());
                              },
                            ),
                            SizedBox(height: 16.h),
                            CustomerFinancialInfoCard(detail: detail),
                            SizedBox(height: 16.h),
                            CustomerTopProductsSection(
                              products: analysis.topProducts,
                              isLoading: analysis.isLoading,
                            ),
                            SizedBox(height: 16.h),
                            CustomerNotBoughtSection(
                              products: analysis.notBoughtRecently,
                              isLoading: analysis.isLoading,
                            ),
                            SizedBox(height: 16.h),
                            CustomerNotesSection(
                              customerId: currentCustomer.id,
                              initialNotes: detail.notes,
                            ),
                            SizedBox(height: 16.h),
                            CustomerVisitHistorySection(
                                customerId: currentCustomer.id),
                            SizedBox(height: 16.h),
                            CustomerAccountStatementSection(
                              customerId: currentCustomer.id,
                              recentInvoices: analysis.recentInvoices,
                              allInvoices: analysis.allInvoices,
                              customerName: currentCustomer.name,
                              currentBalance: currentCustomer.currentBalance,
                              isLoading: analysis.isLoading,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}



============================================================
FILE: .\lib\features\customer-visits\customers\screens\customer_detail_screen.dart
============================================================

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:mivet_app/core/utils/responsive_extension.dart';
// import '../../../customer_account/presentation/screens/customer_account_screen.dart';
// import '../../../home/domain/models/quick_invoice_models.dart';
// import '../../../home/presentation/widgets/quick_invoice_dialog.dart';

// class CustomerDetailScreen extends StatelessWidget {
//   final CustomerModel customer;

//   const CustomerDetailScreen({super.key, required this.customer});

//   InvoiceCustomerModel _toInvoiceCustomer(
//     CustomerDetailModel detail,
//     CustomerAnalysisState analysis,
//   ) {
//     return InvoiceCustomerModel(
//       customer: detail.customer,
//       topPurchasedProducts: analysis.topProducts.map((p) => p.name).toList(),
//       notPurchasedRecently:
//           analysis.notBoughtRecently.map((p) => p.name).toList(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => CustomerAnalysisCubit(customer.id)..load(),
//       child: ValueListenableBuilder<List<CustomerModel>>(
//         valueListenable: CustomersRepository.instance.customersNotifier,
//         builder: (context, _, __) {
//           final currentCustomer =
//               CustomersRepository.instance.getCustomerById(customer.id) ??
//                   customer;
//           final detail = CustomerDetailModel.mock(currentCustomer);

//           return BlocBuilder<CustomerAnalysisCubit, CustomerAnalysisState>(
//             builder: (context, analysis) {
//               return Scaffold(
//                 body: SafeArea(
//                   child: Column(
//                     children: [
//                       CustomerDetailHeader(customer: currentCustomer),
//                       Expanded(
//                         child: ListView(
//                           padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 30.h),
//                           children: [
//                             CustomerQuickActionsBar(
//                               customer: currentCustomer,
//                               onInvoiceTap: () {
//                                 final cubit =
//                                     context.read<CustomerAnalysisCubit>();
//                                 Navigator.of(context)
//                                     .push(
//                                       MaterialPageRoute(
//                                         builder: (_) => QuickInvoiceDialog(
//                                           initialCustomer: _toInvoiceCustomer(
//                                               detail, analysis),
//                                         ),
//                                       ),
//                                     )
//                                     .then((_) => cubit.load());
//                               },
//                               // Was: showCustomerCollectPaymentSheet(context, detail: detail).
//                               // The old collection-only sheet is replaced by the full
//                               // customer financial account (invoices, payments, returns,
//                               // running balance). NOTE: the "ط§ظ„طھط­طµظٹظ„" button label lives
//                               // inside CustomerQuickActionsBar (not provided to us) â€” its
//                               // text should be updated there to "ط§ظ„ط­ط³ط§ط¨ ظˆط§ظ„ظ…ط¹ط§ظ…ظ„ط§طھ" or similar.
//                               onCollectTap: () {
//                                 final cubit =
//                                     context.read<CustomerAnalysisCubit>();
//                                 Navigator.of(context)
//                                     .push(
//                                       MaterialPageRoute(
//                                         builder: (_) => CustomerAccountScreen(
//                                           customerId: currentCustomer.id,
//                                           customerName: currentCustomer.name,
//                                           fallbackBalance:
//                                               currentCustomer.currentBalance,
//                                         ),
//                                       ),
//                                     )
//                                     .then((_) => cubit.load());
//                               },
//                             ),
//                             SizedBox(height: 16.h),
//                             CustomerFinancialInfoCard(detail: detail),
//                             SizedBox(height: 16.h),
//                             CustomerTopProductsSection(
//                               products: analysis.topProducts,
//                               isLoading: analysis.isLoading,
//                             ),
//                             SizedBox(height: 16.h),
//                             CustomerNotBoughtSection(
//                               products: analysis.notBoughtRecently,
//                               isLoading: analysis.isLoading,
//                             ),
//                             SizedBox(height: 16.h),
//                             CustomerNotesSection(
//                               customerId: currentCustomer.id,
//                               initialNotes: detail.notes,
//                             ),
//                             SizedBox(height: 16.h),
//                             CustomerVisitHistorySection(
//                                 customerId: currentCustomer.id),
//                             SizedBox(height: 16.h),
//                             CustomerAccountStatementSection(
//                               customerId: currentCustomer.id,
//                               recentInvoices: analysis.recentInvoices,
//                               allInvoices: analysis.allInvoices,
//                               customerName: currentCustomer.name,
//                               currentBalance: currentCustomer.currentBalance,
//                               isLoading: analysis.isLoading,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../customer_account/presentation/screens/customer_account_screen.dart';
import '../../../home/domain/models/quick_invoice_models.dart';
import '../../../home/presentation/widgets/quick_invoice_dialog.dart';
import '../data/customers_repository.dart';
import '../domain/models/customer_detail_model.dart';
import '../domain/models/customer_model.dart';
import '../presentation/cubit/customer_analysis_cubit.dart';
import '../presentation/cubit/customer_analysis_state.dart';
import '../presentation/screens/widgets/customer_detail/customer_quick_actions_bar.dart';
import 'widgets/customer_detail/customer_account_statement_section.dart';
import 'widgets/customer_detail/customer_detail_header.dart';
import 'widgets/customer_detail/customer_financial_info_card.dart';
import 'widgets/customer_detail/customer_notes_section.dart';
import 'widgets/customer_detail/customer_products_section.dart';
import 'widgets/customer_detail/customer_visit_history_section.dart';

class CustomerDetailScreen extends StatelessWidget {
  final CustomerModel customer;

  const CustomerDetailScreen({super.key, required this.customer});

  InvoiceCustomerModel _toInvoiceCustomer(
    CustomerDetailModel detail,
    CustomerAnalysisState analysis,
  ) {
    return InvoiceCustomerModel(
      customer: detail.customer,
      topPurchasedProducts: analysis.topProducts.map((p) => p.name).toList(),
      notPurchasedRecently:
          analysis.notBoughtRecently.map((p) => p.name).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerAnalysisCubit(customer.id)..load(),
      child: ValueListenableBuilder<List<CustomerModel>>(
        valueListenable: CustomersRepository.instance.customersNotifier,
        builder: (context, _, __) {
          final currentCustomer =
              CustomersRepository.instance.getCustomerById(customer.id) ??
                  customer;
          final detail = CustomerDetailModel.mock(currentCustomer);

          return BlocBuilder<CustomerAnalysisCubit, CustomerAnalysisState>(
            builder: (context, analysis) {
              return Scaffold(
                body: SafeArea(
                  child: Column(
                    children: [
                      CustomerDetailHeader(customer: currentCustomer),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 30.h),
                          children: [
                            CustomerQuickActionsBar(
                              customer: currentCustomer,
                              onInvoiceTap: () {
                                final cubit =
                                    context.read<CustomerAnalysisCubit>();
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) => QuickInvoiceDialog(
                                          initialCustomer: _toInvoiceCustomer(
                                              detail, analysis),
                                        ),
                                      ),
                                    )
                                    .then((_) => cubit.load());
                              },
                              // Was: showCustomerCollectPaymentSheet(context, detail: detail).
                              // The old collection-only sheet is replaced by the full
                              // customer financial account (invoices, payments, returns,
                              // running balance). NOTE: the "ط§ظ„طھط­طµظٹظ„" button label lives
                              // inside CustomerQuickActionsBar (not provided to us) â€” its
                              // text should be updated there to "ط§ظ„ط­ط³ط§ط¨ ظˆط§ظ„ظ…ط¹ط§ظ…ظ„ط§طھ" or similar.
                              onCollectTap: () {
                                final cubit =
                                    context.read<CustomerAnalysisCubit>();
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) => CustomerAccountScreen(
                                          customerId: currentCustomer.id,
                                          customerName: currentCustomer.name,
                                          fallbackBalance:
                                              currentCustomer.currentBalance,
                                        ),
                                      ),
                                    )
                                    .then((_) => cubit.load());
                              },
                            ),
                            SizedBox(height: 16.h),
                            CustomerFinancialInfoCard(detail: detail),
                            SizedBox(height: 16.h),
                            CustomerTopProductsSection(
                              products: analysis.topProducts,
                              isLoading: analysis.isLoading,
                            ),
                            SizedBox(height: 16.h),
                            CustomerNotBoughtSection(
                              products: analysis.notBoughtRecently,
                              isLoading: analysis.isLoading,
                            ),
                            SizedBox(height: 16.h),
                            CustomerNotesSection(
                              customerId: currentCustomer.id,
                              initialNotes: detail.notes,
                            ),
                            SizedBox(height: 16.h),
                            CustomerVisitHistorySection(
                                customerId: currentCustomer.id),
                            SizedBox(height: 16.h),
                            CustomerAccountStatementSection(
                              customerId: currentCustomer.id,
                              recentInvoices: analysis.recentInvoices,
                              allInvoices: analysis.allInvoices,
                              customerName: currentCustomer.name,
                              currentBalance: currentCustomer.currentBalance,
                              isLoading: analysis.isLoading,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}



============================================================
FILE: .\lib\features\customer-visits\customers\screens\edit_invoice_screen.dart
============================================================

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:mivet_app/core/errors/app_toast.dart';
// import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
// import 'package:mivet_app/core/theme/app_text_styles.dart';
// import 'package:mivet_app/core/utils/responsive_extension.dart';
// import '../../../inventory/data/products_repository.dart';
// import '../../../inventory/domain/models/product_model.dart';
// import '../../../invoices/domain/invoice_draft.dart';
// import '../data/invoices_repository.dart';

// class EditInvoiceScreen extends StatefulWidget {
//   final InvoiceFullDetail invoice;
//   final String customerName;
//   final String customerId;

//   const EditInvoiceScreen({
//     super.key,
//     required this.invoice,
//     required this.customerName,
//     required this.customerId,
//   });

//   @override
//   State<EditInvoiceScreen> createState() => _EditInvoiceScreenState();
// }

// class _EditInvoiceScreenState extends State<EditInvoiceScreen> {
//   late final InvoiceDraft _draft;
//   final _discountController = TextEditingController();
//   final _notesController = TextEditingController();

//   Map<String, CustomerProductPrice> _customerPrices = {};
//   bool _loading = true;
//   bool _saving = false;
//   int _currentPage = 1;

//   @override
//   void initState() {
//     super.initState();
//     _draft = InvoiceDraft();
//     _discountController.text =
//         widget.invoice.discountPercent.toStringAsFixed(2);
//     _notesController.text = widget.invoice.notes ?? '';
//     _load();
//   }

//   @override
//   void dispose() {
//     _discountController.dispose();
//     _notesController.dispose();
//     super.dispose();
//   }

//   Future<void> _load() async {
//     try {
//       final prices = await InvoicesRepository.instance
//           .getCustomerProductPrices(widget.customerId);

//       for (final item in widget.invoice.items) {
//         _draft.items.add(
//           InvoiceItemDraft(
//             invoiceItemId: item.id,
//             product: _productFromInvoiceItem(item),
//             productId: item.productId,
//             quantity: item.quantity,
//             unitPrice: item.unitPrice,
//             previousCustomerPrice: item.productId == null
//                 ? null
//                 : prices[item.productId]?.lastPrice,
//           ),
//         );
//       }

//       if (!mounted) return;

//       setState(() {
//         _customerPrices = prices;
//         _loading = false;
//       });
//     } catch (error) {
//       if (!mounted) return;
//       setState(() => _loading = false);
//       showAppError(context, error);
//     }
//   }

//   ProductModel _productFromInvoiceItem(InvoiceItemRow item) {
//     return ProductModel(
//       id: item.productId ?? '',
//       name: item.productName,
//       category: 'other',
//       unit: 'piece',
//       retailPrice: item.unitPrice,
//       wholesalePrice: item.unitPrice,
//       minStockThreshold: 0,
//       createdAt: widget.invoice.date,
//     );
//   }

//   double get discountPercent {
//     final value = double.tryParse(_discountController.text) ?? 0;
//     return value.clamp(0, 100).toDouble();
//   }

//   double get subtotal => _draft.items.fold(0, (sum, item) => sum + item.total);

//   double get discountAmount => subtotal * discountPercent / 100;

//   double get total => subtotal - discountAmount;

//   Future<void> _addProduct() async {
//     try {
//       final products = await ProductsRepository.instance.getProducts();

//       if (!mounted) return;

//       final product = await showModalBottomSheet<ProductModel>(
//         context: context,
//         isScrollControlled: true,
//         backgroundColor: Colors.transparent,
//         builder: (_) => _ProductPickerSheet(
//           products: products,
//           existingItems: _draft.items,
//           customerPrices: _customerPrices,
//         ),
//       );

//       if (product == null || !mounted) return;

//       final index = _draft.items.indexWhere(
//         (item) => item.productId == product.id,
//       );

//       if (index >= 0) {
//         setState(() => _draft.items[index].quantity++);
//         return;
//       }

//       final price = suggestedPrice(product, _customerPrices);

//       setState(() {
//         _draft.items.add(
//           InvoiceItemDraft(
//             product: product,
//             productId: product.id,
//             quantity: 1,
//             unitPrice: price,
//             previousCustomerPrice: _customerPrices[product.id]?.lastPrice,
//           ),
//         );
//         _currentPage = _draft.pageCount;
//       });
//     } catch (error) {
//       if (mounted) showAppError(context, error);
//     }
//   }

//   Future<void> _editPrice(InvoiceItemDraft item) async {
//     final controller = TextEditingController(
//       text: item.unitPrice.toStringAsFixed(2),
//     );

//     final value = await showDialog<double>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text(
//             'ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¹ط·آ¢ط¢آ¾ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¯ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€  ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ³ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ± ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¨ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¹'),
//         content: TextField(
//           controller: controller,
//           autofocus: true,
//           keyboardType: const TextInputType.numberWithOptions(
//             decimal: true,
//           ),
//           inputFormatters: [
//             FilteringTextInputFormatter.allow(
//               RegExp(r'^\d*\.?\d{0,2}'),
//             ),
//           ],
//           decoration: const InputDecoration(
//             labelText:
//                 'ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ³ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ± ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ«ط£آ¢أ¢â€ڑآ¬ط¢آ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ­ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¯ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ©',
//             suffixText: 'ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¬.ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ¦',
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text(
//                 'ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¥ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ·ط£آ¢أ¢â€ڑآ¬ط·â€؛ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ·ط·آ¥أ¢â‚¬â„¢'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               final parsed = double.tryParse(controller.text);
//               if (parsed == null || parsed < 0) return;
//               Navigator.pop(context, parsed);
//             },
//             child:
//                 const Text('ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ­ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¾ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¸'),
//           ),
//         ],
//       ),
//     );

//     WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());

//     if (value == null || !mounted) return;

//     setState(() => item.unitPrice = value);
//   }

//   void _changeQuantity(InvoiceItemDraft item, int delta) {
//     final next = item.quantity + delta;
//     if (next < 1) return;
//     setState(() => item.quantity = next);
//   }

//   void _removeItem(InvoiceItemDraft item) {
//     setState(() {
//       _draft.remove(item);
//       if (_currentPage > _draft.pageCount) {
//         _currentPage = _draft.pageCount;
//       }
//     });
//   }

//   Future<void> _requestSave() async {
//     if (_draft.items.isEmpty) {
//       showAppError(context,
//           'ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¾ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¹ط·آ¢ط¢آ¾ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ«ط£آ¢أ¢â€ڑآ¬ط¢آ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ±ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ© ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¬ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¨ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ£ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ  ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¹ط·آ¢ط¢آ¾ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ­ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¹ط·آ¢ط¢آ¾ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ«ط£آ¢أ¢â€ڑآ¬ط¢آ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¹ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ° ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آµط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¾ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ«ط£آ¢أ¢â€ڑآ¬ط¢آ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ­ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¯ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ° ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ£ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¹أ¢â‚¬ع©ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ');
//       return;
//     }

//     final reasonController = TextEditingController();

//     final reason = await showDialog<String>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text(
//             'ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ³ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¨ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¨ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¹ط·آ¢ط¢آ¾ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¯ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€  ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¾ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¹ط·آ¢ط¢آ¾ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ«ط£آ¢أ¢â€ڑآ¬ط¢آ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ±ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ©'),
//         content: TextField(
//           controller: reasonController,
//           autofocus: true,
//           maxLines: 3,
//           decoration: const InputDecoration(
//             labelText:
//                 'ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ³ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¨ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¨',
//             hintText:
//                 'ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ¦ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ«ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ : ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¹ط·آ¢ط¢آ¾ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¯ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€  ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¦ط£آ¢أ¢â€ڑآ¬أ¢â€‍آ¢ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ¦ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ© ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¨ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ·ط·آ¥أ¢â‚¬â„¢ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ¹ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ° ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ·ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¨ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ¦ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ',
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text(
//                 'ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¥ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ·ط£آ¢أ¢â€ڑآ¬ط·â€؛ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ·ط·آ¥أ¢â‚¬â„¢'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               final value = reasonController.text.trim();
//               if (value.isEmpty) return;
//               Navigator.pop(context, value);
//             },
//             child: const Text(
//                 'ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ¦ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¹ط·آ¢ط¢آ¾ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¨ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ©'),
//           ),
//         ],
//       ),
//     );

//     WidgetsBinding.instance.addPostFrameCallback(
//       (_) => reasonController.dispose(),
//     );

//     if (reason == null || reason.isEmpty || !mounted) return;

//     await _save(reason);
//   }

//   Future<void> _save(String reason) async {
//     setState(() => _saving = true);

//     try {
//       await InvoicesRepository.instance.editInvoice(
//         invoiceId: widget.invoice.id,
//         items: _draft.items,
//         discountPercent: discountPercent,
//         reason: reason,
//         notes: _notesController.text.trim().isEmpty
//             ? null
//             : _notesController.text.trim(),
//       );

//       if (!mounted) return;
//       Navigator.pop(context, true);
//     } catch (error) {
//       if (!mounted) return;
//       setState(() => _saving = false);
//       showAppError(context, error);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;

//     return Scaffold(
//       backgroundColor: colors.background,
//       body: SafeArea(
//         child: Column(
//           children: [
//             _Header(
//               invoiceCode: widget.invoice.code,
//               customerName: widget.customerName,
//               onBack: () => Navigator.pop(context),
//             ),
//             Expanded(
//               child: _loading
//                   ? const Center(child: CircularProgressIndicator())
//                   : ListView(
//                       padding: EdgeInsets.all(16.w),
//                       children: [
//                         Row(
//                           children: [
//                             Expanded(
//                               child: Text(
//                                 'ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ£ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آµط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¾ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¾ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¹ط·آ¢ط¢آ¾ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ«ط£آ¢أ¢â€ڑآ¬ط¢آ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ±ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ©',
//                                 style: AppTextStyles.cairoMedium16.copyWith(
//                                   color: colors.text,
//                                   fontSize: 14.sp,
//                                 ),
//                               ),
//                             ),
//                             ElevatedButton.icon(
//                               onPressed: _addProduct,
//                               style: ElevatedButton.styleFrom(
//                                 minimumSize: Size.zero,
//                                 padding: EdgeInsets.symmetric(
//                                   horizontal: 12.w,
//                                   vertical: 8.h,
//                                 ),
//                                 tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                               ),
//                               icon: Icon(Icons.add, size: 18.sp),
//                               label: const Text(
//                                   'ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¥ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¶ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¾ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ© ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آµط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¾'),
//                             ),
//                           ],
//                         ),
//                         SizedBox(height: 10.h),
//                         ..._draft.itemsForPage(_currentPage).map(
//                               (item) => _InvoiceItemCard(
//                                 item: item,
//                                 onIncrease: () => _changeQuantity(item, 1),
//                                 onDecrease: () => _changeQuantity(item, -1),
//                                 onEditPrice: () => _editPrice(item),
//                                 onRemove: () => _removeItem(item),
//                               ),
//                             ),
//                         if (_draft.pageCount > 1)
//                           _Pagination(
//                             page: _currentPage,
//                             pageCount: _draft.pageCount,
//                             onChanged: (page) {
//                               setState(() => _currentPage = page);
//                             },
//                           ),
//                         SizedBox(height: 14.h),
//                         _TotalsCard(
//                           subtotal: subtotal,
//                           discountAmount: discountAmount,
//                           total: total,
//                           controller: _discountController,
//                           onChanged: () => setState(() {}),
//                         ),
//                         SizedBox(height: 14.h),
//                         TextField(
//                           controller: _notesController,
//                           maxLines: 3,
//                           decoration: const InputDecoration(
//                             labelText:
//                                 'ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ¦ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ­ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¸ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¹ط·آ¢ط¢آ¾ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¾ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¹ط·آ¢ط¢آ¾ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ«ط£آ¢أ¢â€ڑآ¬ط¢آ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ±ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ©',
//                             alignLabelWithHint: true,
//                           ),
//                         ),
//                       ],
//                     ),
//             ),
//             Container(
//               padding: EdgeInsets.all(16.w),
//               decoration: BoxDecoration(
//                 color: colors.surface,
//                 border: Border(
//                   top: BorderSide(color: colors.border),
//                 ),
//               ),
//               child: SizedBox(
//                 width: double.infinity,
//                 height: 48.h,
//                 child: ElevatedButton(
//                   onPressed: _saving ? null : _requestSave,
//                   child: _saving
//                       ? const SizedBox(
//                           width: 22,
//                           height: 22,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                           ),
//                         )
//                       : const Text(
//                           'ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ­ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¾ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¸ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¹ط·آ¢ط¢آ¾ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¯ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¹ط·آ¢ط¢آ¾'),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _Header extends StatelessWidget {
//   final String invoiceCode;
//   final String customerName;
//   final VoidCallback onBack;

//   const _Header({
//     required this.invoiceCode,
//     required this.customerName,
//     required this.onBack,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;

//     return Container(
//       color: colors.surface,
//       padding: EdgeInsets.fromLTRB(8.w, 10.h, 16.w, 14.h),
//       child: Row(
//         children: [
//           IconButton(
//             onPressed: onBack,
//             icon: Icon(
//               Icons.arrow_back_ios_new,
//               color: colors.primary,
//               size: 19.sp,
//             ),
//           ),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¹ط·آ¢ط¢آ¾ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¯ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€  ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¾ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¹ط·آ¢ط¢آ¾ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ«ط£آ¢أ¢â€ڑآ¬ط¢آ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ±ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ© $invoiceCode',
//                   style: AppTextStyles.cairoBold18.copyWith(
//                     color: colors.primary,
//                     fontSize: 16.sp,
//                   ),
//                 ),
//                 Text(
//                   customerName,
//                   style: AppTextStyles.almaraiRegular14.copyWith(
//                     color: colors.textMuted,
//                     fontSize: 11.sp,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _InvoiceItemCard extends StatelessWidget {
//   final InvoiceItemDraft item;
//   final VoidCallback onIncrease;
//   final VoidCallback onDecrease;
//   final VoidCallback onEditPrice;
//   final VoidCallback onRemove;

//   const _InvoiceItemCard({
//     required this.item,
//     required this.onIncrease,
//     required this.onDecrease,
//     required this.onEditPrice,
//     required this.onRemove,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;

//     return Container(
//       margin: EdgeInsets.only(bottom: 9.h),
//       padding: EdgeInsets.all(12.w),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(14.r),
//         border: Border.all(color: colors.border),
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   item.product.name,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: AppTextStyles.cairoMedium16.copyWith(
//                     color: colors.text,
//                     fontSize: 13.sp,
//                   ),
//                 ),
//               ),
//               IconButton(
//                 onPressed: onRemove,
//                 icon: Icon(
//                   Icons.delete_outline,
//                   color: colors.textMuted,
//                   size: 20.sp,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 8.h),
//           Row(
//             children: [
//               Expanded(
//                 child: InkWell(
//                   onTap: onEditPrice,
//                   borderRadius: BorderRadius.circular(10.r),
//                   child: Container(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: 10.w,
//                       vertical: 9.h,
//                     ),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(10.r),
//                       border: Border.all(color: colors.border),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           Icons.edit_outlined,
//                           color: colors.primary,
//                           size: 15.sp,
//                         ),
//                         SizedBox(width: 6.w),
//                         Text(
//                           '${item.unitPrice.toStringAsFixed(2)} ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¬.ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ¦',
//                           style: AppTextStyles.cairoMedium16.copyWith(
//                             color: colors.text,
//                             fontSize: 12.sp,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(width: 8.w),
//               _QuantityControl(
//                 quantity: item.quantity,
//                 onIncrease: onIncrease,
//                 onDecrease: onDecrease,
//               ),
//             ],
//           ),
//           SizedBox(height: 8.h),
//           Row(
//             children: [
//               Text(
//                 'ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¥ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¬ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ¦ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¹',
//                 style: AppTextStyles.almaraiRegular14.copyWith(
//                   color: colors.textMuted,
//                   fontSize: 11.sp,
//                 ),
//               ),
//               const Spacer(),
//               Text(
//                 '${item.total.toStringAsFixed(2)} ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¬.ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ¦',
//                 style: AppTextStyles.cairoBold18.copyWith(
//                   color: colors.primary,
//                   fontSize: 14.sp,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _QuantityControl extends StatelessWidget {
//   final int quantity;
//   final VoidCallback onIncrease;
//   final VoidCallback onDecrease;

//   const _QuantityControl({
//     required this.quantity,
//     required this.onIncrease,
//     required this.onDecrease,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;

//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(10.r),
//         border: Border.all(color: colors.border),
//       ),
//       child: Row(
//         children: [
//           IconButton(
//             onPressed: onDecrease,
//             icon: const Icon(Icons.remove),
//             constraints: const BoxConstraints(
//               minWidth: 38,
//               minHeight: 38,
//             ),
//           ),
//           SizedBox(
//             width: 28.w,
//             child: Text(
//               '$quantity',
//               textAlign: TextAlign.center,
//               style: AppTextStyles.cairoMedium16.copyWith(
//                 color: colors.text,
//                 fontSize: 13.sp,
//               ),
//             ),
//           ),
//           IconButton(
//             onPressed: onIncrease,
//             icon: const Icon(Icons.add),
//             constraints: const BoxConstraints(
//               minWidth: 38,
//               minHeight: 38,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _Pagination extends StatelessWidget {
//   final int page;
//   final int pageCount;
//   final ValueChanged<int> onChanged;

//   const _Pagination({
//     required this.page,
//     required this.pageCount,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         IconButton(
//           onPressed: page > 1 ? () => onChanged(page - 1) : null,
//           icon: const Icon(Icons.chevron_left),
//         ),
//         Text('$page / $pageCount'),
//         IconButton(
//           onPressed: page < pageCount ? () => onChanged(page + 1) : null,
//           icon: const Icon(Icons.chevron_right),
//         ),
//       ],
//     );
//   }
// }

// class _TotalsCard extends StatelessWidget {
//   final double subtotal;
//   final double discountAmount;
//   final double total;
//   final TextEditingController controller;
//   final VoidCallback onChanged;

//   const _TotalsCard({
//     required this.subtotal,
//     required this.discountAmount,
//     required this.total,
//     required this.controller,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;

//     return Container(
//       padding: EdgeInsets.all(14.w),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(16.r),
//         border: Border.all(color: colors.border),
//       ),
//       child: Column(
//         children: [
//           _MoneyRow(
//             label:
//                 'ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¥ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¬ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ¦ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¹ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¹أ¢â‚¬ع©ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¨ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€  ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ®ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آµط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ¦',
//             value: subtotal,
//           ),
//           SizedBox(height: 8.h),
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   'ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ³ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¨ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ© ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ®ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آµط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ¦',
//                   style: AppTextStyles.almaraiRegular14.copyWith(
//                     color: colors.textMuted,
//                     fontSize: 11.sp,
//                   ),
//                 ),
//               ),
//               SizedBox(
//                 width: 90.w,
//                 child: TextField(
//                   controller: controller,
//                   textAlign: TextAlign.center,
//                   keyboardType: const TextInputType.numberWithOptions(
//                     decimal: true,
//                   ),
//                   inputFormatters: [
//                     FilteringTextInputFormatter.allow(
//                       RegExp(r'^\d{0,3}\.?\d{0,2}'),
//                     ),
//                   ],
//                   decoration: const InputDecoration(
//                     suffixText: '%',
//                     isDense: true,
//                   ),
//                   onChanged: (_) => onChanged(),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 8.h),
//           _MoneyRow(
//             label:
//                 'ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¹أ¢â‚¬ع©ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ¦ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ© ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ®ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آµط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ¦',
//             value: discountAmount,
//           ),
//           Divider(color: colors.border),
//           _MoneyRow(
//             label:
//                 'ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¥ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¬ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ¦ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¹ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ·ط¥â€™ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¦ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¹',
//             value: total,
//             highlight: true,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _MoneyRow extends StatelessWidget {
//   final String label;
//   final double value;
//   final bool highlight;

//   const _MoneyRow({
//     required this.label,
//     required this.value,
//     this.highlight = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;

//     return Row(
//       children: [
//         Text(
//           label,
//           style: AppTextStyles.almaraiRegular14.copyWith(
//             color: colors.textMuted,
//             fontSize: 11.sp,
//           ),
//         ),
//         const Spacer(),
//         Text(
//           '${value.toStringAsFixed(2)} ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¬.ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ¦',
//           style: AppTextStyles.cairoMedium16.copyWith(
//             color: highlight ? colors.primary : colors.text,
//             fontSize: highlight ? 15.sp : 12.sp,
//             fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _ProductPickerSheet extends StatefulWidget {
//   final List<ProductModel> products;
//   final List<InvoiceItemDraft> existingItems;
//   final Map<String, CustomerProductPrice> customerPrices;

//   const _ProductPickerSheet({
//     required this.products,
//     required this.existingItems,
//     required this.customerPrices,
//   });

//   @override
//   State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
// }

// class _ProductPickerSheetState extends State<_ProductPickerSheet> {
//   final _searchController = TextEditingController();
//   String _search = '';

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;
//     final query = _search.trim().toLowerCase();

//     final filtered = widget.products.where((product) {
//       return query.isEmpty || product.name.toLowerCase().contains(query);
//     }).toList();

//     return SafeArea(
//       child: Container(
//         height: MediaQuery.of(context).size.height * .82,
//         decoration: BoxDecoration(
//           color: colors.background,
//           borderRadius: BorderRadius.vertical(
//             top: Radius.circular(22.r),
//           ),
//         ),
//         child: Column(
//           children: [
//             Padding(
//               padding: EdgeInsets.all(16.w),
//               child: TextField(
//                 controller: _searchController,
//                 onChanged: (value) => setState(() => _search = value),
//                 decoration: const InputDecoration(
//                   hintText:
//                       'ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¨ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ­ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ« ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ  ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آµط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¾',
//                   prefixIcon: Icon(Icons.search),
//                 ),
//               ),
//             ),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: filtered.length,
//                 itemBuilder: (_, index) {
//                   final product = filtered[index];
//                   final added = widget.existingItems.any(
//                     (item) => item.productId == product.id,
//                   );
//                   final remembered =
//                       widget.customerPrices[product.id]?.lastPrice;

//                   return ListTile(
//                     onTap: () => Navigator.pop(context, product),
//                     title: Text(product.name),
//                     subtitle: Text(
//                       remembered == null
//                           ? 'ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ«ط£آ¢أ¢â€ڑآ¬ط¢آ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¬ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¯ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ³ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ± ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ³ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ§ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¨ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¹أ¢â‚¬ع© ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ¦ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ '
//                           : 'ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¢ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ®ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ± ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ³ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ± ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ¦ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ·ط¢آ¸ط·آ¢ط¢آ¹ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط£آ¢أ¢â€ڑآ¬ط¹â€ : ${remembered.toStringAsFixed(2)} ط·آ·ط¢آ·ط·آ¢ط¢آ·ط·آ·ط¢آ¢ط·آ¢ط¢آ¬.ط·آ·ط¢آ·ط·آ¢ط¢آ¸ط·آ£ط¢آ¢ط£آ¢أ¢â‚¬ع‘ط¢آ¬ط·آ¢ط¢آ¦',
//                     ),
//                     trailing: Icon(
//                       added
//                           ? Icons.check_circle_outline
//                           : Icons.add_circle_outline,
//                       color: colors.primary,
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../inventory/data/products_repository.dart';
import '../../../inventory/domain/models/product_model.dart';
import '../../../invoices/domain/invoice_draft.dart';
import '../data/invoices_repository.dart';

class EditInvoiceScreen extends StatefulWidget {
  final InvoiceFullDetail invoice;
  final String customerName;
  final String customerId;

  const EditInvoiceScreen({
    super.key,
    required this.invoice,
    required this.customerName,
    required this.customerId,
  });

  @override
  State<EditInvoiceScreen> createState() => _EditInvoiceScreenState();
}

class _EditInvoiceScreenState extends State<EditInvoiceScreen> {
  late final InvoiceDraft _draft;
  final _discountController = TextEditingController();
  final _notesController = TextEditingController();

  Map<String, CustomerProductPrice> _customerPrices = {};
  bool _loading = true;
  bool _saving = false;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _draft = InvoiceDraft();
    _discountController.text =
        widget.invoice.discountPercent.toStringAsFixed(2);
    _notesController.text = widget.invoice.notes ?? '';
    _load();
  }

  @override
  void dispose() {
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prices = await InvoicesRepository.instance
          .getCustomerProductPrices(widget.customerId);

      for (final item in widget.invoice.items) {
        _draft.items.add(
          InvoiceItemDraft(
            invoiceItemId: item.id,
            product: _productFromInvoiceItem(item),
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            previousCustomerPrice: item.productId == null
                ? null
                : prices[item.productId]?.lastPrice,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _customerPrices = prices;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppError(context, error);
    }
  }

  ProductModel _productFromInvoiceItem(InvoiceItemRow item) {
    return ProductModel(
      id: item.productId ?? '',
      name: item.productName,
      category: 'other',
      unit: 'piece',
      retailPrice: item.unitPrice,
      wholesalePrice: item.unitPrice,
      minStockThreshold: 0,
      createdAt: widget.invoice.date,
    );
  }

  double get discountPercent {
    final value = double.tryParse(_discountController.text) ?? 0;
    return value.clamp(0, 100).toDouble();
  }

  double get subtotal => _draft.items.fold(0, (sum, item) => sum + item.total);

  double get discountAmount => subtotal * discountPercent / 100;

  double get total => subtotal - discountAmount;

  Future<void> _addProduct() async {
    try {
      final products = await ProductsRepository.instance.getProducts();

      if (!mounted) return;

      final product = await showModalBottomSheet<ProductModel>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ProductPickerSheet(
          products: products,
          existingItems: _draft.items,
          customerPrices: _customerPrices,
        ),
      );

      if (product == null || !mounted) return;

      final index = _draft.items.indexWhere(
        (item) => item.productId == product.id,
      );

      if (index >= 0) {
        setState(() => _draft.items[index].quantity++);
        return;
      }

      final price = suggestedPrice(product, _customerPrices);

      setState(() {
        _draft.items.add(
          InvoiceItemDraft(
            product: product,
            productId: product.id,
            quantity: 1,
            unitPrice: price,
            previousCustomerPrice: _customerPrices[product.id]?.lastPrice,
          ),
        );
        _currentPage = _draft.pageCount;
      });
    } catch (error) {
      if (mounted) showAppError(context, error);
    }
  }

  Future<void> _editPrice(InvoiceItemDraft item) async {
    final controller = TextEditingController(
      text: item.unitPrice.toStringAsFixed(2),
    );

    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('طھط¹ط¯ظٹظ„ ط§ظ„ط³ط¹ط±'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'^\d*\.?\d{0,2}'),
            ),
          ],
          decoration: const InputDecoration(
            labelText: 'ط§ظ„ط³ط¹ط± ط§ظ„ط¬ط¯ظٹط¯',
            suffixText: 'ط¬.ظ…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ط¥ظ„ط؛ط§ط،'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text);
              if (parsed == null || parsed < 0) return;
              Navigator.pop(context, parsed);
            },
            child: const Text('ط­ظپط¸'),
          ),
        ],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());

    if (value == null || !mounted) return;

    setState(() => item.unitPrice = value);
  }

  void _changeQuantity(InvoiceItemDraft item, int delta) {
    final next = item.quantity + delta;
    if (next < 1) return;
    setState(() => item.quantity = next);
  }

  void _removeItem(InvoiceItemDraft item) {
    setState(() {
      _draft.remove(item);
      if (_currentPage > _draft.pageCount) {
        _currentPage = _draft.pageCount;
      }
    });
  }

  Future<void> _requestSave() async {
    if (_draft.items.isEmpty) {
      showAppError(
        context,
        // REVIEW-WORDING: multi-round mojibake, restored by context
        'ظ„ط§ ظٹظ…ظƒظ† ط­ظپط¸ ط§ظ„ظپط§طھظˆط±ط© ط¨ط¯ظˆظ† ط£طµظ†ط§ظپطŒ ط£ط¶ظپ ظ…ظ†طھط¬ط§ظ‹ ظˆط§ط­ط¯ط§ظ‹ ط¹ظ„ظ‰ ط§ظ„ط£ظ‚ظ„',
      );
      return;
    }

    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ط³ط¨ط¨ طھط¹ط¯ظٹظ„ ط§ظ„ظپط§طھظˆط±ط©'),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'ط§ظ„ط³ط¨ط¨',
            hintText:
                // REVIEW-WORDING: multi-round mojibake, restored by context
                'ظ…ط«ط§ظ„: طھط¹ط¯ظٹظ„ ط§ظ„ظƒظ…ظٹط© ط¨ط¹ط¯ ظ…ط±ط§ط¬ط¹ط© ط§ظ„ط¹ظ…ظٹظ„',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ط¥ظ„ط؛ط§ط،'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = reasonController.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(context, value);
            },
            child: const Text('ظ…طھط§ط¨ط¹ط©'),
          ),
        ],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => reasonController.dispose(),
    );

    if (reason == null || reason.isEmpty || !mounted) return;

    await _save(reason);
  }

  Future<void> _save(String reason) async {
    setState(() => _saving = true);

    try {
      await InvoicesRepository.instance.editInvoice(
        invoiceId: widget.invoice.id,
        items: _draft.items,
        discountPercent: discountPercent,
        reason: reason,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              invoiceCode: widget.invoice.code,
              customerName: widget.customerName,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: EdgeInsets.all(16.w),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                // REVIEW-WORDING: multi-round mojibake, restored by context
                                'ط£طµظ†ط§ظپ ط§ظ„ظپط§طھظˆط±ط©',
                                style: AppTextStyles.cairoMedium16.copyWith(
                                  color: colors.text,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _addProduct,
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 8.h,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: Icon(Icons.add, size: 18.sp),
                              label: const Text('ط¥ط¶ط§ظپط© ظ…ظ†طھط¬'),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        ..._draft.itemsForPage(_currentPage).map(
                              (item) => _InvoiceItemCard(
                                item: item,
                                onIncrease: () => _changeQuantity(item, 1),
                                onDecrease: () => _changeQuantity(item, -1),
                                onEditPrice: () => _editPrice(item),
                                onRemove: () => _removeItem(item),
                              ),
                            ),
                        if (_draft.pageCount > 1)
                          _Pagination(
                            page: _currentPage,
                            pageCount: _draft.pageCount,
                            onChanged: (page) {
                              setState(() => _currentPage = page);
                            },
                          ),
                        SizedBox(height: 14.h),
                        _TotalsCard(
                          subtotal: subtotal,
                          discountAmount: discountAmount,
                          total: total,
                          controller: _discountController,
                          onChanged: () => setState(() {}),
                        ),
                        SizedBox(height: 14.h),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'ظ…ظ„ط§ط­ط¸ط§طھ ط§ظ„طھط¹ط¯ظٹظ„ط§طھ',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
            ),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  top: BorderSide(color: colors.border),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _saving ? null : _requestSave,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('ط­ظپط¸ ط§ظ„طھط¹ط¯ظٹظ„ط§طھ'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String invoiceCode;
  final String customerName;
  final VoidCallback onBack;

  const _Header({
    required this.invoiceCode,
    required this.customerName,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: colors.surface,
      padding: EdgeInsets.fromLTRB(8.w, 10.h, 16.w, 14.h),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: colors.primary,
              size: 19.sp,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طھط¹ط¯ظٹظ„ ط§ظ„ظپط§طھظˆط±ط© $invoiceCode',
                  style: AppTextStyles.cairoBold18.copyWith(
                    color: colors.primary,
                    fontSize: 16.sp,
                  ),
                ),
                Text(
                  customerName,
                  style: AppTextStyles.almaraiRegular14.copyWith(
                    color: colors.textMuted,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceItemCard extends StatelessWidget {
  final InvoiceItemDraft item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onEditPrice;
  final VoidCallback onRemove;

  const _InvoiceItemCard({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onEditPrice,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: EdgeInsets.only(bottom: 9.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cairoMedium16.copyWith(
                    color: colors.text,
                    fontSize: 13.sp,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(
                  Icons.delete_outline,
                  color: colors.textMuted,
                  size: 20.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onEditPrice,
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 9.h,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: colors.primary,
                          size: 15.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '${item.unitPrice.toStringAsFixed(2)} ط¬.ظ…',
                          style: AppTextStyles.cairoMedium16.copyWith(
                            color: colors.text,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              _QuantityControl(
                quantity: item.quantity,
                onIncrease: onIncrease,
                onDecrease: onDecrease,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(
                'ط§ظ„ط¥ط¬ظ…ط§ظ„ظٹ',
                style: AppTextStyles.almaraiRegular14.copyWith(
                  color: colors.textMuted,
                  fontSize: 11.sp,
                ),
              ),
              const Spacer(),
              Text(
                '${item.total.toStringAsFixed(2)} ط¬.ظ…',
                style: AppTextStyles.cairoBold18.copyWith(
                  color: colors.primary,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _QuantityControl({
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove),
            constraints: const BoxConstraints(
              minWidth: 38,
              minHeight: 38,
            ),
          ),
          SizedBox(
            width: 28.w,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.cairoMedium16.copyWith(
                color: colors.text,
                fontSize: 13.sp,
              ),
            ),
          ),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add),
            constraints: const BoxConstraints(
              minWidth: 38,
              minHeight: 38,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  final int page;
  final int pageCount;
  final ValueChanged<int> onChanged;

  const _Pagination({
    required this.page,
    required this.pageCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: page > 1 ? () => onChanged(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('$page / $pageCount'),
        IconButton(
          onPressed: page < pageCount ? () => onChanged(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final double subtotal;
  final double discountAmount;
  final double total;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _TotalsCard({
    required this.subtotal,
    required this.discountAmount,
    required this.total,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          _MoneyRow(
            label: 'ط§ظ„ط¥ط¬ظ…ط§ظ„ظٹ ظ‚ط¨ظ„ ط§ظ„ط®طµظ…',
            value: subtotal,
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'ظ†ط³ط¨ط© ط§ظ„ط®طµظ…',
                  style: AppTextStyles.almaraiRegular14.copyWith(
                    color: colors.textMuted,
                    fontSize: 11.sp,
                  ),
                ),
              ),
              SizedBox(
                width: 90.w,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d{0,3}\.?\d{0,2}'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    suffixText: '%',
                    isDense: true,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          _MoneyRow(
            label: 'ظ‚ظٹظ…ط© ط§ظ„ط®طµظ…',
            value: discountAmount,
          ),
          Divider(color: colors.border),
          _MoneyRow(
            label: 'ط§ظ„ط¥ط¬ظ…ط§ظ„ظٹ ط¨ط¹ط¯ ط§ظ„ط®طµظ…',
            value: total,
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final double value;
  final bool highlight;

  const _MoneyRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.almaraiRegular14.copyWith(
            color: colors.textMuted,
            fontSize: 11.sp,
          ),
        ),
        const Spacer(),
        Text(
          '${value.toStringAsFixed(2)} ط¬.ظ…',
          style: AppTextStyles.cairoMedium16.copyWith(
            color: highlight ? colors.primary : colors.text,
            fontSize: highlight ? 15.sp : 12.sp,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  final List<ProductModel> products;
  final List<InvoiceItemDraft> existingItems;
  final Map<String, CustomerProductPrice> customerPrices;

  const _ProductPickerSheet({
    required this.products,
    required this.existingItems,
    required this.customerPrices,
  });

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final query = _search.trim().toLowerCase();

    final filtered = widget.products.where((product) {
      return query.isEmpty || product.name.toLowerCase().contains(query);
    }).toList();

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * .82,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(22.r),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _search = value),
                decoration: const InputDecoration(
                  hintText: 'ط§ط¨ط­ط« ط¹ظ† ظ…ظ†طھط¬',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, index) {
                  final product = filtered[index];
                  final added = widget.existingItems.any(
                    (item) => item.productId == product.id,
                  );
                  final remembered =
                      widget.customerPrices[product.id]?.lastPrice;

                  return ListTile(
                    onTap: () => Navigator.pop(context, product),
                    title: Text(product.name),
                    subtitle: Text(
                      remembered == null
                          ? 'ظ„ط§ ظٹظˆط¬ط¯ ط³ط¹ط± ط³ط§ط¨ظ‚ ظ„ظ‡ط°ط§ ط§ظ„ط¹ظ…ظٹظ„'
                          : 'ط¢ط®ط± ط³ط¹ط± ط³ط§ط¨ظ‚: ${remembered.toStringAsFixed(2)} ط¬.ظ…',
                    ),
                    trailing: Icon(
                      added
                          ? Icons.check_circle_outline
                          : Icons.add_circle_outline,
                      color: colors.primary,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}



============================================================
FILE: .\lib\features\customer-visits\customers\screens\invoice_detail_screen.dart
============================================================

import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mivet_app/features/rep_session/data/rep_session_store.dart';
import 'package:printing/printing.dart';

import '../../../invoices/domain/invoice_pdf_builder.dart';
import '../data/invoices_repository.dart';
import 'edit_invoice_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceCode;
  final String customerName;
  final double previousBalanceAtView;

  const InvoiceDetailScreen({
    super.key,
    required this.invoiceCode,
    required this.customerName,
    this.previousBalanceAtView = 0,
  });

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  InvoiceFullDetail? _detail;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await InvoicesRepository.instance
          .getInvoiceDetailByCode(widget.invoiceCode);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _editInvoice() async {
    final detail = _detail;
    if (detail == null) return;

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditInvoiceScreen(
          invoice: detail,
          customerName: widget.customerName,
          customerId: detail.customerId,
        ),
      ),
    );

    if (changed == true && mounted) {
      setState(() => _loading = true);
      await _load();
    }
  }

  Future<String> _resolveRepName() async {
    final activeRep = await RepSessionStore.instance.getActiveRep();
    final activeRepName = activeRep?.name.trim();
    if (activeRepName != null && activeRepName.isNotEmpty) {
      return activeRepName;
    }

    final signedInUserName = context.read<AuthCubit>().state.user?.name.trim();
    if (signedInUserName != null && signedInUserName.isNotEmpty) {
      return signedInUserName;
    }

    return '';
  }

  Future<Uint8List> _buildPdf(InvoiceFullDetail detail) async {
    final repName = await _resolveRepName();
    return InvoicePdfBuilder.build(
      InvoicePdfData(
        invoiceNumber: detail.code,
        date: detail.date,
        customerName: widget.customerName,
        repName: repName,
        items: detail.items
            .map(
              (i) => InvoicePdfLineItem(
                name: i.productName,
                quantity: i.quantity,
                price: i.unitPrice,
                total: i.lineTotal,
              ),
            )
            .toList(),
        invoiceTotal: detail.totalAmount,
        previousBalance: widget.previousBalanceAtView,
        totalDue: detail.totalAmount + widget.previousBalanceAtView,
        paidNow: detail.paidNow,
        remaining: detail.remaining,
      ),
    );
  }

  Future<void> _printPdf() async {
    final detail = _detail;
    if (detail == null) return;

    try {
      final bytes = await _buildPdf(detail);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  Future<void> _sharePdf() async {
    final detail = _detail;
    if (detail == null) return;

    try {
      final bytes = await _buildPdf(detail);
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${detail.code}.pdf',
      );
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              code: widget.invoiceCode,
              onBack: () => Navigator.of(context).pop(),
              onEdit: _detail == null ? null : _editInvoice,
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError || _detail == null
                      ? Center(
                          child: Text(
                            'طھط¹ط°ط± طھط­ظ…ظٹظ„ طھظپط§طµظٹظ„ ط§ظ„ظپط§طھظˆط±ط©',
                            style: AppTextStyles.almaraiRegular14.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                        )
                      : _DetailBody(detail: _detail!),
            ),
            if (!_loading && _detail != null)
              _FooterActions(
                onPrint: _printPdf,
                onShare: _sharePdf,
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String code;
  final VoidCallback onBack;
  final VoidCallback? onEdit;

  const _Header({
    required this.code,
    required this.onBack,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: colors.surface,
      padding: EdgeInsets.fromLTRB(8.w, 10.h, 12.w, 14.h),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(
              CupertinoIcons.back,
              color: colors.primary,
              size: 22.sp,
            ),
          ),
          Expanded(
            child: Text(
              'طھظپط§طµظٹظ„ ط§ظ„ظپط§طھظˆط±ط© $code',
              style: AppTextStyles.cairoBold18.copyWith(
                color: colors.primary,
                fontSize: 16.sp,
              ),
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: 'طھط¹ط¯ظٹظ„ ط§ظ„ظپط§طھظˆط±ط©',
            icon: Icon(
              Icons.edit_outlined,
              color: colors.primary,
              size: 21.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final InvoiceFullDetail detail;

  const _DetailBody({required this.detail});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      children: [
        _InfoCard(
          children: [
            _InfoRow(
              label: 'ط§ظ„طھط§ط±ظٹط®',
              value:
                  '${detail.date.year}/${detail.date.month.toString().padLeft(2, '0')}/${detail.date.day.toString().padLeft(2, '0')}',
            ),
            _InfoRow(
              label: 'ظ†ظˆط¹ ط§ظ„ط¨ظٹط¹',
              value: detail.saleType,
            ),
            _InfoRow(
              label: 'ط§ظ„ط­ط§ظ„ط©',
              value: detail.statusLabel,
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Text(
          'ط§ظ„ظ…ظ†طھط¬ط§طھ',
          style: AppTextStyles.cairoMedium16.copyWith(
            color: colors.text,
            fontSize: 13.sp,
          ),
        ),
        SizedBox(height: 8.h),
        for (final item in detail.items) _ItemRow(item: item),
        SizedBox(height: 16.h),
        _InfoCard(
          children: [
            _InfoRow(
              label: 'ط§ظ„ط¥ط¬ظ…ط§ظ„ظٹ ظ‚ط¨ظ„ ط§ظ„ط®طµظ…',
              value: '${detail.subtotal.toStringAsFixed(0)} ط¬.ظ…',
            ),
            if (detail.discountPercent > 0)
              _InfoRow(
                label: 'ط§ظ„ط®طµظ…',
                value: '${detail.discountPercent.toStringAsFixed(0)}%',
              ),
            _InfoRow(
              label: 'ط§ظ„ط¥ط¬ظ…ط§ظ„ظٹ',
              value: '${detail.totalAmount.toStringAsFixed(0)} ط¬.ظ…',
              highlight: true,
            ),
            _InfoRow(
              label: 'ط§ظ„ظ…ط¯ظپظˆط¹',
              value: '${detail.paidNow.toStringAsFixed(0)} ط¬.ظ…',
            ),
            _InfoRow(
              label: 'ط§ظ„ظ…طھط¨ظ‚ظٹ',
              value: '${detail.remaining.toStringAsFixed(0)} ط¬.ظ…',
            ),
          ],
        ),
        if (detail.notes != null && detail.notes!.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _InfoCard(
            children: [
              _InfoRow(
                label: 'ظ…ظ„ط§ط­ط¸ط§طھ',
                value: detail.notes!,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final InvoiceItemRow item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTextStyles.cairoMedium16.copyWith(
                    color: colors.text,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${item.quantity} أ— ${item.unitPrice.toStringAsFixed(0)} ط¬.ظ…',
                  style: AppTextStyles.almaraiRegular14.copyWith(
                    color: colors.textMuted,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item.lineTotal.toStringAsFixed(0)} ط¬.ظ…',
            style: AppTextStyles.cairoBold18.copyWith(
              color: colors.primary,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.almaraiRegular14.copyWith(
              color: colors.textMuted,
              fontSize: 12.sp,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.cairoMedium16.copyWith(
              color: highlight ? colors.primary : colors.text,
              fontSize: highlight ? 14.sp : 12.sp,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterActions extends StatelessWidget {
  final VoidCallback onPrint;
  final VoidCallback onShare;

  const _FooterActions({
    required this.onPrint,
    required this.onShare,
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
            child: OutlinedButton.icon(
              onPressed: onPrint,
              icon: Icon(Icons.print_outlined, size: 18.sp),
              label: const Text('ط·ط¨ط§ط¹ط©'),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onShare,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
              ),
              icon: const FaIcon(
                FontAwesomeIcons.whatsapp,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'ظ…ط´ط§ط±ظƒط© PDF',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



============================================================
FILE: .\lib\features\customer-visits\customers\screens\widgets\customer_detail\customer_products_section.dart
============================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../domain/models/customer_detail_model.dart';

String _formatDate(DateTime date) =>
    '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

final _skeletonProducts = [
  ProductPurchaseModel(
      name: 'ظ…ظ†طھط¬ طھط¬ط±ظٹط¨ظٹ', price: 100, lastPurchaseDate: DateTime.now()),
  ProductPurchaseModel(
      name: 'ظ…ظ†طھط¬ طھط¬ط±ظٹط¨ظٹ طھط§ظ†ظٹ', price: 100, lastPurchaseDate: DateTime.now()),
];

class CustomerTopProductsSection extends StatelessWidget {
  final List<ProductPurchaseModel> products;
  final bool isLoading;

  const CustomerTopProductsSection({
    super.key,
    required this.products,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final shown = isLoading ? _skeletonProducts : products;
    return _SectionCard(
      title: 'ط£ظƒطھط± ط§ظ„ظ…ظ†طھط¬ط§طھ ط´ط±ط§ط،ظ‹',
      icon: CupertinoIcons.star_fill,
      iconColor: context.colors.primary,
      child: (!isLoading && products.isEmpty)
          ? const _EmptySectionMessage(text: 'ظ„ط³ظ‡ ظ…ظپظٹط´ ظپظˆط§طھظٹط± ظ…ط³ط¬ظ„ط© ظ„ظ„ط¹ظ…ظٹظ„ ط¯ظ‡')
          : Skeletonizer(
              enabled: isLoading,
              child: Column(
                children: [
                  for (final product in shown)
                    _ProductRow(
                      name: product.name,
                      trailing: '${product.price.toStringAsFixed(0)} ط¬.ظ…',
                      subtitle:
                          'ط¢ط®ط± ط´ط±ط§ط، ${_formatDate(product.lastPurchaseDate)}',
                    ),
                ],
              ),
            ),
    );
  }
}

class CustomerNotBoughtSection extends StatelessWidget {
  final List<ProductPurchaseModel> products;
  final bool isLoading;

  const CustomerNotBoughtSection({
    super.key,
    required this.products,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final shown = isLoading ? _skeletonProducts : products;
    return _SectionCard(
      title: 'ظ…ظ†طھط¬ط§طھ ظ„ظ… ظٹط´طھط±ظ‡ط§ ظ…ظ† ظپطھط±ط©',
      icon: CupertinoIcons.exclamationmark_triangle_fill,
      iconColor: context.colors.statOrange,
      child: (!isLoading && products.isEmpty)
          ? const _EmptySectionMessage(text: 'ظ…ظپظٹط´ ظ…ظ†طھط¬ط§طھ ط¨ط·ظ‘ظ„ ظٹط´طھط±ظٹظ‡ط§ ظ…ظ† ظپطھط±ط©')
          : Skeletonizer(
              enabled: isLoading,
              child: Column(
                children: [
                  for (final product in shown)
                    _ProductRow(
                      name: product.name,
                      trailing: '${product.price.toStringAsFixed(0)} ط¬.ظ…',
                      subtitle:
                          'ط¢ط®ط± ط´ط±ط§ط، ${_formatDate(product.lastPurchaseDate)}',
                      showAddButton: true,
                    ),
                ],
              ),
            ),
    );
  }
}

class _EmptySectionMessage extends StatelessWidget {
  final String text;

  const _EmptySectionMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.almaraiRegular14.copyWith(
        color: context.colors.textMuted,
        fontSize: 11.sp,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

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
              Icon(icon, color: iconColor, size: 16.sp),
              SizedBox(width: 8.w),
              Text(title,
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.text, fontSize: 13.sp)),
            ],
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final String trailing;
  final bool showAddButton;

  const _ProductRow({
    required this.name,
    required this.subtitle,
    required this.trailing,
    this.showAddButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.cairoMedium16
                        .copyWith(color: colors.text, fontSize: 12.sp)),
                SizedBox(height: 2.h),
                Text(subtitle,
                    style: AppTextStyles.almaraiRegular14
                        .copyWith(color: colors.textMuted, fontSize: 10.sp)),
              ],
            ),
          ),
          Text(trailing,
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: colors.text, fontSize: 11.sp)),
          if (showAddButton) ...[
            SizedBox(width: 8.w),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(CupertinoIcons.add,
                    size: 14.sp, color: colors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}



============================================================
FILE: .\lib\features\customer-visits\customers\screens\widgets\customers_list_view\customer_list_tile.dart
============================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/models/customer_model.dart';
import '../../../domain/models/customer_status.dart';
import '../../customer_detail_screen.dart';
import 'customer_status_style.dart';

class CustomerListTile extends StatelessWidget {
  final CustomerModel customer;

  const CustomerListTile({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final color = customerStatusColor(context, customer.status);

    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(customer: customer)),
        ),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(CupertinoIcons.person_2_fill,
                    color: color, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: AppTextStyles.cairoMedium16.copyWith(
                        color: context.colors.text,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${customer.category} â€” ${customer.area}',
                      style: AppTextStyles.almaraiRegular14.copyWith(
                        color: context.colors.textMuted,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  customer.status.label,
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: color, fontSize: 10.sp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



============================================================
FILE: .\lib\features\customer-visits\customers\screens\widgets\route_view\route_visit_status_sheet.dart
============================================================

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../data/customers_repository.dart';
import '../../../domain/models/route_stop_model.dart';
import '../../../domain/models/visit_status.dart';
import '../../customer_detail_screen.dart';
import 'route_status_style.dart';

Future<void> showRouteStopActionsSheet(
  BuildContext context, {
  required RouteStopModel stop,
  required ValueChanged<RouteVisitStatus> onStatusChanged,
  required VoidCallback onRemove,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _RouteStopActionsSheet(
      stop: stop,
      onStatusChanged: onStatusChanged,
      onRemove: onRemove,
    ),
  );
}

class _RouteStopActionsSheet extends StatelessWidget {
  final RouteStopModel stop;
  final ValueChanged<RouteVisitStatus> onStatusChanged;
  final VoidCallback onRemove;

  const _RouteStopActionsSheet({
    required this.stop,
    required this.onStatusChanged,
    required this.onRemove,
  });

  static const _statuses = [
    RouteVisitStatus.pending,
    RouteVisitStatus.completed,
    RouteVisitStatus.sold,
    RouteVisitStatus.noOrder,
    RouteVisitStatus.notReached,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 42.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            stop.customerName,
            style: AppTextStyles.cairoBold18
                .copyWith(color: context.colors.text, fontSize: 16.sp),
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedLocation01,
                size: 12.sp,
                color: context.colors.textMuted,
              ),
              SizedBox(width: 4.w),
              Text(
                stop.area,
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: context.colors.textMuted, fontSize: 11.sp),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Text(
            'ط­ط§ظ„ط© ط§ظ„ط²ظٹط§ط±ط©',
            style: AppTextStyles.cairoMedium16
                .copyWith(color: context.colors.text, fontSize: 12.sp),
          ),
          SizedBox(height: 8.h),
          for (final status in _statuses)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _StatusOption(
                status: status,
                isSelected: stop.status == status,
                onTap: () {
                  onStatusChanged(status);
                  Navigator.of(context).pop();
                },
              ),
            ),
          SizedBox(height: 6.h),
          Material(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(14.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(14.r),
              onTap: () {
                final customer = CustomersRepository.instance
                    .getCustomerById(stop.customerId);
                Navigator.of(context).pop();
                if (customer == null || customer.id.isEmpty) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CustomerDetailScreen(customer: customer),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: context.colors.border),
                ),
                child: Text(
                  'ظپطھط­ ظ…ظ„ظپ ط§ظ„ط¹ظ…ظٹظ„ ط§ظ„ظƒط§ظ…ظ„',
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: context.colors.text, fontSize: 13.sp),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Material(
            color: context.colors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(14.r),
              onTap: () {
                onRemove();
                Navigator.of(context).pop();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                alignment: Alignment.center,
                child: Text(
                  'ط¥ط²ط§ظ„ط© ظ…ظ† ط®ط· ط§ظ„ظٹظˆظ…',
                  style: AppTextStyles.cairoMedium16.copyWith(
                      color: context.colors.statusNotReached, fontSize: 13.sp),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final RouteVisitStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusOption({
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = routeStatusColor(context, status);

    return Material(
      color: isSelected ? color.withOpacity(0.1) : context.colors.surface,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isSelected ? color : context.colors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20.w,
                height: 20.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.14),
                  border: Border.all(color: color, width: 1.4),
                ),
                child: isSelected
                    ? HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        size: 12.sp,
                        color: color,
                      )
                    : null,
              ),
              SizedBox(width: 10.w),
              Text(
                status.label,
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: context.colors.text, fontSize: 13.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



============================================================
FILE: .\lib\features\home\domain\models\quick_invoice_models.dart
============================================================

import 'package:mivet_app/features/customer-visits/customers/domain/models/customer_model.dart';

class InvoiceCustomerModel {
  final CustomerModel customer;

  final List<String> topPurchasedProducts;
  final List<String> notPurchasedRecently;

  const InvoiceCustomerModel({
    required this.customer,
    this.topPurchasedProducts = const [],
    this.notPurchasedRecently = const [],
  });

  /// Remaining credit the customer can still purchase on.
  double get availableCredit => (customer.creditLimit - customer.currentBalance)
      .clamp(0, customer.creditLimit);
}

class InvoiceProductModel {
  final String id;
  final String name;
  final double price;
  final String unit;

  const InvoiceProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.unit = 'ط¹ظ„ط¨ط©',
  });
}

class InvoiceLineItemModel {
  final InvoiceProductModel product;
  int quantity;
  double unitPrice;
  final double? previousCustomerPrice;

  InvoiceLineItemModel({
    required this.product,
    this.quantity = 1,
    required this.unitPrice,
    this.previousCustomerPrice,
  });

  double get total => unitPrice * quantity;
}

/// A single row inside the "ظƒط´ظپ ط­ط³ط§ط¨ - ط¢ط®ط± 6 ط´ظ‡ظˆط±" statement sheet.
class PastInvoiceSummaryModel {
  final String invoiceNumber;
  final DateTime date;
  final double total;
  final String status;

  const PastInvoiceSummaryModel({
    required this.invoiceNumber,
    required this.date,
    required this.total,
    required this.status,
  });
}

/// ظ…ط¹ظ„ظˆظ…ط§طھ ط§ظ„ظپط§طھظˆط±ط© ط¨ط¹ط¯ ط¥طµط¯ط§ط±ظ‡ط§ â€” ط¨طھط±ط¬ط¹ ط¹ظ† ط·ط±ظٹظ‚ onIssued ط¹ط´ط§ظ† ط£ظٹ
/// ط­ط¯ ظ…ط³طھط®ط¯ظ… ظ„ظ„ظ€ dialog ظٹظ‚ط¯ط± ظٹط­ط¯ظ‘ط« ط±طµظٹط¯ ط§ظ„ط¹ظ…ظٹظ„ ظˆظٹط³ط¬ظ„ ط§ظ„ظپط§طھظˆط±ط©.
class IssuedInvoiceInfo {
  final String invoiceNumber;
  final double amount;
  final String saleType;
  final DateTime date;

  const IssuedInvoiceInfo({
    required this.invoiceNumber,
    required this.amount,
    required this.saleType,
    required this.date,
  });
}



============================================================
FILE: .\lib\features\home\presentation\widgets\quick_invoice_dialog.dart
============================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../inventory/data/products_repository.dart';
import '../../../inventory/domain/models/product_model.dart';
import '../../../invoices/domain/invoice_pdf_builder.dart';
import '../../../invoices/domain/invoice_draft.dart';
import '../../domain/models/quick_invoice_models.dart';
import '../../../customer_account/domain/entities/payment_method.dart';
import '../../../customer_account/presentation/widgets/payment_method_selector.dart';

const _currentRepName = 'ط£ط­ظ…ط¯ ط¹ط¨ط¯ط§ظ„ظƒط±ظٹظ…';

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
  if (decimals > 0.005) {
    out += '.${(decimals * 100).round().toString().padLeft(2, '0')}';
  }
  return '${negative ? '-' : ''}$out ط¬.ظ…';
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
  String saleType = 'ط¢ط¬ظ„';

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
      _toast('ط§ظ„ط±ط¬ط§ط، ط§ط®طھظٹط§ط± ط§ظ„ط¹ظ…ظٹظ„ ط£ظˆظ„ط§ظ‹');
      return;
    }
    if (lineItems.isEmpty) {
      _toast('ط£ط¶ظپ ظ…ظ†طھط¬ط§طھ ظ„ظ„ظپط§طھظˆط±ط©');
      return;
    }
    final total = grandTotal;
    final isDeferredSale = saleType != 'ظ†ظ‚ط¯ظٹ';
    if (isDeferredSale && total > customer!.availableCredit) {
      _toast('ط§ظ„ط¹ظ…ظٹظ„ طھط¬ط§ظˆط² ط§ظ„ط­ط¯ ط§ظ„ط§ط¦طھظ…ط§ظ†ظٹ ط§ظ„ظ…ط³ظ…ظˆط­ ط¨ظ‡');
      return;
    }

    final paid = paidNow;
    if (paid < 0) {
      _toast('ط§ظ„ظ…ط¨ظ„ط؛ ط§ظ„ظ…ط¯ظپظˆط¹ ط؛ظٹط± طµط­ظٹط­');
      return;
    }
    if (!isDeferredSale && (paid - total).abs() > 0.01) {
      _toast('ط§ظ„ظ…ط¨ظ„ط؛ ط§ظ„ظ…ط¯ظپظˆط¹ ظپظٹ ط­ط§ظ„ط© ط§ظ„ط¯ظپط¹ ط§ظ„ظ†ظ‚ط¯ظٹ ظٹط¬ط¨ ط£ظ† ظٹط·ط§ط¨ظ‚ ط§ظ„ط¥ط¬ظ…ط§ظ„ظٹ');
      return;
    }
    if (isDeferredSale && paid > totalDue + 0.01) {
      _toast('ط§ظ„ظ…ط¨ظ„ط؛ ط§ظ„ظ…ط¯ظپظˆط¹ ظٹطھط¬ط§ظˆط² ط§ظ„ط±طµظٹط¯ ط§ظ„ظ…ط³طھط­ظ‚');
      return;
    }
    if (paid > 0 && _paymentMethod == null) {
      _toast('ط§ط®طھط± ط·ط±ظٹظ‚ط© ط§ظ„ط¯ظپط¹');
      return;
    }

    for (final item in lineItems) {
      if (item.product.name.trim().isEmpty ||
          item.quantity <= 0 ||
          item.unitPrice < 0) {
        _toast('ظٹط±ط¬ظ‰ ط§ظ„طھط­ظ‚ظ‚ ظ…ظ† ظƒظ…ظٹط© ظˆط³ط¹ط± ط¬ظ…ظٹط¹ ط§ظ„ظ…ظ†طھط¬ط§طھ');
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
      'طھظ… ط¥طµط¯ط§ط± ط§ظ„ظپط§طھظˆط±ط© ط¨ظ†ط¬ط§ط­: $invoiceNumber',
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _canBuildPdf() {
    if (customer == null) {
      _toast('ط§ظ„ط±ط¬ط§ط، ط§ط®طھظٹط§ط± ط§ظ„ط¹ظ…ظٹظ„');
      return false;
    }
    if (lineItems.isEmpty) {
      _toast('ط£ط¶ظپ ظ…ظ†طھط¬ط§طھ ظ„ظ„ظپط§طھظˆط±ط©');
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
                  'ط¥ظ†ط´ط§ط، ظپط§طھظˆط±ط© ط¬ط¯ظٹط¯ط©',
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
          'ط§ظ„ظ…ظ†ط¯ظˆط¨ ط§ظ„ط­ط§ظ„ظٹ: $name',
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
            icon: Icons.storefront_outlined, title: 'ط¨ظٹط§ظ†ط§طھ ط§ظ„ط¹ظ…ظٹظ„'),
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
                      'ط§ط®طھط± ط§ظ„ط¹ظ…ظٹظ„ ظ„ظ„ط¥طµط¯ط§ط± ط§ظ„ظپط§طھظˆط±ط©',
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
                'طھط؛ظٹظٹط±',
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
      title: 'ط§ط®طھط± ط§ظ„ط¹ظ…ظٹظ„',
      icon: Icons.storefront_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: (v) => setState(() => query = v),
            style: TextStyle(color: colors.text),
            decoration: InputDecoration(
              hintText: 'ط§ط¨ط­ط« ط¨ط§ط³ظ… ط§ظ„ط¹ظ…ظٹظ„...',
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
                  'ظ„ط§ ظٹظˆط¬ط¯ ط¹ظ…ظ„ط§ط، ظ…ط·ط§ط¨ظ‚ظٹظ† ظ„ظ„ط¨ط­ط«',
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
            icon: Icons.receipt_long_outlined, title: 'ط¨ظٹط§ظ†ط§طھ ط§ظ„ظپط§طھظˆط±ط©'),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _TappableField(
                label: 'ط§ظ„طھط§ط±ظٹط®',
                value: _date(date),
                icon: Icons.calendar_today_outlined,
                onTap: onPickDate,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _StaticField(
                label: 'ط±ظ‚ظ… ط§ظ„ظپط§طھظˆط±ط©',
                value: invoiceNumber,
                icon: Icons.tag_rounded,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Text(
          'ظ†ظˆط¹ ط§ظ„ط¨ظٹط¹',
          style: AppTextStyles.almaraiRegular14
              .copyWith(color: colors.textMuted, fontSize: 12.sp),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _SaleTypeOption(
                label: 'ظ†ظ‚ط¯ظٹ',
                icon: Icons.payments_outlined,
                selected: saleType == 'ظ†ظ‚ط¯ظٹ',
                onTap: () => onSaleTypeChanged('ظ†ظ‚ط¯ظٹ'),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _SaleTypeOption(
                label: 'ط¢ط¬ظ„',
                icon: Icons.schedule_outlined,
                selected: saleType == 'ط¢ط¬ظ„',
                onTap: () => onSaleTypeChanged('ط¢ط¬ظ„'),
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
            title: 'ط§ظ„ط­ط¯ ط§ظ„ط§ط¦طھظ…ط§ظ†ظٹ',
            value: _money(invoice.customer.creditLimit),
            icon: Icons.verified_user_outlined,
            color: colors.statBlue,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _FinancialCard(
            title: 'ط§ظ„ط±طµظٹط¯ ط§ظ„ط­ط§ظ„ظٹ',
            value: _money(invoice.customer.currentBalance),
            icon: Icons.account_balance_wallet_outlined,
            color: nearLimit ? colors.statusNotReached : colors.statOrange,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _FinancialCard(
            title: 'طھط§ط±ظٹط® ط¢ط®ط± ط³ط¯ط§ط¯',
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
                  'ظƒط´ظپ ط§ظ„ط­ط³ط§ط¨',
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
      title: 'ظƒط´ظپ ط­ط³ط§ط¨: ${invoice.customer.name}',
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
                        color: (e.status == 'ظ…ط¯ظپظˆط¹ط©'
                                ? colors.primary
                                : colors.statOrange)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        e.status,
                        style: AppTextStyles.almaraiRegular14.copyWith(
                          color: e.status == 'ظ…ط¯ظپظˆط¹ط©'
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
          title: 'ط§ظ„ط£طµظ†ط§ظپ (${items.length})',
          trailing: TextButton.icon(
            onPressed: onAdd,
            icon: Icon(Icons.add_circle_outline_rounded,
                size: 16.sp, color: colors.primary),
            label: Text(
              'ط¥ط¶ط§ظپط© ظ…ظ†طھط¬',
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
              'ظ„ط§ ظٹظˆط¬ط¯ ظ…ظ†طھط¬ط§طھ ظ…ط¶ط§ظپط© ظ„ظ„ظپط§طھظˆط±ط© ط­طھظ‰ ط§ظ„ط¢ظ†',
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
          _TotalsRow(label: 'ط§ظ„ط¥ط¬ظ…ط§ظ„ظٹ ظ‚ط¨ظ„ ط§ظ„ط®طµظ…', value: _money(subtotal)),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(
                'ط®طµظ… %',
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
              label: 'ظ‚ظٹظ…ط© ط§ظ„ط®طµظ…',
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
                  'ط¥ط¬ظ…ط§ظ„ظٹ ط§ظ„ظپط§طھظˆط±ط©',
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
            'ط§ظ„ط£طµظ†ط§ظپ $start - $end ظ…ظ† $itemCount',
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
                  child: const Text('ط§ظ„ط³ط§ط¨ظ‚'),
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
                  child: const Text('ط§ظ„طھط§ظ„ظٹ'),
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
                      ? 'ط³ط¹ط± ط§ظ„ط£ط³ط§ط³ظٹ: ${_money(item.product.price)}'
                      : 'ط§ظ„ط³ط¹ط± ط§ظ„ط³ط§ط¨ظ‚ ظ„ظ„ط¹ظ…ظٹظ„: ${_money(item.previousCustomerPrice!)}',
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
                      labelText: 'ط³ط¹ط± ط§ظ„ط¨ظٹط¹',
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
      title: 'ط¥ط¶ط§ظپط© ط£طµظ†ط§ظپ ظ„ظ„ظپط§طھظˆط±ط©',
      icon: Icons.inventory_2_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: (v) => setState(() => query = v),
            style: TextStyle(color: colors.text),
            decoration: InputDecoration(
              hintText: 'ط§ط¨ط­ط« ط¹ظ† ظ…ظ†طھط¬...',
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
                              child: Text('ط¥ط¶ط§ظپط©',
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
                'طھظ… (${cart.length} ط£طµظ†ط§ظپ)',
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
    final isCash = saleType == 'ظ†ظ‚ط¯ظٹ';

    final String? warning = isCash && (paid - invoiceTotal).abs() > 0.01
        ? 'ط§ظ„ظ…ط¨ظ„ط؛ ط§ظ„ظ…ط¯ظپظˆط¹ ظپظٹ ط­ط§ظ„ط© ط§ظ„ط¯ظپط¹ ط§ظ„ظ†ظ‚ط¯ظٹ ظٹط¬ط¨ ط£ظ† ظٹط·ط§ط¨ظ‚ ط¥ط¬ظ…ط§ظ„ظٹ ط§ظ„ظپط§طھظˆط±ط© (${_money(invoiceTotal)}) طھظ…ط§ظ…ط§ظ‹'
        : !isCash && paid > totalDue + 0.01
            ? 'ط§ظ„ظ…ط¨ظ„ط؛ ط§ظ„ظ…ط¯ظپظˆط¹ ظٹطھط¬ط§ظˆط² ط¥ط¬ظ…ط§ظ„ظٹ ط§ظ„ظ…ط³طھط­ظ‚ ط¹ظ„ظ‰ ط§ظ„ط¹ظ…ظٹظ„'
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          icon: Icons.account_balance_wallet_outlined,
          title: 'ظ…ظ„ط®طµ ط§ظ„ط­ط³ط§ط¨',
        ),
        SizedBox(height: 12.h),
        _TotalsRow(label: 'ظ‚ظٹظ…ط© ط§ظ„ظپط§طھظˆط±ط© ط§ظ„ط­ط§ظ„ظٹط©', value: _money(invoiceTotal)),
        SizedBox(height: 8.h),
        _TotalsRow(label: 'ط­ط³ط§ط¨ ط³ط§ط¨ظ‚', value: _money(previousBalance)),
        SizedBox(height: 10.h),
        Divider(height: 1, color: colors.border),
        SizedBox(height: 10.h),
        _TotalsRow(label: 'ط¥ط¬ظ…ط§ظ„ظٹ ط§ظ„ظ…ط³طھط­ظ‚ ط¹ظ„ظ‰ ط§ظ„ط¹ظ…ظٹظ„', value: _money(totalDue)),
        SizedBox(height: 14.h),
        Row(
          children: [
            Text('ط§ظ„ظ…ط¯ظپظˆط¹ ط§ظ„ط¢ظ†',
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: colors.textMuted, fontSize: 12.sp)),
            if (isCash) ...[
              SizedBox(width: 8.w),
              Text('(ظ†ظ‚ط¯ظٹ - ظ…ظ„ط²ظ… ط¨طھط³ط¯ظٹط¯ ظƒط§ظ…ظ„ ط§ظ„ظپط§طھظˆط±ط©)',
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
                    child: Text('طھط¹ط¨ط¦ط© ظƒط§ظ…ظ„ط©',
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
              Text('ط§ظ„ظ…طھط¨ظ‚ظٹ ط¹ظ„ظ‰ ط§ظ„ط¹ظ…ظٹظ„',
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
            icon: Icons.edit_note_rounded, title: 'ظ…ظ„ط§ط­ط¸ط§طھ ط¥ط¶ط§ظپظٹط©'),
        SizedBox(height: 10.h),
        TextField(
          controller: controller,
          maxLines: 3,
          style: TextStyle(color: colors.text),
          decoration: InputDecoration(
            hintText: 'ط§ظƒطھط¨ ظ…ظ„ط§ط­ط¸ط§طھظƒ ط¹ظ„ظ‰ ط§ظ„ط²ظٹط§ط±ط© ط£ظˆ ط§ظ„ظپط§طھظˆط±ط©...',
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
              icon: Icons.insights_rounded, title: 'طھط­ظ„ظٹظ„ ط§ظ„ظ…ط´طھط±ظٹط§طھ ظ„ظ„ط¹ظ…ظٹظ„'),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (customer.topPurchasedProducts.isNotEmpty)
                Expanded(
                  child: _InsightBadge(
                    title: 'ط£ظƒط«ط± ط§ظ„ظ…ظ†طھط¬ط§طھ ط´ط±ط§ط،ظ‹',
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
                    title: 'ظ„ظ… ظٹط´طھط±ظٹظ‡ط§ ظ…ظ†ط° ظپطھط±ط©',
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
                isIssuing ? 'ط¬ط§ط±ظٹ ط§ظ„ط¥طµط¯ط§ط±...' : 'ط­ظپط¸ ظˆط¥طµط¯ط§ط± ط§ظ„ظپط§طھظˆط±ط©',
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



============================================================
FILE: .\lib\features\inventory\domain\mock_stock_adjustments_repository.dart
============================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/stock_adjustment_model.dart';

class MockStockAdjustmentsRepository {
  MockStockAdjustmentsRepository._();

  static final MockStockAdjustmentsRepository instance =
      MockStockAdjustmentsRepository._();

  static const _storageKey = 'inventory_stock_adjustments';

  final ValueNotifier<List<StockAdjustmentModel>> adjustmentsNotifier =
      ValueNotifier<List<StockAdjustmentModel>>([]);

  bool _initialized = false;

  List<StockAdjustmentModel> get adjustments => adjustmentsNotifier.value;

  Future<void> initialize() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const [];
    adjustmentsNotifier.value = raw
        .map((e) => StockAdjustmentModel.fromJson(
            jsonDecode(e) as Map<String, dynamic>))
        .toList();
    _initialized = true;
  }

  Future<void> recordReturn({
    required String productId,
    required String productName,
    required int quantity,
    required double unitPrice,
    String? note,
  }) =>
      _record(StockAdjustmentType.returned, productId, productName, quantity,
          unitPrice, note);

  Future<void> recordDamage({
    required String productId,
    required String productName,
    required int quantity,
    required double unitPrice,
    String? note,
  }) =>
      _record(StockAdjustmentType.damaged, productId, productName, quantity,
          unitPrice, note);

  Future<void> _record(
    StockAdjustmentType type,
    String productId,
    String productName,
    int quantity,
    double unitPrice,
    String? note,
  ) async {
    await initialize();
    final entry = StockAdjustmentModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      productId: productId,
      productName: productName,
      type: type,
      quantity: quantity,
      value: quantity * unitPrice,
      createdAt: DateTime.now(),
      note: note,
    );
    adjustmentsNotifier.value = [entry, ...adjustments];
    await _persist();
  }

  List<StockAdjustmentModel> inRange(
    DateTime start,
    DateTime end, {
    StockAdjustmentType? type,
  }) {
    return adjustments.where((a) {
      final matchesType = type == null || a.type == type;
      return matchesType &&
          !a.createdAt.isBefore(start) &&
          a.createdAt.isBefore(end);
    }).toList();
  }

  double totalValueInRange(
      DateTime start, DateTime end, StockAdjustmentType type) {
    return inRange(start, end, type: type).fold(0.0, (sum, a) => sum + a.value);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      adjustments.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }
}



============================================================
FILE: .\lib\features\invoices\domain\invoice_draft.dart
============================================================

// import '../../inventory/domain/models/product_model.dart';

// class CustomerProductPrice {
//   final String customerId;
//   final String productId;
//   final double lastPrice;

//   const CustomerProductPrice({
//     required this.customerId,
//     required this.productId,
//     required this.lastPrice,
//   });

//   factory CustomerProductPrice.fromJson(Map<String, dynamic> json) {
//     return CustomerProductPrice(
//       customerId: json['customer_id'] as String? ?? '',
//       productId: json['product_id'] as String? ?? '',
//       lastPrice: (json['last_price'] as num?)?.toDouble() ?? 0,
//     );
//   }
// }

// class InvoiceItemDraft {
//   final String? invoiceItemId;
//   final ProductModel product;
//   int quantity;
//   double unitPrice;
//   final double? previousCustomerPrice;

//   InvoiceItemDraft({
//     required this.product,
//     this.quantity = 1,
//     required this.unitPrice,
//     this.invoiceItemId,
//     this.previousCustomerPrice,
//   });

//   double get total => unitPrice * quantity;

//   Map<String, dynamic> toRpcJson() => {
//         if (invoiceItemId != null) 'invoice_item_id': invoiceItemId,
//         'product_id': product.id,
//         'product_name': product.name,
//         'unit_price': unitPrice,
//         'quantity': quantity,
//       };
// }

// class InvoiceDraft {
//   static const itemsPerPage = 15;

//   final List<InvoiceItemDraft> items = [];

//   int get pageCount => items.isEmpty ? 1 : (items.length / itemsPerPage).ceil();

//   List<InvoiceItemDraft> itemsForPage(int page) {
//     final start = (page - 1) * itemsPerPage;
//     if (start >= items.length) return const [];
//     final end = (start + itemsPerPage).clamp(0, items.length);
//     return items.sublist(start, end);
//   }

//   void remove(InvoiceItemDraft item) => items.remove(item);
// }

// double suggestedPrice(
//   ProductModel product,
//   Map<String, CustomerProductPrice> prices,
// ) {
//   return prices[product.id]?.lastPrice ?? product.basePrice;
// }

import '../../inventory/domain/models/product_model.dart';

class CustomerProductPrice {
  final String customerId;
  final String productId;
  final double lastPrice;

  const CustomerProductPrice({
    required this.customerId,
    required this.productId,
    required this.lastPrice,
  });

  factory CustomerProductPrice.fromJson(Map<String, dynamic> json) {
    return CustomerProductPrice(
      customerId: json['customer_id'] as String,
      productId: json['product_id'] as String,
      lastPrice: (json['last_price'] as num).toDouble(),
    );
  }
}

class InvoiceItemDraft {
  final String? invoiceItemId;
  final String? productId;
  final ProductModel product;
  int quantity;
  double unitPrice;
  final double? previousCustomerPrice;

  InvoiceItemDraft({
    required this.product,
    this.productId,
    this.invoiceItemId,
    this.quantity = 1,
    required this.unitPrice,
    this.previousCustomerPrice,
  });

  double get total => unitPrice * quantity;

  Map<String, dynamic> toRpcJson() {
    final json = <String, dynamic>{
      if (invoiceItemId != null) 'invoice_item_id': invoiceItemId,
      'product_name': product.name,
      'unit_price': unitPrice,
      'quantity': quantity,
    };

    if (productId != null && productId!.isNotEmpty) {
      json['product_id'] = productId;
    }

    return json;
  }
}

class InvoiceDraft {
  static const int itemsPerPage = 15;

  final List<InvoiceItemDraft> items = [];

  int get pageCount => items.isEmpty ? 1 : (items.length / itemsPerPage).ceil();

  List<InvoiceItemDraft> itemsForPage(int page) {
    if (page < 1) return [];

    final start = (page - 1) * itemsPerPage;
    if (start >= items.length) return [];

    final end = (start + itemsPerPage).clamp(0, items.length);
    return items.sublist(start, end);
  }

  void remove(InvoiceItemDraft item) {
    items.remove(item);
  }
}

double suggestedPrice(
  ProductModel product,
  Map<String, CustomerProductPrice> prices,
) {
  return prices[product.id]?.lastPrice ?? product.basePrice;
}



============================================================
FILE: .\test\customer_account_financial_harness_test.dart
============================================================

import 'dart:io';

import 'package:mivet_app/features/customer-visits/customers/domain/models/invoice_line_input.dart';
import 'package:mivet_app/features/customer-visits/customers/domain/models/invoice_record_model.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

const _testEmail = 'owner@mivet.com';
const _testPassword = 'Owner@2024';

late SupabaseClient _client;
final _harnessFailures = <String>[];

void main() {
  setUpAll(() async {
    final env = _readEnv();
    _client =
        SupabaseClient(env['SUPABASE_URL']!, env['SUPABASE_PUBLISHABLE_KEY']!);
    await _client.auth.signInWithPassword(
      email: _testEmail,
      password: _testPassword,
    );
  });

  tearDownAll(() async {
    await _client.auth.signOut();
  });

  test('financial harness: cases 3-17', () async {
    _harnessFailures.clear();
    await _runCase(3, () async {
      final customer = await _newCustomer(3);
      await _issue(customer, amount: 1000, quantity: 1, paidNow: 400);
      await _expectBalance(customer, 600);
    });

    await _runCase(4, () async {
      final customer = await _newCustomer(4);
      await _issue(customer, amount: 1000, quantity: 1);
      await _pay(customer, 300);
      await _pay(customer, 200);
      final ledger = await _ledger(customer);
      expect(_typesAscending(ledger), [
        'invoice',
        'payment',
        'payment',
      ]);
      await _expectBalance(customer, 500);
    });

    await _runCase(5, () async {
      final customer = await _newCustomer(5);
      final invoice = await _issue(customer, amount: 100, quantity: 10);
      final item = (await _invoiceItems(invoice.id)).single;
      await _return(customer, invoice.id, {item['id'] as String: 3});
      await _expectBalance(customer, 700);
    });

    await _runCase(6, () async {
      final customer = await _newCustomer(6);
      final invoice = await _issue(
        customer,
        amount: 100,
        quantity: 10,
        paidNow: 1000,
      );
      final item = (await _invoiceItems(invoice.id)).single;
      await _return(customer, invoice.id, {item['id'] as String: 3});
      await _expectBalance(customer, -300);
    });

    await _runCase(7, () async {
      final customer = await _newCustomer(7);
      final invoice = await _issue(
        customer,
        amount: 100,
        quantity: 10,
        paidNow: 1000,
      );
      final item = (await _invoiceItems(invoice.id)).single;
      await _return(customer, invoice.id, {item['id'] as String: 10});
      await _expectBalance(customer, -1000);
    });

    await _runCase(8, () async {
      final customer = await _newCustomer(8);
      final invoice = await _issue(customer, amount: 100, quantity: 2);
      final item = (await _invoiceItems(invoice.id)).single;
      final before = await _returnIds(invoice.id);
      final ledgerBefore = await _ledger(customer);
      await _expectRejected(() => _return(
            customer,
            invoice.id,
            {item['id'] as String: 3},
          ));
      expect(await _returnIds(invoice.id), before);
      expect(_ledgerIds(await _ledger(customer)), _ledgerIds(ledgerBefore));
      await _expectBalance(customer, 200);
    });

    await _runCase(9, () async {
      final customer = await _newCustomer(9);
      final invoice = await _issue(customer, amount: 100, quantity: 5);
      final item = (await _invoiceItems(invoice.id)).single;
      final itemId = item['id'] as String;
      await _return(customer, invoice.id, {itemId: 2});
      expect(await _returnedQuantity(invoice.id, itemId), 2);
      await _return(customer, invoice.id, {itemId: 2});
      expect(await _returnedQuantity(invoice.id, itemId), 4);
      await _expectRejected(() => _return(customer, invoice.id, {itemId: 2}));
      expect(await _returnedQuantity(invoice.id, itemId), 4);
      await _expectBalance(customer, 100);
    });

    await _runCase(10, () async {
      final customer = await _newCustomer(10);
      final invoice = await _issue(
        customer,
        lines: const [
          InvoiceLineInput(
            productId: null,
            productName: 'Product A',
            unitPrice: 100,
            quantity: 5,
          ),
          InvoiceLineInput(
            productId: null,
            productName: 'Product B',
            unitPrice: 200,
            quantity: 3,
          ),
        ],
      );
      final items = await _invoiceItems(invoice.id);
      await _return(customer, invoice.id, {
        items[0]['id'] as String: 2,
        items[1]['id'] as String: 1,
      });
      final returnRow = await _latestReturn(invoice.id);
      expect((returnRow['total_amount'] as num).toDouble(), 400);
      await _expectBalance(customer, 700);
    });

    await _runCase(11, () async {
      final customer = await _newCustomer(11);
      final invoice = await _issue(
        customer,
        discountPercent: 10,
        lines: const [
          InvoiceLineInput(
            productId: null,
            productName: 'Product A',
            unitPrice: 100,
            quantity: 5,
          ),
          InvoiceLineInput(
            productId: null,
            productName: 'Product B',
            unitPrice: 200,
            quantity: 3,
          ),
        ],
      );
      final items = await _invoiceItems(invoice.id);
      await _return(customer, invoice.id, {items[0]['id'] as String: 2});
      const uiTotal = 2 * 100 * (1 - 10 / 100);
      final dbTotal =
          ((await _latestReturn(invoice.id))['total_amount'] as num).toDouble();
      expect(dbTotal, uiTotal);
    });

    await _runCase(12, () async {
      final customer = await _newCustomer(12);
      await _issue(customer, amount: 1000, quantity: 1, paidNow: 1200);
      await _expectBalance(customer, -200);
    });

    await _runCase(13, () async {
      final customer = await _newCustomer(13);
      final invoice = await _issue(customer, amount: 100, quantity: 15);
      await _pay(customer, 500);
      final item = (await _invoiceItems(invoice.id)).single;
      await _return(customer, invoice.id, {item['id'] as String: 2});
      await _expectBalance(customer, 800);
    });

    await _runCase(14, () async {
      final customer = await _newCustomer(14);
      final invoice = await _issue(customer, amount: 100, quantity: 15);
      await _pay(customer, 500);
      await _pay(customer, 300);
      final item = (await _invoiceItems(invoice.id)).single;
      await _return(customer, invoice.id, {item['id'] as String: 2});
      await _expectBalance(customer, 500);
    });

    await _runCase(15, () async {
      final customer = await _newCustomer(15);
      final invoice = await _issue(
        customer,
        amount: 1000,
        quantity: 1,
        paidNow: 1000,
      );
      final item = (await _invoiceItems(invoice.id)).single;
      final before = await _ledger(customer);
      await _expectRejected(() => _return(
            customer,
            invoice.id,
            {item['id'] as String: 2},
          ));
      expect(_ledgerIds(await _ledger(customer)), _ledgerIds(before));
      expect(await _returnIds(invoice.id), isEmpty);
      await _expectBalance(customer, 0);
    });

    await _runCase(16, () async {
      final customer = await _newCustomer(16);
      final invoice = await _issue(customer, amount: 1500, quantity: 15);
      await _pay(customer, 500);
      await _pay(customer, 300);
      final item = (await _invoiceItems(invoice.id)).single;
      await _return(customer, invoice.id, {item['id'] as String: 2});
      final types = _typesAscending(await _ledger(customer));
      expect(types, ['invoice', 'payment', 'payment', 'sales_return']);
    });

    await _runCase(17, () async {
      final customer = await _newCustomer(17);
      final invoice = await _issue(customer, amount: 1000, quantity: 10);
      await _pay(customer, 100);
      final item = (await _invoiceItems(invoice.id)).single;
      await _return(customer, invoice.id, {item['id'] as String: 1});
      final ledger = await _ledger(customer);
      final codes = ledger
          .map((row) => row['reference_code'] as String)
          .toList(growable: false);
      expect(codes.where((code) => code.startsWith('INV-')), hasLength(1));
      expect(codes.where((code) => code.startsWith('PAY-')), hasLength(1));
      expect(codes.where((code) => code.startsWith('RET-')), hasLength(1));
      expect(codes.toSet(), hasLength(codes.length));
    });

    expect(_harnessFailures, isEmpty);
  });

  test('financial harness: cases 19-20 database verification', () async {
    _harnessFailures.clear();
    await _runCase(19, () async {
      final customer = await _newCustomer(19);
      final invoice = await _issue(customer, amount: 100, quantity: 1);
      final item = (await _invoiceItems(invoice.id)).single;
      await _return(customer, invoice.id, {item['id'] as String: 1});
      final ledger = await _ledger(customer);
      expect(_typesAscending(ledger), ['invoice', 'sales_return']);
      await _expectBalance(customer, 0);
    });

    await _runCase(20, () async {
      final customer = await _newCustomer(20);
      final invoice = await _issue(customer, amount: 100, quantity: 1);
      final item = (await _invoiceItems(invoice.id)).single;
      final itemId = item['id'] as String;
      await _return(customer, invoice.id, {itemId: 1});
      expect(await _returnedQuantity(invoice.id, itemId), 1);
      final returned = await _returnedQuantities(invoice.id);
      expect(returned[itemId], 1);
      expect((item['quantity'] as num).toInt() - returned[itemId]!, 0);
    });

    expect(_harnessFailures, isEmpty);
  });
}

Future<void> _runCase(int number, Future<void> Function() body) async {
  try {
    await body();
    stdout.writeln('CASE $number | PASS');
  } catch (error, stackTrace) {
    stderr.writeln('CASE $number | FAIL | $error');
    stderr.writeln(stackTrace);
    _harnessFailures.add('CASE $number | $error');
  }
}

Future<Map<String, dynamic>> _newCustomer(int caseNumber) async {
  final rows = await _client
      .from('customers')
      .insert({
        'name':
            'HARNESS-CASE-$caseNumber-${DateTime.now().microsecondsSinceEpoch}',
        'area': 'TEST',
        'category': 'TEST',
        'status': 'active',
        'phone': '',
        'address': '',
        'notes': 'Financial test harness case $caseNumber',
        'credit_limit': 0,
        'current_balance': 0,
      })
      .select('id')
      .single();
  return rows;
}

Future<InvoiceRecordModel> _issue(
  Map<String, dynamic> customer, {
  double? amount,
  int? quantity,
  List<InvoiceLineInput>? lines,
  double discountPercent = 0,
  double paidNow = 0,
}) {
  final invoiceLines = lines ??
      [
        InvoiceLineInput(
          productId: null,
          productName: 'Harness Product',
          unitPrice: amount!,
          quantity: quantity!,
        ),
      ];
  return _client.rpc('issue_invoice', params: {
    'p_customer_id': customer['id'],
    'p_items': invoiceLines.map((item) => item.toRpcJson()).toList(),
    'p_discount_percent': discountPercent,
    'p_sale_type': 'credit',
    'p_paid_now': paidNow,
    'p_notes': 'Financial test harness',
  }).then((row) => InvoiceRecordModel.fromSupabaseRow(
        row as Map<String, dynamic>,
      ));
}

Future<void> _pay(Map<String, dynamic> customer, double amount) async {
  await _client.rpc('record_customer_payment', params: {
    'p_customer_id': customer['id'],
    'p_amount': amount,
    'p_invoice_id': null,
    'p_source': 'old_debt_payment',
    'p_notes': 'Financial test harness',
  });
}

Future<void> _return(
  Map<String, dynamic> customer,
  String invoiceId,
  Map<String, int> items,
) {
  return _client.rpc('create_sales_return', params: {
    'p_customer_id': customer['id'],
    'p_invoice_id': invoiceId,
    'p_items': items.entries
        .map((entry) => {
              'invoice_item_id': entry.key,
              'quantity': entry.value,
            })
        .toList(),
    'p_reason': 'Financial test harness',
    'p_notes': null,
  });
}

Future<List<Map<String, dynamic>>> _invoiceItems(String invoiceId) async {
  final rows = await _client
      .from('invoice_items')
      .select('id, quantity, unit_price, product_name')
      .eq('invoice_id', invoiceId);
  return (rows as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();
}

Future<List<dynamic>> _ledger(Map<String, dynamic> customer) {
  return _client.rpc('get_customer_ledger', params: {
    'p_customer_id': customer['id'],
    'p_from': null,
    'p_to': null,
  });
}

Future<void> _expectBalance(
  Map<String, dynamic> customer,
  double expected,
) async {
  final rows = await _ledger(customer);
  expect(rows, isNotEmpty);
  final chronological = rows
      .map((row) => Map<String, dynamic>.from(row))
      .toList()
    ..sort((a, b) =>
        (a['occurred_at'] as String).compareTo(b['occurred_at'] as String));
  expect((chronological.last['balance_after'] as num).toDouble(), expected);
}

Future<List<String>> _returnIds(String invoiceId) async {
  final rows = await _client
      .from('sales_returns')
      .select('id')
      .eq('invoice_id', invoiceId);
  return (rows as List).map((row) => row['id'] as String).toList();
}

Future<Map<String, dynamic>> _latestReturn(String invoiceId) async {
  final row = await _client
      .from('sales_returns')
      .select('id, total_amount, code')
      .eq('invoice_id', invoiceId)
      .order('created_at', ascending: false)
      .limit(1)
      .single();
  return Map<String, dynamic>.from(row);
}

Future<int> _returnedQuantity(String invoiceId, String itemId) async {
  final quantities = await _returnedQuantities(invoiceId);
  return quantities[itemId] ?? 0;
}

Future<Map<String, int>> _returnedQuantities(String invoiceId) async {
  final rows = await _client
      .from('sales_returns')
      .select('id, sales_return_items(invoice_item_id, quantity)')
      .eq('invoice_id', invoiceId);
  final result = <String, int>{};
  for (final row in rows as List) {
    for (final item in (row['sales_return_items'] as List? ?? const [])) {
      final itemId = item['invoice_item_id'] as String;
      result[itemId] =
          (result[itemId] ?? 0) + (item['quantity'] as num).toInt();
    }
  }
  return result;
}

Future<void> _expectRejected(Future<void> Function() operation) async {
  var rejected = false;
  try {
    await operation();
  } on PostgrestException {
    rejected = true;
  }
  expect(rejected, isTrue);
}

List<String> _typesAscending(List<dynamic> rows) {
  final copy = rows.map((row) => Map<String, dynamic>.from(row)).toList();
  copy.sort((a, b) =>
      (a['occurred_at'] as String).compareTo(b['occurred_at'] as String));
  return copy.map((row) => row['transaction_type'] as String).toList();
}

List<String> _ledgerIds(List<dynamic> rows) =>
    rows.map((row) => row['id'] as String).toList()..sort();

Map<String, String> _readEnv() {
  final values = <String, String>{};
  for (final line in File('.env').readAsLinesSync()) {
    final separator = line.indexOf('=');
    if (separator <= 0) continue;
    values[line.substring(0, separator)] = line.substring(separator + 1);
  }
  return values;
}



============================================================
FILE: .\test\invoice_draft_test.dart
============================================================

import 'package:mivet_app/features/inventory/domain/models/product_model.dart';
import 'package:mivet_app/features/invoices/domain/invoice_draft.dart';
import 'package:test/test.dart';

void main() {
  final product = ProductModel(
    id: 'product-1',
    name: 'Vitamin X',
    category: 'poultry',
    unit: 'piece',
    retailPrice: 200,
    wholesalePrice: 200,
    minStockThreshold: 1,
    createdAt: DateTime(2024),
  );

  test("uses the customer's previous price when available", () {
    final price = suggestedPrice(product, {
      product.id: const CustomerProductPrice(
        customerId: 'customer-1',
        productId: 'product-1',
        lastPrice: 175,
      ),
    });

    expect(price, 175);
  });

  test('falls back to the product base price', () {
    expect(suggestedPrice(product, {}), 200);
  });

  test('manual price and quantity are represented in the draft item', () {
    final item =
        InvoiceItemDraft(product: product, unitPrice: 180, quantity: 2);

    expect(item.total, 360);
    expect(item.toRpcJson()['unit_price'], 180);
  });

  test('paginates at most 15 items and preserves edited items', () {
    final draft = InvoiceDraft();
    for (var index = 0; index < 31; index++) {
      draft.items.add(InvoiceItemDraft(product: product, unitPrice: 200));
    }
    draft.items[16].unitPrice = 180;

    expect(draft.pageCount, 3);
    expect(draft.itemsForPage(1), hasLength(15));
    expect(draft.itemsForPage(2), hasLength(15));
    expect(draft.itemsForPage(3), hasLength(1));
    expect(draft.itemsForPage(2)[1].unitPrice, 180);
  });

  test('deleting items changes page count without changing remaining data', () {
    final draft = InvoiceDraft();
    for (var index = 0; index < 16; index++) {
      draft.items
          .add(InvoiceItemDraft(product: product, unitPrice: index.toDouble()));
    }

    final removed = draft.items[15];
    draft.remove(removed);

    expect(draft.pageCount, 1);
    expect(draft.items.first.unitPrice, 0);
  });
}



============================================================
FILE: .\test\invoice_line_input_test.dart
============================================================

import 'package:mivet_app/features/customer-visits/customers/domain/models/invoice_line_input.dart';
import 'package:test/test.dart';

void main() {
  test('preserves the real product id in the invoice payload', () {
    const input = InvoiceLineInput(
      productId: '2d931510-8f9c-4b91-8cb8-3c7b3a1e7a10',
      productName: 'Vitamin X',
      unitPrice: 150,
      quantity: 2,
    );

    expect(input.toRpcJson()['product_id'], input.productId);
  });

  test('omits product id only for an explicitly id-less legacy line', () {
    const input = InvoiceLineInput(
      productId: null,
      productName: 'Legacy item',
      unitPrice: 10,
      quantity: 1,
    );

    expect(input.toRpcJson().containsKey('product_id'), isFalse);
  });
}


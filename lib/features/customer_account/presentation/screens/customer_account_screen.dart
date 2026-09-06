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
          listenWhen: (p, c) => p.actionStatus != c.actionStatus,
          listener: (context, state) {
            final cubit = context.read<CustomerAccountCubit>();

            if (state.actionStatus == CustomerAccountActionStatus.success &&
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
                          'حركة الحساب',
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
              'الحساب والمعاملات — $customerName',
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
            onPressed: () => showPaymentDialog(context),
            child: const Text('تحصيل'),
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
            child: const Text('مرتجع مبيعات'),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _openNewInvoice(context),
            child: const Text('فاتورة جديدة'),
          ),
        ),
      ],
    );
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

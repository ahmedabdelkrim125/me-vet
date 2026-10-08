import 'package:mivet_app/core/utils/months_before.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_breakdown.dart';
import 'package:mivet_app/features/customer_account/presentation/models/statement_entry.dart';
import 'package:mivet_app/features/invoices/domain/models/invoice_record_model.dart';

class CustomerInvoicesState {
  static const int recentMonths = 6;

  final bool loading;
  final bool showAll;
  final List<InvoiceRecordModel> invoices;
  final List<PaymentBreakdown> payments;
  final Map<String, String?> collectionSources;
  final Object? error;

  const CustomerInvoicesState({
    this.loading = true,
    this.showAll = false,
    this.invoices = const [],
    this.payments = const [],
    this.collectionSources = const {},
    this.error,
  });

  DateTime get _since => monthsBefore(DateTime.now(), recentMonths);

  List<InvoiceRecordModel> get visibleInvoices {
    if (showAll) return invoices;
    final since = _since;
    return invoices.where((invoice) => !invoice.date.isBefore(since)).toList();
  }

  List<PaymentBreakdown> get visiblePayments {
    final since = _since;
    return payments.where((payment) {
      final worthARow =
          payment.ownInvoiceLines.isEmpty && payment.oldDebtLines.isNotEmpty;
      if (!worthARow) return false;
      return showAll || !payment.collectedAt.toLocal().isBefore(since);
    }).toList();
  }

  Map<String, double> get oldDebtByInvoiceCode {
    final map = <String, double>{};
    for (final payment in payments) {
      final code = payment.ownInvoiceCode;
      if (code == null) continue;
      final oldDebt =
          payment.oldDebtLines.fold(0.0, (sum, line) => sum + line.amount);
      if (oldDebt > 0) map[code] = oldDebt;
    }
    return map;
  }

  Map<String, List<StatementEntry>> get groups =>
      groupStatementByMonth(visibleInvoices, visiblePayments);

  CustomerInvoicesState copyWith({
    bool? loading,
    bool? showAll,
    List<InvoiceRecordModel>? invoices,
    List<PaymentBreakdown>? payments,
    Map<String, String?>? collectionSources,
    Object? error,
  }) {
    return CustomerInvoicesState(
      loading: loading ?? this.loading,
      showAll: showAll ?? this.showAll,
      invoices: invoices ?? this.invoices,
      payments: payments ?? this.payments,
      collectionSources: collectionSources ?? this.collectionSources,
      error: error,
    );
  }
}

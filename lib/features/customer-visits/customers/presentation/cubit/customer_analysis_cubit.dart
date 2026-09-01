import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/invoices_repository.dart';
import '../../domain/models/customer_detail_model.dart';
import 'customer_analysis_state.dart';

class CustomerAnalysisCubit extends Cubit<CustomerAnalysisState> {
  CustomerAnalysisCubit(this._customerId)
      : super(const CustomerAnalysisState());

  final String _customerId;

  static const int _notBoughtThresholdDays = 45;

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true));
    try {
      final stats = await InvoicesRepository.instance
          .getProductStatsForCustomer(_customerId);
      final invoices = await InvoicesRepository.instance
          .getInvoicesForCustomer(_customerId, since: _sixMonthsAgo());
      final allInvoices = await InvoicesRepository.instance
          .getInvoicesForCustomer(_customerId);

      final now = DateTime.now();
      final sorted = [...stats]
        ..sort((a, b) => b.timesPurchased.compareTo(a.timesPurchased));

      final top = sorted
          .take(5)
          .map((s) => ProductPurchaseModel(
                name: s.productName,
                price: s.lastPrice,
                lastPurchaseDate: s.lastPurchaseDate,
              ))
          .toList();

      final notBought = stats
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

  InvoiceSummaryModel _toSummary(invoice) {
    return InvoiceSummaryModel(
      code: invoice.code,
      date: invoice.date,
      amount: invoice.amount,
      status: invoice.status.label,
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/invoices_repository.dart';
import '../../domain/models/customer_detail_model.dart';
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
      ));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false));
    }
  }
}

import 'package:mivet_app/features/invoices/data/invoices_repository.dart';

enum DailyInvoicesStatus { loading, loaded, failure }

class DailyInvoicesState {
  final DailyInvoicesStatus status;
  final List<DailyInvoiceSummary> invoices;
  final bool sharing;
  final String? progress;
  final Object? error;

  const DailyInvoicesState({
    this.status = DailyInvoicesStatus.loading,
    this.invoices = const [],
    this.sharing = false,
    this.progress,
    this.error,
  });

  bool get isLoading => status == DailyInvoicesStatus.loading;

  DailyInvoicesState copyWith({
    DailyInvoicesStatus? status,
    List<DailyInvoiceSummary>? invoices,
    bool? sharing,
    String? progress,
    Object? error,
  }) {
    return DailyInvoicesState(
      status: status ?? this.status,
      invoices: invoices ?? this.invoices,
      sharing: sharing ?? this.sharing,
      progress: progress,
      error: error,
    );
  }
}

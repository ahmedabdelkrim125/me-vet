import 'package:mivet_app/features/invoices/domain/invoice_draft.dart';

class EditInvoiceState {
  final bool loading;
  final bool saving;
  final List<InvoiceItemDraft> items;
  final Map<String, CustomerProductPrice> customerPrices;
  final int currentPage;
  final double discountAmount;
  final Object? error;
  final bool saved;

  const EditInvoiceState({
    this.loading = true,
    this.saving = false,
    this.items = const [],
    this.customerPrices = const {},
    this.currentPage = 1,
    this.discountAmount = 0,
    this.error,
    this.saved = false,
  });

  double get subtotal => items.fold<double>(0, (sum, item) => sum + item.total);
  double get total => subtotal - discountAmount;
  int get pageCount => InvoiceDraft.pageCountFor(items.length);
  List<InvoiceItemDraft> get pageItems =>
      InvoiceDraft.pageOf(items, currentPage);

  EditInvoiceState copyWith({
    bool? loading,
    bool? saving,
    List<InvoiceItemDraft>? items,
    Map<String, CustomerProductPrice>? customerPrices,
    int? currentPage,
    double? discountAmount,
    Object? error,
    bool saved = false,
  }) {
    return EditInvoiceState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      items: items ?? this.items,
      customerPrices: customerPrices ?? this.customerPrices,
      currentPage: currentPage ?? this.currentPage,
      discountAmount: discountAmount ?? this.discountAmount,
      error: error,
      saved: saved,
    );
  }
}

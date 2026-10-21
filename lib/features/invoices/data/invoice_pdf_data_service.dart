import 'package:mivet_app/features/invoices/data/invoices_repository.dart';
import 'package:mivet_app/features/invoices/domain/invoice_pdf_builder.dart';
import 'package:mivet_app/features/invoices/domain/invoice_pdf_data_factory.dart';
import 'package:mivet_app/features/rep_session/data/rep_session_store.dart';

class InvoicePdfDataService {
  final InvoicesRepository _invoicesRepository;
  final RepSessionStore _repSessionStore;

  InvoicePdfDataService({
    InvoicesRepository? invoicesRepository,
    RepSessionStore? repSessionStore,
  })  : _invoicesRepository = invoicesRepository ?? InvoicesRepository.instance,
        _repSessionStore = repSessionStore ?? RepSessionStore.instance;

  Future<InvoiceAccountSummary?> fetchSummary(String invoiceId) async {
    try {
      return await _invoicesRepository.getInvoiceAccountSummary(invoiceId);
    } catch (_) {
      return null;
    }
  }

  Future<InvoicePdfData> buildByCode({
    required String invoiceCode,
    required String customerName,
    String? fallbackRepName,
    double fallbackPreviousBalance = 0,
  }) async {
    final detail = await _invoicesRepository.getInvoiceDetailByCode(invoiceCode);
    final summary = await fetchSummary(detail.id);
    final repName = await _resolveRepName(detail, fallbackRepName);
    return InvoicePdfDataFactory.fromDetail(
      detail: detail,
      summary: summary,
      customerName: customerName,
      repName: repName,
      fallbackPreviousBalance: fallbackPreviousBalance,
    );
  }

  Future<String> _resolveRepName(
    InvoiceFullDetail detail,
    String? fallbackRepName,
  ) async {
    final creatorName = detail.creatorName?.trim();
    if (creatorName != null && creatorName.isNotEmpty) {
      return '$creatorName${detail.isFromAdmin ? ' (إدارة)' : ''}';
    }
    final activeRep = await _repSessionStore.getActiveRep();
    final activeRepName = activeRep?.name.trim();
    if (activeRepName != null && activeRepName.isNotEmpty) return activeRepName;
    final fallback = fallbackRepName?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return '';
  }
}

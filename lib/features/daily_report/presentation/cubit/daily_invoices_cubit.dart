import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/utils/pdf_export.dart';
import 'package:mivet_app/features/daily_report/domain/daily_invoices_pdf_builder.dart';
import 'package:mivet_app/features/daily_report/presentation/cubit/daily_invoices_state.dart';
import 'package:mivet_app/features/invoices/data/invoice_pdf_data_service.dart';
import 'package:mivet_app/features/invoices/data/invoices_repository.dart';
import 'package:mivet_app/features/invoices/domain/invoice_pdf_data_factory.dart';

class DailyInvoicesCubit extends Cubit<DailyInvoicesState> {
  static const int _fetchBatchSize = 6;
  static const int _fetchAttempts = 3;

  final DateTime day;
  final InvoicesRepository _invoicesRepository;
  final InvoicePdfDataService _pdfDataService;

  DailyInvoicesCubit({
    required DateTime day,
    InvoicesRepository? invoicesRepository,
    InvoicePdfDataService? pdfDataService,
  })  : day = DateTime(day.year, day.month, day.day),
        _invoicesRepository = invoicesRepository ?? InvoicesRepository.instance,
        _pdfDataService = pdfDataService ?? InvoicePdfDataService(),
        super(const DailyInvoicesState());

  DateTime get _to => DateTime(day.year, day.month, day.day + 1);

  bool get isToday {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  Future<void> load() async {
    try {
      final invoices = await _invoicesRepository.getDailyInvoiceSummaries(
        from: day,
        to: _to,
      );
      if (isClosed) return;
      emit(state.copyWith(
        status: DailyInvoicesStatus.loaded,
        invoices: invoices,
      ));
    } catch (error) {
      if (isClosed) return;
      emit(state.copyWith(status: DailyInvoicesStatus.failure, error: error));
    }
  }

  Future<void> shareAll() async {
    final invoices = state.invoices;
    if (invoices.isEmpty || state.sharing) return;
    emit(state.copyWith(
      sharing: true,
      progress: 'تحميل 0/${invoices.length}',
    ));
    try {
      final entries = await _collectEntries(invoices);
      if (isClosed) return;
      emit(state.copyWith(sharing: true, progress: 'تجهيز الملفات...'));
      final parts = await DailyInvoicesPdfBuilder.buildParts(
        entries,
        day,
        onProgress: (done, total) {
          if (isClosed) return;
          emit(state.copyWith(sharing: true, progress: 'ملف $done/$total'));
        },
      );
      if (isClosed) return;
      await PdfExport.shareMany(parts, _fileBaseName());
    } catch (error) {
      if (!isClosed) emit(state.copyWith(sharing: true, error: error));
    } finally {
      if (!isClosed) emit(state.copyWith(sharing: false));
    }
  }

  Future<List<DailyInvoicePdfEntry>> _collectEntries(
    List<DailyInvoiceSummary> invoices,
  ) async {
    final entries = <DailyInvoicePdfEntry>[];
    for (var start = 0; start < invoices.length; start += _fetchBatchSize) {
      final slice = invoices.skip(start).take(_fetchBatchSize).toList();
      final batch = await Future.wait(slice.map(_entryOf));
      entries.addAll(batch);
      if (!isClosed) {
        emit(state.copyWith(
          sharing: true,
          progress: 'تحميل ${entries.length}/${invoices.length}',
        ));
      }
    }
    return entries;
  }

  Future<DailyInvoicePdfEntry> _entryOf(DailyInvoiceSummary invoice) async {
    final summaryFuture = _pdfDataService.fetchSummary(invoice.id);
    final detail = await _detailWithRetry(invoice.code);
    final summary = await summaryFuture;
    return DailyInvoicePdfEntry(
      invoiceCode: detail.code,
      customerName: invoice.customerName,
      date: invoice.date,
      items: [
        for (final item in detail.items)
          (
            name: item.productName,
            quantity: item.quantity,
            price: item.unitPrice,
            total: item.lineTotal,
          ),
      ],
      total: detail.totalAmount,
      status: detail.statusLabel,
      summary: InvoicePdfDataFactory.fromDetail(
        detail: detail,
        summary: summary,
        customerName: invoice.customerName,
        repName: '',
        date: invoice.date,
        includeItems: false,
      ),
    );
  }

  Future<InvoiceFullDetail> _detailWithRetry(String code) async {
    Object? lastError;
    for (var attempt = 0; attempt < _fetchAttempts; attempt++) {
      try {
        return await _invoicesRepository.getInvoiceDetailByCode(code);
      } catch (error) {
        lastError = error;
        await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }
    throw lastError ?? StateError('تعذر تحميل الفاتورة $code');
  }

  String _fileBaseName() =>
      'daily-invoices-${day.year}-${day.month}-${day.day}';
}

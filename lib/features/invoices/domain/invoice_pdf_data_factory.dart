import 'package:mivet_app/features/invoices/data/invoices_repository.dart';
import 'package:mivet_app/features/invoices/domain/invoice_pdf_builder.dart';

class InvoicePdfDataFactory {
  InvoicePdfDataFactory._();

  static InvoicePdfData fromDetail({
    required InvoiceFullDetail detail,
    required InvoiceAccountSummary? summary,
    required String customerName,
    required String repName,
    double fallbackPreviousBalance = 0,
    DateTime? date,
    bool includeItems = true,
  }) {
    final previousBalance = summary?.previousBalance ?? fallbackPreviousBalance;
    final paidTotal = summary?.paidFor(detail.totalAmount) ?? detail.paidNow;
    final accountRemaining =
        summary?.remaining ?? previousBalance + detail.totalAmount - paidTotal;
    return InvoicePdfData(
      invoiceNumber: detail.code,
      date: date ?? detail.date,
      customerName: customerName,
      repName: repName,
      items: includeItems
          ? detail.items
              .map((item) => InvoicePdfLineItem(
                    name: item.productName,
                    quantity: item.quantity,
                    price: item.unitPrice,
                    total: item.lineTotal,
                  ))
              .toList()
          : const [],
      invoiceTotal: detail.totalAmount,
      discountAmount: discountOf(detail),
      previousBalance: previousBalance,
      totalDue: detail.totalAmount + previousBalance,
      paidNow: paidTotal,
      remaining: accountRemaining < 0 ? 0 : accountRemaining,
      creditBalance: accountRemaining < 0 ? -accountRemaining : 0,
    );
  }

  static double discountOf(InvoiceFullDetail detail) {
    final fromSubtotal = detail.subtotal - detail.totalAmount;
    return detail.discountAmount > fromSubtotal
        ? detail.discountAmount
        : (fromSubtotal > 0 ? fromSubtotal : 0.0);
  }
}
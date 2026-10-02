import 'dart:io';
import 'package:mivet_app/features/invoices/domain/invoice_pdf_builder.dart';

Future<void> main() async {
  InvoicePdfLineItem item(String name) => const InvoicePdfLineItem(
    name: 'فلوريديكول',
    quantity: 1,
    price: 75,
    total: 75,
  );

  // نفس حالة السكرين شوت: حساب سابق 75 + فاتورة 75، وتم تحصيل 75.
  final cases = <String, InvoicePdfData>{
    'partial': InvoicePdfData(
      invoiceNumber: 'INV-2026-0406',
      date: DateTime(2026, 9, 28),
      customerName: 'العميل / 100',
      repName: 'احمد عبدالكريم',
      items: [item('فلوريديكول')],
      invoiceTotal: 75,
      previousBalance: 75,
      totalDue: 150,
      paidNow: 75,
      remaining: 75,
    ),
    'paid': InvoicePdfData(
      invoiceNumber: 'INV-2026-0407',
      date: DateTime(2026, 9, 28),
      customerName: 'العميل / 100',
      repName: 'احمد عبدالكريم',
      items: [item('فلوريديكول')],
      invoiceTotal: 75,
      previousBalance: 75,
      totalDue: 150,
      paidNow: 150,
      remaining: 0,
    ),
    'deferred': InvoicePdfData(
      invoiceNumber: 'INV-2026-0408',
      date: DateTime(2026, 9, 28),
      customerName: 'العميل / 100',
      repName: 'احمد عبدالكريم',
      items: [item('فلوريديكول')],
      invoiceTotal: 75,
      previousBalance: 75,
      totalDue: 150,
      paidNow: 0,
      remaining: 150,
    ),
  };

  final outDir = Directory('tool/pdf_preview/out');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  for (final entry in cases.entries) {
    final bytes = await InvoicePdfBuilder.build(entry.value);
    final file = File('tool/pdf_preview/out/${entry.key}.pdf');
    await file.writeAsBytes(bytes);
    stdout.writeln('wrote ${file.path} (${bytes.length} bytes)');
  }
}

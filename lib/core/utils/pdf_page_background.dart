import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

pw.Widget buildWhitePdfBackground({Uint8List? watermarkBytes}) {
  return pw.FullPage(
    ignoreMargins: true,
    child: pw.Container(
      color: PdfColors.white,
      child: watermarkBytes == null
          ? null
          : pw.Padding(
              padding: const pw.EdgeInsets.only(top: 35),
              child: pw.Center(
                child: pw.Image(pw.MemoryImage(watermarkBytes), width: 320),
              ),
            ),
    ),
  );
}

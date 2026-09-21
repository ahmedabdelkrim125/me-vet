import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Page background used by EVERY generated PDF.
///
/// A PDF page has no background by default (it is transparent). Viewers show
/// that as white, but when a page is rasterised to PNG (e.g. the images we
/// share) the transparent pixels turn black in dark viewers. Painting an
/// explicit white page makes the result white everywhere.
///
/// Use it as `pageTheme: pw.PageTheme(buildBackground: (_) => buildWhitePdfBackground(...))`.
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

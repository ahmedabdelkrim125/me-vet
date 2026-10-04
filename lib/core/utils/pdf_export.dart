import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfExport {
  PdfExport._();

  static Future<void> share(Uint8List bytes, String fileName) async {
    final file = await _writeTemp(bytes, fileName);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType: 'application/pdf',
            name: file.uri.pathSegments.last,
          ),
        ],
      ),
    );
  }

  static Future<File> _writeTemp(Uint8List bytes, String fileName) async {
    if (bytes.isEmpty) {
      throw StateError('ملف الـ PDF فاضي، جرّب تاني');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_safeName(fileName)}');
    await file.writeAsBytes(bytes, flush: true);

    if (await file.length() != bytes.length) {
      throw StateError('تعذر حفظ ملف الـ PDF على الجهاز');
    }
    return file;
  }

  static String _safeName(String fileName) {
    var name = fileName.replaceAll(RegExp(r'[^A-Za-z0-9_.\-]'), '_');
    name = name.replaceAll(RegExp(r'_+'), '_');
    if (name.replaceAll(RegExp(r'[_.]'), '').isEmpty) name = 'document.pdf';
    if (!name.toLowerCase().endsWith('.pdf')) name = '$name.pdf';
    return name;
  }
}

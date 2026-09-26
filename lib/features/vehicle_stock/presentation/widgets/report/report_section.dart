import 'package:pdf/widgets.dart' as pw;

class ReportSection {
  final String category;
  final List<String> headers;
  final List<List<String>> rows;
  final Map<int, pw.TableColumnWidth> columnWidths;

  ReportSection(this.category, this.headers, this.rows, this.columnWidths);
}

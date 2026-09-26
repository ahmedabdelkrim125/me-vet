import 'report_section.dart';

const int reportRowsPerPage = 14;

List<List<ReportSection>> paginateReportSections(
  List<ReportSection> sections,
) {
  final pages = <List<ReportSection>>[];
  var currentPage = <ReportSection>[];
  var currentRowCount = 0;

  void pushPage() {
    if (currentPage.isNotEmpty) pages.add(currentPage);
    currentPage = <ReportSection>[];
    currentRowCount = 0;
  }

  for (final section in sections) {
    var remainingRows = section.rows;
    var isFirstPart = true;

    while (remainingRows.isNotEmpty) {
      var availableSlots = reportRowsPerPage - currentRowCount;
      if (availableSlots <= 0) {
        pushPage();
        availableSlots = reportRowsPerPage;
      }
      final takeCount = remainingRows.length <= availableSlots
          ? remainingRows.length
          : availableSlots;
      final chunkRows = remainingRows.sublist(0, takeCount);
      remainingRows = remainingRows.sublist(takeCount);

      final label =
          isFirstPart ? section.category : '${section.category} (تابع)';
      currentPage.add(
        ReportSection(label, section.headers, chunkRows, section.columnWidths),
      );
      currentRowCount += chunkRows.length;
      isFirstPart = false;
    }
  }
  pushPage();
  if (pages.isEmpty) pages.add(<ReportSection>[]);
  return pages;
}

import 'package:flutter/material.dart';
import '../../../domain/models/client_visit_stats_model.dart';
import 'report_card.dart';

class ClientStatsCard extends StatelessWidget {
  final ClientVisitStatsModel stats;
  const ClientStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      title: 'إحصائيات العملاء',
      icon: Icons.groups_outlined,
      rows: [
        ('إجمالي العملاء المخصصين', '${stats.totalAssignedClients}'),
        ('تمت زيارتهم', '${stats.visitedClients}'),
        ('مكتملة / بيع', '${stats.completedOrSoldClients}'),
        ('بدون طلب', '${stats.noOrderClients}'),
        ('لم يوصل', '${stats.notReachedClients}'),
        ('نسبة الإنجاز', '${(stats.completionRate * 100).toStringAsFixed(0)}%'),
      ],
    );
  }
}

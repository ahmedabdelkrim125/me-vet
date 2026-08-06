import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../domain/models/daily_stat_model.dart';
import 'stat_card.dart';

class DailySummarySection extends StatelessWidget {
  const DailySummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = <DailyStatModel>[
      const DailyStatModel(
        label: 'إجمالي المبيعات',
        value: '18,450 ج.م',
        icon: Icons.trending_up_rounded,
        color: AppColors.primaryGreen,
      ),
      const DailyStatModel(
        label: 'إجمالي المرتجعات',
        value: '620 ج.م',
        icon: Icons.undo_rounded,
        color: AppColors.statOrange,
      ),
      const DailyStatModel(
        label: 'إجمالي التحصيل',
        value: '15,900 ج.م',
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.statBlue,
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          Expanded(child: StatCard(stat: stats[i])),
          if (i != stats.length - 1) SizedBox(width: 12.w),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/shortcut_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildKpiRow(),
                const SizedBox(height: 16),
                _buildRouteCard(context),
                const SizedBox(height: 20),
                const Text('اختصارات سريعة', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                _buildShortcutsGrid(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 96,
      backgroundColor: AppColors.navy,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.navyGradient),
          padding: const EdgeInsets.fromLTRB(20, 46, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('أهلاً، أحمد 👋',
                        style: AppTextStyles.h2.copyWith(color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('المنصورة — الأحد 18 يوليو',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white60)),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_none_rounded,
                        color: Colors.white, size: 20),
                  ),
                  Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: const Text('5',
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiRow() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: const [
        StatCard(
          label: 'زيارات اليوم',
          value: '5/12',
          icon: Icons.route_rounded,
          accent: AppColors.teal,
        ),
        StatCard(
          label: 'مبيعات اليوم',
          value: '18,500 ج',
          icon: Icons.trending_up_rounded,
          accent: AppColors.gold,
        ),
        StatCard(
          label: 'تحصيلات',
          value: '12,200 ج',
          icon: Icons.payments_outlined,
          accent: AppColors.success,
        ),
        StatCard(
          label: 'فواتير اليوم',
          value: '4',
          icon: Icons.receipt_long_outlined,
          accent: AppColors.info,
        ),
      ],
    );
  }

  Widget _buildRouteCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.navyGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_rounded,
                  color: AppColors.tealLight, size: 20),
              const SizedBox(width: 8),
              Text('خط اليوم — المنصورة 1',
                  style: AppTextStyles.h3.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 4),
          Text('5 من 12 زيارة مكتملة',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white60)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 5 / 12,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.tealLight),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                minimumSize: const Size.fromHeight(46),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('ابدأ الجولة', style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutsGrid() {
    final items = [
      (Icons.shopping_cart_outlined, 'بيع جديد', 'إنشاء فاتورة', null),
      (Icons.people_outline_rounded, 'العملاء', '68 عميل', null),
      (Icons.savings_outlined, 'التحصيلات', '5 مستحقة', null),
      (Icons.local_shipping_outlined, 'مخزون السيارة', '3 منخفضة', null),
      (Icons.bar_chart_rounded, 'أدائي', '68% من الهدف', null),
      (Icons.notifications_none_rounded, 'التنبيهات', '5 جديدة', 5),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: items.map((e) {
        return ShortcutCard(
          icon: e.$1,
          title: e.$2,
          subtitle: e.$3,
          badge: e.$4,
          onTap: () {},
        );
      }).toList(),
    );
  }
}

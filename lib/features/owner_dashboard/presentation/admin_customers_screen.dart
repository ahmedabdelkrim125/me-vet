import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

import '../../customer-visits/customers/domain/models/customer_model.dart';
import '../data/admin_actions_service.dart';
import 'widgets/admin_customer_actions_sheet.dart';

/// كل عملاء التطبيق (مش عملاء مندوب واحد بس)، عشان الأونر يقدر يختار عميل
/// ويضيفله مديونية قديمة، أو يعمل له فاتورة تاريخية، أو يحذفه نهائيًا.
class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  final _service = AdminActionsService();
  final _searchController = TextEditingController();
  List<CustomerModel> _all = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final customers = await _service.getAllCustomers();
      if (!mounted) return;
      setState(() {
        _all = customers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppError(context, e);
    }
  }

  List<CustomerModel> get _filtered {
    final q = _query.trim();
    if (q.isEmpty) return _all;
    return _all
        .where((c) => c.name.contains(q) || c.phone.contains(q))
        .toList();
  }

  Future<void> _openActions(CustomerModel customer) async {
    final deleted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdminCustomerActionsSheet(customer: customer),
    );
    if (deleted == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final customers = _filtered;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'إدارة العملاء',
          style: AppTextStyles.cairoBold18
              .copyWith(color: Colors.white, fontSize: 17.sp),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(14.w),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو رقم الهاتف',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : customers.isEmpty
                    ? Center(
                        child: Text(
                          _query.isEmpty
                              ? 'لا يوجد عملاء'
                              : 'مفيش عميل بالاسم ده',
                          style: AppTextStyles.almaraiRegular14.copyWith(
                              color: AppColors.navInactive, fontSize: 13.sp),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                          itemCount: customers.length,
                          itemBuilder: (context, index) {
                            final c = customers[index];
                            final hasDebt = c.currentBalance > 0;
                            return Container(
                              margin: EdgeInsets.only(bottom: 10.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: ListTile(
                                onTap: () => _openActions(c),
                                title: Text(
                                  c.name,
                                  style: AppTextStyles.cairoMedium16
                                      .copyWith(fontSize: 13.5.sp),
                                ),
                                subtitle: Text(
                                  c.phone.isEmpty
                                      ? c.area
                                      : '${c.phone} • ${c.area}',
                                  style: AppTextStyles.almaraiRegular14
                                      .copyWith(
                                          color: AppColors.navInactive,
                                          fontSize: 11.sp),
                                ),
                                trailing: hasDebt
                                    ? Text(
                                        '${c.currentBalance.toStringAsFixed(0)} ج.م',
                                        style: TextStyle(
                                          color: AppColors.statusNotReached,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.sp,
                                        ),
                                      )
                                    : const Icon(Icons.chevron_left_rounded,
                                        color: AppColors.navInactive),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

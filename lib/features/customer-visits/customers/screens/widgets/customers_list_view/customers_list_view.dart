import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../../../../core/theme/app_color_scheme_extension.dart';
import '../../../domain/mock_customers_repository.dart';
import '../../../domain/models/customer_model.dart';
import '../../../domain/models/customer_status.dart';
import 'add_customer_bottom_sheet.dart';
import 'add_customer_button.dart';
import 'customer_filter_bar.dart';
import 'customer_list_tile.dart';
import 'customer_search_field.dart';

class CustomersListView extends StatefulWidget {
  const CustomersListView({super.key});

  @override
  State<CustomersListView> createState() => _CustomersListViewState();
}

class _CustomersListViewState extends State<CustomersListView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  int _filterIndex = 0;
  String _query = '';
  late final MockCustomersRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = MockCustomersRepository.instance;
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _loadCustomers();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    await _repository.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  List<CustomerModel> get _filteredCustomers {
    return _repository.getCustomers(
      query: _query,
      status: switch (_filterIndex) {
        1 => CustomerStatus.active,
        2 => CustomerStatus.needsFollowUp,
        3 => CustomerStatus.stopped,
        _ => null,
      },
    );
  }

  List<int> get _filterCounts {
    return [
      _repository.countForStatus(null),
      _repository.countForStatus(CustomerStatus.active),
      _repository.countForStatus(CustomerStatus.needsFollowUp),
      _repository.countForStatus(CustomerStatus.stopped),
    ];
  }

  Future<void> _openAddCustomerSheet() async {
    final newCustomer = await showAddCustomerBottomSheet(context);
    if (newCustomer == null) return;

    await _repository.addCustomer(newCustomer);
    if (mounted) {
      setState(() {
        _entranceController
          ..reset()
          ..forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // final customers = _filteredCustomers;

    return ValueListenableBuilder<List<CustomerModel>>(
      valueListenable: _repository.customersNotifier,
      builder: (context, _, __) {
        final visibleCustomers = _filteredCustomers;

        return Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
              children: [
                CustomerSearchField(
                    onChanged: (value) => setState(() => _query = value)),
                SizedBox(height: 12.h),
                CustomerFilterBar(
                  selectedIndex: _filterIndex,
                  counts: _filterCounts,
                  onChanged: (index) => setState(() => _filterIndex = index),
                ),
                SizedBox(height: 14.h),
                for (int i = 0; i < visibleCustomers.length; i++)
                  _AnimatedCustomerTile(
                    index: i,
                    total: visibleCustomers.length,
                    controller: _entranceController,
                    customer: visibleCustomers[i],
                  ),
                if (visibleCustomers.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 60.h),
                    child: Center(
                      child: Text(
                        'لا يوجد عملاء مطابقين',
                        style: AppTextStyles.cairoMedium16.copyWith(
                          color: context.colors.textMuted,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16.h,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: AddCustomerButton(onTap: _openAddCustomerSheet),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnimatedCustomerTile extends StatelessWidget {
  final int index;
  final int total;
  final AnimationController controller;
  final CustomerModel customer;

  const _AnimatedCustomerTile({
    required this.index,
    required this.total,
    required this.controller,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = total == 0 ? 1 : total;
    final start = (index / safeTotal) * 0.5;
    final end = (start + 0.5).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: CustomerListTile(customer: customer),
      ),
    );
  }
}

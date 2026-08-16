import 'package:hugeicons/hugeicons.dart';
import 'nav_item_model.dart';

const List<NavItemModel> appNavItems = [
  NavItemModel(icon: HugeIcons.strokeRoundedHome01, label: 'الرئيسية'),
  NavItemModel(
    icon: HugeIcons.strokeRoundedUserGroup,
    label: 'العملاء وخط السير',
  ),
  NavItemModel(
    icon: HugeIcons.strokeRoundedInvoice01,
    label: 'اضافة المنتجات',
  ),
  NavItemModel(
    icon: HugeIcons.strokeRoundedPackage,
    label: 'المخزون والمنتجات',
  ),
  NavItemModel(icon: HugeIcons.strokeRoundedChartColumn, label: 'تقرير اليوم'),
  NavItemModel(icon: HugeIcons.strokeRoundedSettings01, label: 'الإعدادات'),
];

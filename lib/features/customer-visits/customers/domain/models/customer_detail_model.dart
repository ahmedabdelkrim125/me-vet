import 'customer_model.dart';
import '../../data/customers_repository.dart';

class ProductPurchaseModel {
  final String name;
  final double price;
  final DateTime lastPurchaseDate;

  const ProductPurchaseModel({
    required this.name,
    required this.price,
    required this.lastPurchaseDate,
  });
}

class InvoiceSummaryModel {
  final String code;
  final DateTime date;
  final double amount;
  final String status;

  const InvoiceSummaryModel({
    required this.code,
    required this.date,
    required this.amount,
    required this.status,
  });
}

class CustomerDetailModel {
  final CustomerModel customer;
  final double currentBalance;
  final DateTime? lastCollectionDate;
  final double averageOrder;
  final List<ProductPurchaseModel> topProducts;
  final List<ProductPurchaseModel> notBoughtRecently;
  final List<String> seasonalSuggestions;
  final String notes;
  final List<InvoiceSummaryModel> invoices;

  const CustomerDetailModel({
    required this.customer,
    required this.currentBalance,
    required this.lastCollectionDate,
    required this.averageOrder,
    required this.topProducts,
    required this.notBoughtRecently,
    required this.seasonalSuggestions,
    required this.notes,
    required this.invoices,
  });

  /// TODO(invoices-feature): topProducts/notBoughtRecently/seasonalSuggestions
  /// و invoices هيتحسبوا من جدولي `invoices`/`invoice_items` الحقيقيين لما
  /// نشتغل على فيتشر الفواتير. لحد وقتها بيرجعوا فاضيين بدل بيانات وهمية
  /// (كانوا قبل كده seed data ثابتة بتظهر لكل عميل بالظبط).
  ///
  /// `notes` كمان هترجع من عمود `notes` الحقيقي في جدول customers بمجرد ما
  /// تبقى شاشة إضافة/تعديل العميل فيها حقل للملاحظات (مش موجود لسه).
  factory CustomerDetailModel.mock(CustomerModel customer) {
    final averageOrder =
        CustomersRepository.instance.getAverageOrder(customer.id);

    return CustomerDetailModel(
      customer: customer,
      currentBalance: customer.currentBalance,
      lastCollectionDate: customer.lastCollectionDate,
      averageOrder: averageOrder,
      topProducts: const [],
      notBoughtRecently: const [],
      seasonalSuggestions: const [],
      notes: '',
      invoices: const [],
    );
  }
}

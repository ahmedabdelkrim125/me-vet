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

  factory CustomerDetailModel.mock(CustomerModel customer) {
    final now = DateTime.now();
    final averageOrder =
        CustomersRepository.instance.getAverageOrder(customer.id);

    return CustomerDetailModel(
      customer: customer,
      currentBalance: customer.currentBalance,
      lastCollectionDate: customer.lastCollectionDate,
      averageOrder: averageOrder,
      topProducts: [
        ProductPurchaseModel(
            name: 'فيتامين أ د3 إي',
            price: 180,
            lastPurchaseDate: now.subtract(const Duration(days: 6))),
        ProductPurchaseModel(
            name: 'مضاد حيوي واسع المجال',
            price: 320,
            lastPurchaseDate: now.subtract(const Duration(days: 14))),
        ProductPurchaseModel(
            name: 'محلول ترطيب فموي',
            price: 95,
            lastPurchaseDate: now.subtract(const Duration(days: 20))),
      ],
      notBoughtRecently: [
        ProductPurchaseModel(
            name: 'مطهر عام',
            price: 140,
            lastPurchaseDate: now.subtract(const Duration(days: 75))),
        ProductPurchaseModel(
            name: 'إضافات علف',
            price: 260,
            lastPurchaseDate: now.subtract(const Duration(days: 95))),
      ],
      seasonalSuggestions: const [
        'فيتامينات مقاومة الحرارة',
        'مطهرات تعقيم الصيف'
      ],
      notes: 'العميل بيفضل التسليم الصبح، وبيسدد آجل غالبًا خلال أسبوعين.',
      invoices: [
        InvoiceSummaryModel(
            code: 'INV-2201',
            date: now.subtract(const Duration(days: 5)),
            amount: 1250,
            status: 'مدفوعة'),
        InvoiceSummaryModel(
            code: 'INV-2188',
            date: now.subtract(const Duration(days: 19)),
            amount: 890,
            status: 'جزئي'),
        InvoiceSummaryModel(
            code: 'INV-2153',
            date: now.subtract(const Duration(days: 40)),
            amount: 2100,
            status: 'آجلة'),
      ],
    );
  }
}

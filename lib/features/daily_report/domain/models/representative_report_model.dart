// class RepresentativeReportModel {
//   final DateTime from;
//   final DateTime to;
//   final String? repId;
//   final double totalSales;
//   final int invoiceCount;
//   final double totalCollections;
//   final Map<String, double> collectionsByMethod;
//   final List<CustomerCollectionModel> collectionsByCustomer;
//   final List<CustomerSaleModel> salesByCustomer;
//   final List<ExpenseItemModel> expenses;
//   final double totalExpenses;
//   final Map<String, double> expensesByMethod;
//   final Map<String, double> balances;

//   const RepresentativeReportModel({
//     required this.from,
//     required this.to,
//     this.repId,
//     required this.totalSales,
//     required this.invoiceCount,
//     required this.totalCollections,
//     required this.collectionsByMethod,
//     required this.collectionsByCustomer,
//     required this.salesByCustomer,
//     required this.expenses,
//     required this.totalExpenses,
//     required this.expensesByMethod,
//     required this.balances,
//   });

//   factory RepresentativeReportModel.fromJson(Map<String, dynamic> json) {
//     return RepresentativeReportModel(
//       from: DateTime.parse(json['from'] as String),
//       to: DateTime.parse(json['to'] as String),
//       repId: json['rep_id'] as String?,
//       totalSales: _parseDouble(json['total_sales']),
//       invoiceCount: json['invoice_count'] as int? ?? 0,
//       totalCollections: _parseDouble(json['total_collections']),
//       collectionsByMethod: _parseMap(json['collections_by_method']),
//       collectionsByCustomer: (json['collections_by_customer'] as List<dynamic>?)
//               ?.map((e) =>
//                   CustomerCollectionModel.fromJson(e as Map<String, dynamic>))
//               .toList() ??
//           [],
//       salesByCustomer: (json['sales_by_customer'] as List<dynamic>?)
//               ?.map(
//                   (e) => CustomerSaleModel.fromJson(e as Map<String, dynamic>))
//               .toList() ??
//           [],
//       expenses: (json['expenses'] as List<dynamic>?)
//               ?.map((e) => ExpenseItemModel.fromJson(e as Map<String, dynamic>))
//               .toList() ??
//           [],
//       totalExpenses: _parseDouble(json['total_expenses']),
//       expensesByMethod: _parseMap(json['expenses_by_method']),
//       balances: _parseMap(json['balances']),
//     );
//   }

//   static double _parseDouble(dynamic value) {
//     if (value == null) return 0.0;
//     if (value is int) return value.toDouble();
//     if (value is double) return value;
//     if (value is String) return double.tryParse(value) ?? 0.0;
//     return 0.0;
//   }

//   static Map<String, double> _parseMap(dynamic map) {
//     if (map == null || map is! Map) return {};
//     return map
//         .map((key, value) => MapEntry(key.toString(), _parseDouble(value)));
//   }
// }

// class CustomerCollectionModel {
//   final String customerName;
//   final double totalCollected;
//   final Map<String, double> breakdown;

//   const CustomerCollectionModel({
//     required this.customerName,
//     required this.totalCollected,
//     required this.breakdown,
//   });

//   factory CustomerCollectionModel.fromJson(Map<String, dynamic> json) {
//     return CustomerCollectionModel(
//       customerName: json['customer_name'] as String? ?? 'غير معروف',
//       totalCollected:
//           RepresentativeReportModel._parseDouble(json['total_collected']),
//       breakdown: RepresentativeReportModel._parseMap(json['breakdown']),
//     );
//   }
// }

// class CustomerSaleModel {
//   final String customerName;
//   final double totalSales;

//   const CustomerSaleModel({
//     required this.customerName,
//     required this.totalSales,
//   });

//   factory CustomerSaleModel.fromJson(Map<String, dynamic> json) {
//     return CustomerSaleModel(
//       customerName: json['customer_name'] as String? ?? 'غير معروف',
//       totalSales: RepresentativeReportModel._parseDouble(json['total_sales']),
//     );
//   }
// }

// class ExpenseItemModel {
//   final String category;
//   final double amount;
//   final String paymentMethod;
//   final String? notes;
//   final DateTime expenseAt;

//   const ExpenseItemModel({
//     required this.category,
//     required this.amount,
//     required this.paymentMethod,
//     this.notes,
//     required this.expenseAt,
//   });

//   factory ExpenseItemModel.fromJson(Map<String, dynamic> json) {
//     return ExpenseItemModel(
//       category: json['category'] as String? ?? '',
//       amount: RepresentativeReportModel._parseDouble(json['amount']),
//       paymentMethod: json['payment_method'] as String? ?? '',
//       notes: json['notes'] as String?,
//       expenseAt: DateTime.parse(json['expense_at'] as String),
//     );
//   }
// }

class PaymentMethodBalanceModel {
  final double beforeExpenses;
  final double expenses;
  final double afterExpenses;

  const PaymentMethodBalanceModel({
    required this.beforeExpenses,
    required this.expenses,
    required this.afterExpenses,
  });

  factory PaymentMethodBalanceModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodBalanceModel(
      beforeExpenses:
          RepresentativeReportModel._parseDouble(json['before_expenses']),
      expenses: RepresentativeReportModel._parseDouble(json['expenses']),
      afterExpenses:
          RepresentativeReportModel._parseDouble(json['after_expenses']),
    );
  }
}

class RepresentativeReportModel {
  final DateTime from;
  final DateTime to;
  final String? repId;
  final double totalSales;
  final int invoiceCount;
  final double totalCollections;
  final Map<String, double> collectionsByMethod;
  final List<CustomerCollectionModel> collectionsByCustomer;
  final List<CustomerSaleModel> salesByCustomer;
  final List<ExpenseItemModel> expenses;
  final double totalExpenses;
  final Map<String, double> expensesByMethod;
  final Map<String, PaymentMethodBalanceModel> balances;

  const RepresentativeReportModel({
    required this.from,
    required this.to,
    this.repId,
    required this.totalSales,
    required this.invoiceCount,
    required this.totalCollections,
    required this.collectionsByMethod,
    required this.collectionsByCustomer,
    required this.salesByCustomer,
    required this.expenses,
    required this.totalExpenses,
    required this.expensesByMethod,
    required this.balances,
  });

  factory RepresentativeReportModel.fromJson(Map<String, dynamic> json) {
    return RepresentativeReportModel(
      from: DateTime.parse(json['from'] as String),
      to: DateTime.parse(json['to'] as String),
      repId: json['rep_id'] as String?,
      totalSales: _parseDouble(json['total_sales']),
      invoiceCount: json['invoice_count'] as int? ?? 0,
      totalCollections: _parseDouble(json['total_collections']),
      collectionsByMethod: _parseMap(json['collections_by_method']),
      collectionsByCustomer: (json['collections_by_customer'] as List<dynamic>?)
              ?.map((e) =>
                  CustomerCollectionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      salesByCustomer: (json['sales_by_customer'] as List<dynamic>?)
              ?.map(
                  (e) => CustomerSaleModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      expenses: (json['expenses'] as List<dynamic>?)
              ?.map((e) => ExpenseItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalExpenses: _parseDouble(json['total_expenses']),
      expensesByMethod: _parseMap(json['expenses_by_method']),
      balances: _parseBalancesMap(json['balances']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static Map<String, double> _parseMap(dynamic map) {
    if (map == null || map is! Map) return {};
    return map
        .map((key, value) => MapEntry(key.toString(), _parseDouble(value)));
  }

  static Map<String, PaymentMethodBalanceModel> _parseBalancesMap(dynamic map) {
    if (map == null || map is! Map) return {};
    return map.map((key, value) => MapEntry(
          key.toString(),
          PaymentMethodBalanceModel.fromJson(value as Map<String, dynamic>),
        ));
  }
}

class CustomerCollectionModel {
  final String customerName;
  final double totalCollected;
  final Map<String, double> breakdown;

  const CustomerCollectionModel({
    required this.customerName,
    required this.totalCollected,
    required this.breakdown,
  });

  factory CustomerCollectionModel.fromJson(Map<String, dynamic> json) {
    return CustomerCollectionModel(
      customerName: json['customer_name'] as String? ?? 'غير معروف',
      totalCollected:
          RepresentativeReportModel._parseDouble(json['total_collected']),
      breakdown: RepresentativeReportModel._parseMap(json['breakdown']),
    );
  }
}

class CustomerSaleModel {
  final String customerName;
  final double totalSales;

  const CustomerSaleModel({
    required this.customerName,
    required this.totalSales,
  });

  factory CustomerSaleModel.fromJson(Map<String, dynamic> json) {
    return CustomerSaleModel(
      customerName: json['customer_name'] as String? ?? 'غير معروف',
      totalSales: RepresentativeReportModel._parseDouble(json['total_sales']),
    );
  }
}

class ExpenseItemModel {
  final String category;
  final double amount;
  final String paymentMethod;
  final String? notes;
  final DateTime expenseAt;

  const ExpenseItemModel({
    required this.category,
    required this.amount,
    required this.paymentMethod,
    this.notes,
    required this.expenseAt,
  });

  factory ExpenseItemModel.fromJson(Map<String, dynamic> json) {
    return ExpenseItemModel(
      category: json['category'] as String? ?? '',
      amount: RepresentativeReportModel._parseDouble(json['amount']),
      paymentMethod: json['payment_method'] as String? ?? '',
      notes: json['notes'] as String?,
      expenseAt: DateTime.parse(json['expense_at'] as String),
    );
  }
}

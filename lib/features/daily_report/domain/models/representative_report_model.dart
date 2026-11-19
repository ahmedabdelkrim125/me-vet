import 'package:flutter/foundation.dart';

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
  final double totalReturns;
  final double netSales;
  final int invoiceCount;
  final double totalCollections;
  final Map<String, double> collectionsByMethod;
  final List<CustomerCollectionModel> collectionsByCustomer;
  final List<CustomerSaleModel> salesByCustomer;
  final List<ExpenseItemModel> expenses;
  final List<ReturnItemModel> returns;
  final double totalExpenses;
  final Map<String, double> expensesByMethod;
  final Map<String, PaymentMethodBalanceModel> balances;
  final List<String> warnings;
  final Set<String> invalidBalanceMethods;

  const RepresentativeReportModel({
    required this.from,
    required this.to,
    this.repId,
    required this.totalSales,
    required this.totalReturns,
    required this.netSales,
    required this.invoiceCount,
    required this.totalCollections,
    required this.collectionsByMethod,
    required this.collectionsByCustomer,
    required this.salesByCustomer,
    required this.expenses,
    this.returns = const <ReturnItemModel>[],
    required this.totalExpenses,
    required this.expensesByMethod,
    required this.balances,
    this.warnings = const <String>[],
    this.invalidBalanceMethods = const <String>{},
  });

  factory RepresentativeReportModel.fromJson(
    Map<String, dynamic> json, {
    DateTime? fallbackFrom,
    DateTime? fallbackTo,
    dynamic returnsJson,
  }) {
    final warnings = <String>[];
    final invalidBalanceMethods = <String>{};

    final from = _parseDate(json['from']) ?? fallbackFrom;
    final to = _parseDate(json['to']) ?? fallbackTo;
    if (from == null || to == null) {
      throw const FormatException('تاريخ بداية أو نهاية التقرير غير موجود');
    }

    final balances = _parseBalancesMap(
      json['balances'],
      invalidBalanceMethods,
      warnings,
    );

    final totalReturns = _parseDouble(json['total_returns']);
    final returns = returnsJson == null
        ? <ReturnItemModel>[]
        : _parseList(
            returnsJson,
            'المرتجعات',
            ReturnItemModel.fromJson,
            warnings,
          );
    if (returnsJson == null) {
      if (totalReturns > 0) {
        warnings.add('تفاصيل المرتجعات غير متاحة حاليا');
      }
    } else {
      final listed = returns.fold<double>(0, (sum, r) => sum + r.amount);
      if ((listed - totalReturns).abs() > 0.01) {
        warnings.add('مجموع المرتجعات المعروضة لا يطابق إجمالي المرتجعات');
      }
    }

    return RepresentativeReportModel(
      from: from,
      to: to,
      repId: json['rep_id']?.toString(),
      totalSales: _parseDouble(json['total_sales']),
      totalReturns: totalReturns,
      netSales: _parseDouble(json['net_sales']),
      invoiceCount: _parseInt(json['invoice_count']),
      totalCollections: _parseDouble(json['total_collections']),
      collectionsByMethod: _parseMap(json['collections_by_method']),
      collectionsByCustomer: _parseList(
        json['collections_by_customer'],
        'تحصيلات العملاء',
        CustomerCollectionModel.fromJson,
        warnings,
      ),
      salesByCustomer: _parseList(
        json['sales_by_customer'],
        'مبيعات العملاء',
        CustomerSaleModel.fromJson,
        warnings,
      ),
      expenses: _parseList(
        json['expenses'],
        'المصروفات',
        ExpenseItemModel.fromJson,
        warnings,
      ),
      returns: returns,
      totalExpenses: _parseDouble(json['total_expenses']),
      expensesByMethod: _parseMap(json['expenses_by_method']),
      balances: balances,
      warnings: warnings,
      invalidBalanceMethods: invalidBalanceMethods,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static Map<String, double> _parseMap(dynamic map) {
    if (map == null || map is! Map) return {};
    return map
        .map((key, value) => MapEntry(key.toString(), _parseDouble(value)));
  }

  static List<T> _parseList<T>(
    dynamic raw,
    String label,
    T Function(Map<String, dynamic>) parse,
    List<String> warnings,
  ) {
    if (raw == null) return <T>[];
    if (raw is! List) {
      warnings.add('بيانات $label بصيغة غير صالحة');
      return <T>[];
    }
    final result = <T>[];
    var skipped = 0;
    for (final item in raw) {
      if (item is! Map) {
        skipped++;
        continue;
      }
      try {
        result.add(parse(Map<String, dynamic>.from(item)));
      } catch (e) {
        skipped++;
        debugPrint('[Report] تعذر قراءة عنصر من $label: $e');
      }
    }
    if (skipped > 0) {
      warnings.add('تم تجاهل $skipped من بيانات $label لأنها غير صالحة');
    }
    return result;
  }

  static Map<String, PaymentMethodBalanceModel> _parseBalancesMap(
    dynamic raw,
    Set<String> invalidMethods,
    List<String> warnings,
  ) {
    if (raw == null) return {};
    if (raw is! Map) {
      warnings.add('بيانات الأرصدة بصيغة غير صالحة');
      return {};
    }
    final result = <String, PaymentMethodBalanceModel>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value == null) continue;
      if (value is! Map) {
        invalidMethods.add(key);
        continue;
      }
      try {
        result[key] = PaymentMethodBalanceModel.fromJson(
          Map<String, dynamic>.from(value),
        );
      } catch (e) {
        invalidMethods.add(key);
        debugPrint('[Report] تعذر قراءة رصيد $key: $e');
      }
    }
    if (invalidMethods.isNotEmpty) {
      warnings.add(
        'رصيد بعض وسائل الدفع غير صالح: ${invalidMethods.join('، ')}',
      );
    }
    return result;
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
      customerName: json['customer_name']?.toString() ?? 'غير معروف',
      totalCollected:
          RepresentativeReportModel._parseDouble(json['total_collected']),
      breakdown: RepresentativeReportModel._parseMap(json['breakdown']),
    );
  }
}

class CustomerSaleModel {
  final String customerName;
  final double totalSales;
  final double returnsAmount;

  const CustomerSaleModel({
    required this.customerName,
    required this.totalSales,
    required this.returnsAmount,
  });

  factory CustomerSaleModel.fromJson(Map<String, dynamic> json) {
    return CustomerSaleModel(
      customerName: json['customer_name']?.toString() ?? 'غير معروف',
      totalSales: RepresentativeReportModel._parseDouble(json['total_sales']),
      returnsAmount:
          RepresentativeReportModel._parseDouble(json['returns_amount']),
    );
  }
}

class ExpenseItemModel {
  final String category;
  final double amount;
  final String paymentMethod;
  final String? notes;
  final DateTime? expenseAt;

  const ExpenseItemModel({
    required this.category,
    required this.amount,
    required this.paymentMethod,
    this.notes,
    this.expenseAt,
  });

  factory ExpenseItemModel.fromJson(Map<String, dynamic> json) {
    return ExpenseItemModel(
      category: json['category']?.toString() ?? '',
      amount: RepresentativeReportModel._parseDouble(json['amount']),
      paymentMethod: json['payment_method']?.toString() ?? '',
      notes: json['notes']?.toString(),
      expenseAt: RepresentativeReportModel._parseDate(json['expense_at']),
    );
  }
}

class ReturnItemModel {
  final String code;
  final String customerName;
  final double amount;
  final String? reason;
  final DateTime? returnDate;

  const ReturnItemModel({
    required this.code,
    required this.customerName,
    required this.amount,
    this.reason,
    this.returnDate,
  });

  factory ReturnItemModel.fromJson(Map<String, dynamic> json) {
    return ReturnItemModel(
      code: json['code']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'غير معروف',
      amount: RepresentativeReportModel._parseDouble(json['amount']),
      reason: json['reason']?.toString(),
      returnDate: RepresentativeReportModel._parseDate(json['return_date']),
    );
  }
}

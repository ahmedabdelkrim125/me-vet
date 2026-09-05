import 'package:equatable/equatable.dart';

import '../../domain/models/customer_detail_model.dart';

class CustomerAnalysisState extends Equatable {
  final bool isLoading;
  final List<ProductPurchaseModel> topProducts;
  final List<ProductPurchaseModel> notBoughtRecently;
  final List<InvoiceSummaryModel> recentInvoices;
  final List<InvoiceSummaryModel> allInvoices;

  const CustomerAnalysisState({
    this.isLoading = true,
    this.topProducts = const [],
    this.notBoughtRecently = const [],
    this.recentInvoices = const [],
    this.allInvoices = const [],
  });

  CustomerAnalysisState copyWith({
    bool? isLoading,
    List<ProductPurchaseModel>? topProducts,
    List<ProductPurchaseModel>? notBoughtRecently,
    List<InvoiceSummaryModel>? recentInvoices,
    List<InvoiceSummaryModel>? allInvoices,
  }) {
    return CustomerAnalysisState(
      isLoading: isLoading ?? this.isLoading,
      topProducts: topProducts ?? this.topProducts,
      notBoughtRecently: notBoughtRecently ?? this.notBoughtRecently,
      recentInvoices: recentInvoices ?? this.recentInvoices,
      allInvoices: allInvoices ?? this.allInvoices,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, topProducts, notBoughtRecently, recentInvoices, allInvoices];
}

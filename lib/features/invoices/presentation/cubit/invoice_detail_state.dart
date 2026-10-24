// import 'package:mivet_app/features/customer_account/domain/entities/payment_breakdown.dart';
// import 'package:mivet_app/features/invoices/data/invoices_repository.dart';

// enum InvoiceDetailStatus { loading, loaded, failure }

// class InvoiceDetailState {
//   final InvoiceDetailStatus status;
//   final InvoiceFullDetail? detail;
//   final List<PaymentBreakdownLine> oldDebtLines;
//   final double applicableCredit;
//   final InvoiceAccountSummary? accountSummary;
//   final String? successMessage;
//   final Object? error;

//   const InvoiceDetailState({
//     this.status = InvoiceDetailStatus.loading,
//     this.detail,
//     this.oldDebtLines = const [],
//     this.applicableCredit = 0,
//     this.accountSummary,
//     this.successMessage,
//     this.error,
//   });

//   bool get isLoading => status == InvoiceDetailStatus.loading;
//   bool get hasDetail => detail != null;

//   InvoiceDetailState copyWith({
//     InvoiceDetailStatus? status,
//     InvoiceFullDetail? detail,
//     List<PaymentBreakdownLine>? oldDebtLines,
//     double? applicableCredit,
//     InvoiceAccountSummary? accountSummary,
//     String? successMessage,
//     Object? error,
//   }) {
//     return InvoiceDetailState(
//       status: status ?? this.status,
//       detail: detail ?? this.detail,
//       oldDebtLines: oldDebtLines ?? this.oldDebtLines,
//       applicableCredit: applicableCredit ?? this.applicableCredit,
//       accountSummary: accountSummary ?? this.accountSummary,
//       successMessage: successMessage,
//       error: error,
//     );
//   }
// }
import 'package:mivet_app/features/invoices/data/invoices_repository.dart';

enum InvoiceDetailStatus { loading, loaded, failure }

class InvoiceDetailState {
  final InvoiceDetailStatus status;
  final InvoiceFullDetail? detail;
  final double laterCollections;
  final double applicableCredit;
  final InvoiceAccountSummary? accountSummary;
  final String? successMessage;
  final Object? error;

  const InvoiceDetailState({
    this.status = InvoiceDetailStatus.loading,
    this.detail,
    this.laterCollections = 0,
    this.applicableCredit = 0,
    this.accountSummary,
    this.successMessage,
    this.error,
  });

  bool get isLoading => status == InvoiceDetailStatus.loading;
  bool get hasDetail => detail != null;

  InvoiceDetailState copyWith({
    InvoiceDetailStatus? status,
    InvoiceFullDetail? detail,
    double? laterCollections,
    double? applicableCredit,
    InvoiceAccountSummary? accountSummary,
    String? successMessage,
    Object? error,
  }) {
    return InvoiceDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      laterCollections: laterCollections ?? this.laterCollections,
      applicableCredit: applicableCredit ?? this.applicableCredit,
      accountSummary: accountSummary ?? this.accountSummary,
      successMessage: successMessage,
      error: error,
    );
  }
}

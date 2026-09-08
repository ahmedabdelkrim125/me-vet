import 'package:equatable/equatable.dart';
import 'package:mivet_app/core/errors/app_exception.dart';
import '../../domain/entities/customer_ledger.dart';

enum CustomerAccountActionStatus {
  idle,
  submitting,
  success,
  failure,
}

class CustomerAccountState extends Equatable {
  final String customerId;
  final String customerName;
  final bool isLoading;
  final CustomerLedger? ledger;

  final double? fallbackBalance;

  final CustomerAccountActionStatus actionStatus;
  final AppException? actionError;
  final AppException? ledgerError;
  final String? actionSuccessMessage;

  final Map<String, int>? returnedQuantities;

  const CustomerAccountState({
    required this.customerId,
    required this.customerName,
    this.isLoading = true,
    this.ledger,
    this.fallbackBalance,
    this.actionStatus = CustomerAccountActionStatus.idle,
    this.actionError,
    this.ledgerError,
    this.actionSuccessMessage,
    this.returnedQuantities,
  });

  double get balance => ledger?.currentBalance ?? fallbackBalance ?? 0;

  CustomerAccountState copyWith({
    bool? isLoading,
    CustomerLedger? ledger,
    CustomerAccountActionStatus? actionStatus,
    AppException? actionError,
    AppException? ledgerError,
    String? actionSuccessMessage,
    bool clearActionError = false,
    bool clearActionSuccess = false,
    bool clearLedgerError = false,
    Map<String, int>? returnedQuantities,
  }) {
    return CustomerAccountState(
      customerId: customerId,
      customerName: customerName,
      isLoading: isLoading ?? this.isLoading,
      ledger: ledger ?? this.ledger,
      fallbackBalance: fallbackBalance,
      actionStatus: actionStatus ?? this.actionStatus,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      ledgerError: clearLedgerError ? null : (ledgerError ?? this.ledgerError),
      actionSuccessMessage: clearActionSuccess
          ? null
          : (actionSuccessMessage ?? this.actionSuccessMessage),
      returnedQuantities: returnedQuantities ?? this.returnedQuantities,
    );
  }

  @override
  List<Object?> get props => [
        customerId,
        customerName,
        isLoading,
        ledger,
        fallbackBalance,
        actionStatus,
        actionError,
        ledgerError,
        actionSuccessMessage,
        returnedQuantities,
      ];
}

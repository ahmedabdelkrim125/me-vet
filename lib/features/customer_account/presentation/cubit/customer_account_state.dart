import 'package:equatable/equatable.dart';
import 'package:mivet_app/core/errors/app_exception.dart';

import '../../domain/entities/customer_ledger.dart';

enum CustomerAccountActionStatus { idle, submitting, success, failure }

class CustomerAccountState extends Equatable {
  final String customerId;
  final String customerName;
  final bool isLoading;
  final CustomerLedger? ledger;

  /// Display-only fallback (the customer's `current_balance` at the time
  /// this screen was opened). Used only when the ledger has no rows yet —
  /// once the ledger loads with transactions, `balance_after` takes over.
  final double? fallbackBalance;

  final CustomerAccountActionStatus actionStatus;
  final AppException? actionError;
  final String? actionSuccessMessage;

  const CustomerAccountState({
    required this.customerId,
    required this.customerName,
    this.isLoading = true,
    this.ledger,
    this.fallbackBalance,
    this.actionStatus = CustomerAccountActionStatus.idle,
    this.actionError,
    this.actionSuccessMessage,
  });

  double get balance => ledger?.currentBalance ?? fallbackBalance ?? 0;

  CustomerAccountState copyWith({
    bool? isLoading,
    CustomerLedger? ledger,
    CustomerAccountActionStatus? actionStatus,
    AppException? actionError,
    String? actionSuccessMessage,
    bool clearActionError = false,
    bool clearActionSuccess = false,
  }) {
    return CustomerAccountState(
      customerId: customerId,
      customerName: customerName,
      isLoading: isLoading ?? this.isLoading,
      ledger: ledger ?? this.ledger,
      fallbackBalance: fallbackBalance,
      actionStatus: actionStatus ?? this.actionStatus,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      actionSuccessMessage: clearActionSuccess
          ? null
          : (actionSuccessMessage ?? this.actionSuccessMessage),
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
        actionSuccessMessage,
      ];
}
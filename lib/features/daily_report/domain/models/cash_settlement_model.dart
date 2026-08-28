/// The accounting reconciliation block — this is the heart of the
/// "daily settlement" (تصفية المندوب) the rep and admin sign off on.
class CashSettlementModel {
  /// Total value of invoices issued in the period (فواتير المبيعات).
  final double totalInvoicesValue;
  final int totalInvoicesCount;

  /// Cash collected on brand-new invoices, paid at the moment of sale.
  final double cashCollectedOnNewInvoices;

  /// Cash collected against pre-existing customer debt (تحصيل مديونية قديمة).
  final double cashCollectedOnOldDebt;

  double get totalCashCollected =>
      cashCollectedOnNewInvoices + cashCollectedOnOldDebt;

  /// مصاريف الطريق — road expenses the rep is allowed to deduct.
  final double roadExpenses;

  /// المفروض معاه كاش قد إيه — what the rep should be physically
  /// holding: total collected minus road expenses (and minus anything
  /// already handed in, if that's tracked later).
  double get expectedCashInHand => totalCashCollected - roadExpenses;

  /// باقي فلوس بره — total outstanding balance across all assigned
  /// customers (sum of CustomerModel.currentBalance).
  final double outstandingCreditOutside;

  /// Optional: cash actually counted/declared by the rep, so the UI can
  /// show a shortage/surplus (العجز) once that input exists. Null means
  /// "not yet reconciled".
  final double? actualCashDeclared;

  double? get cashShortageOrSurplus => actualCashDeclared == null
      ? null
      : actualCashDeclared! - expectedCashInHand;

  const CashSettlementModel({
    required this.totalInvoicesValue,
    required this.totalInvoicesCount,
    required this.cashCollectedOnNewInvoices,
    required this.cashCollectedOnOldDebt,
    required this.roadExpenses,
    required this.outstandingCreditOutside,
    this.actualCashDeclared,
  });

  static const empty = CashSettlementModel(
    totalInvoicesValue: 0,
    totalInvoicesCount: 0,
    cashCollectedOnNewInvoices: 0,
    cashCollectedOnOldDebt: 0,
    roadExpenses: 0,
    outstandingCreditOutside: 0,
  );
}

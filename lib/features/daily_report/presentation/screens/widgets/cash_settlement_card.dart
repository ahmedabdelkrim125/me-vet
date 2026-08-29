import 'package:flutter/material.dart';
import 'package:mivet_app/features/daily_report/domain/models/cash_settlement_model.dart';
import 'report_card.dart';

class CashSettlementCard extends StatelessWidget {
  final CashSettlementModel cash;
  const CashSettlementCard({super.key, required this.cash});

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      title: 'التصفية المالية',
      icon: Icons.account_balance_wallet_outlined,
      rows: [
        ('عدد الفواتير', '${cash.totalInvoicesCount}'),
        ('قيمة الفواتير', moneyLabel(cash.totalInvoicesValue)),
        ('تحصيل فواتير جديدة', moneyLabel(cash.cashCollectedOnNewInvoices)),
        ('تحصيل مديونية قديمة', moneyLabel(cash.cashCollectedOnOldDebt)),
        ('إجمالي التحصيل', moneyLabel(cash.totalCashCollected)),
        ('مصاريف الطريق', moneyLabel(cash.roadExpenses)),
        ('المفروض معاه كاش', moneyLabel(cash.expectedCashInHand)),
        ('باقي فلوس بره', moneyLabel(cash.outstandingCreditOutside)),
        if (cash.cashShortageOrSurplus != null)
          ('العجز / الزيادة', moneyLabel(cash.cashShortageOrSurplus!)),
      ],
    );
  }
}

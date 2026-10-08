enum PaymentMethod {
  cash,
  vodafoneCash,
  instaPay,
}

extension PaymentMethodBackendValue on PaymentMethod {
  String get backendValue {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.vodafoneCash:
        return 'vodafone_cash';
      case PaymentMethod.instaPay:
        return 'instapay';
    }
  }
}

extension PaymentMethodDisplayLabel on PaymentMethod {
  String get displayLabel {
    switch (this) {
      case PaymentMethod.cash:
        return 'نقدي';
      case PaymentMethod.vodafoneCash:
        return 'فودافون كاش';
      case PaymentMethod.instaPay:
        return 'إنستا باي';
    }
  }
}

class PaymentSplitEntry {
  final PaymentMethod method;
  final double amount;

  const PaymentSplitEntry({required this.method, required this.amount});

  Map<String, dynamic> toRpcJson() => {
        'payment_method': method.backendValue,
        'amount': amount,
      };
}

PaymentMethod? paymentMethodFromBackend(String? value) {
  switch (value) {
    case 'cash':
      return PaymentMethod.cash;
    case 'vodafone_cash':
      return PaymentMethod.vodafoneCash;
    case 'instapay':
      return PaymentMethod.instaPay;
    default:
      return null;
  }
}

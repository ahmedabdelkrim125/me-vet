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

import 'package:mivet_app/features/customer_account/domain/entities/payment_method.dart';
import 'package:test/test.dart';

void main() {
  test('maps payment methods to backend values', () {
    expect(PaymentMethod.cash.backendValue, 'cash');
    expect(PaymentMethod.vodafoneCash.backendValue, 'vodafone_cash');
    expect(PaymentMethod.instaPay.backendValue, 'instapay');
  });

  test('preserves null for historical payment methods', () {
    expect(paymentMethodFromBackend(null), isNull);
    expect(paymentMethodFromBackend('legacy_value'), isNull);
  });
}

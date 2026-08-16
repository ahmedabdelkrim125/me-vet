import '../../customer-visits/customers/domain/models/customer_model.dart';
import '../../customer-visits/customers/domain/models/customer_status.dart';

class DiscountEligibility {
  final bool isEligible;
  final double suggestedPercentage;

  const DiscountEligibility(
      {required this.isEligible, required this.suggestedPercentage});
}

class DiscountCalculator {
  DiscountCalculator._();

  static const double _defaultPercentage = 10;
  static const double _largeOrderThreshold = 1500;

  static DiscountEligibility evaluate(CustomerModel customer) {
    final isActive = customer.status == CustomerStatus.active;
    final isLargeBuyer = customer.averageOrder >= _largeOrderThreshold;

    if (isActive || isLargeBuyer) {
      return const DiscountEligibility(
          isEligible: true, suggestedPercentage: _defaultPercentage);
    }

    return const DiscountEligibility(isEligible: false, suggestedPercentage: 0);
  }
}

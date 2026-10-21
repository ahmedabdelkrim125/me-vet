import 'package:mivet_app/features/home/domain/models/quick_invoice_models.dart';

class CustomerPickerState {
  final List<InvoiceCustomerModel> customers;
  final String query;

  const CustomerPickerState({required this.customers, this.query = ''});

  List<InvoiceCustomerModel> get filtered {
    final needle = query.toLowerCase();
    return customers
        .where((c) => c.customer.name.toLowerCase().contains(needle))
        .toList();
  }

  CustomerPickerState copyWith({String? query}) {
    return CustomerPickerState(
      customers: customers,
      query: query ?? this.query,
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/features/home/domain/models/quick_invoice_models.dart';
import 'package:mivet_app/features/home/presentation/cubit/customer_picker_state.dart';

class CustomerPickerCubit extends Cubit<CustomerPickerState> {
  CustomerPickerCubit(List<InvoiceCustomerModel> customers)
      : super(CustomerPickerState(customers: customers));

  void search(String query) => emit(state.copyWith(query: query));
}

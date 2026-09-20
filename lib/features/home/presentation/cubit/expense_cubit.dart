import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/expense_repository.dart';
import 'expense_state.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  final ExpenseRepository _repository;

  ExpenseCubit(this._repository) : super(const ExpenseInitial());

  Future<void> submitExpense({
    required double amount,
    required String paymentMethod,
    required String category,
    String? notes,
  }) async {
    emit(const ExpenseLoading());
    try {
      await _repository.addExpense(
        amount: amount,
        paymentMethod: paymentMethod,
        category: category,
        notes: notes,
      );
      emit(const ExpenseSuccess());
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }
}

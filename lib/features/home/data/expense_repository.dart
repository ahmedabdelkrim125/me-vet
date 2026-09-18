import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseRepository {
  final SupabaseClient _supabase;

  ExpenseRepository(this._supabase);

  Future<void> addExpense({
    required double amount,
    required String paymentMethod,
    required String category,
    String? notes,
  }) async {
    await _supabase.rpc(
      'add_rep_expense',
      params: {
        'p_amount': amount,
        'p_payment_method': paymentMethod,
        'p_category': category,
        if (notes != null && notes.isNotEmpty) 'p_notes': notes,
        'p_expense_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }
}
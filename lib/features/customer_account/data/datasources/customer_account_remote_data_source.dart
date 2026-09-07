// import 'package:flutter/foundation.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../../domain/entities/payment_method.dart';

// class CustomerAccountRemoteDataSource {
//   const CustomerAccountRemoteDataSource(this._client);

//   final SupabaseClient _client;

//   Future<List<dynamic>> getCustomerLedger({
//     required String customerId,
//     DateTime? from,
//     DateTime? to,
//   }) async {
//     try {
//       return await _fetchCustomerLedger(
//         customerId: customerId,
//         from: from,
//         to: to,
//       );
//     } catch (error, stackTrace) {
//       if (!_isAuthenticationFailure(error)) rethrow;
//       if (kDebugMode) {
//         debugPrint(
//             '[CustomerLedger] auth failure; attempting one refresh: $error');
//         debugPrint('$stackTrace');
//       }
//       try {
//         await _client.auth.refreshSession();
//       } catch (refreshError) {
//         if (kDebugMode) {
//           debugPrint('[CustomerLedger] session refresh failed: $refreshError');
//         }
//         try {
//           await _client.auth.signOut();
//         } catch (_) {}
//         rethrow;
//       }
//       return _fetchCustomerLedger(
//         customerId: customerId,
//         from: from,
//         to: to,
//       );
//     }
//   }

//   Future<List<dynamic>> _fetchCustomerLedger({
//     required String customerId,
//     DateTime? from,
//     DateTime? to,
//   }) async {
//     final result = await _client.rpc('get_customer_ledger', params: {
//       'p_customer_id': customerId,
//       'p_from': from?.toIso8601String(),
//       'p_to': to?.toIso8601String(),
//     });
//     return result as List<dynamic>;
//   }

//   bool _isAuthenticationFailure(Object error) {
//     if (error is AuthException) return true;
//     if (error is PostgrestException) {
//       return error.code == '401' || error.code == 'PGRST301';
//     }
//     if (error is FunctionException) return error.status == 401;
//     return false;
//   }

//   Future<Map<String, dynamic>> recordCustomerPayment({
//     required String customerId,
//     required double amount,
//     String? invoiceId,
//     required String source,
//     String? notes,
//   }) async {
//     final result = await _client.rpc('record_customer_payment', params: {
//       'p_customer_id': customerId,
//       'p_amount': amount,
//       'p_invoice_id': invoiceId,
//       'p_source': source,
//       'p_notes': notes,
//     });
//     return result as Map<String, dynamic>;
//   }

//   Future<Map<String, dynamic>> recordCustomerPaymentV2({
//     required String customerId,
//     required double amount,
//     String? invoiceId,
//     required String source,
//     required PaymentMethod paymentMethod,
//     String? notes,
//   }) async {
//     final result = await _client.rpc('record_customer_payment_v2', params: {
//       'p_customer_id': customerId,
//       'p_amount': amount,
//       'p_invoice_id': invoiceId,
//       'p_source': source,
//       'p_payment_method': paymentMethod.backendValue,
//       'p_notes': notes,
//     });
//     return result as Map<String, dynamic>;
//   }

//   Future<Map<String, dynamic>> recordCustomerAccountPayment({
//     required String customerId,
//     required double amount,
//     required PaymentMethod paymentMethod,
//     String? notes,
//   }) async {
//     final result =
//         await _client.rpc('record_customer_account_payment', params: {
//       'p_customer_id': customerId,
//       'p_amount': amount,
//       'p_payment_method': paymentMethod.backendValue,
//       'p_notes': notes,
//     });
//     return result as Map<String, dynamic>;
//   }

//   Future<Map<String, dynamic>> createSalesReturn({
//     required String customerId,
//     required String invoiceId,
//     required List<Map<String, dynamic>> items,
//     required String reason,
//     String? notes,
//   }) async {
//     final result = await _client.rpc('create_sales_return', params: {
//       'p_customer_id': customerId,
//       'p_invoice_id': invoiceId,
//       'p_items': items,
//       'p_reason': reason,
//       'p_notes': notes,
//     });
//     return result as Map<String, dynamic>;
//   }

//   Future<Map<String, int>> getReturnedQuantities(
//       {required String invoiceId}) async {
//     final result = await _client
//         .from('sales_returns')
//         .select('id, sales_return_items(invoice_item_id, quantity)')
//         .eq('invoice_id', invoiceId);

//     final returnedQuantities = <String, int>{};
//     for (final row in result as List<dynamic>) {
//       final items = row['sales_return_items'] as List<dynamic>?;
//       if (items != null) {
//         for (final item in items) {
//           final itemId = item['invoice_item_id'] as String;
//           final qty = (item['quantity'] as num).toInt();
//           returnedQuantities[itemId] = (returnedQuantities[itemId] ?? 0) + qty;
//         }
//       }
//     }
//     return returnedQuantities;
//   }
// }
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/payment_method.dart';

class CustomerAccountRemoteDataSource {
  const CustomerAccountRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<dynamic>> getCustomerLedger({
    required String customerId,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      return await _fetchCustomerLedger(
        customerId: customerId,
        from: from,
        to: to,
      );
    } catch (error, stackTrace) {
      if (!_isAuthenticationFailure(error)) rethrow;

      if (kDebugMode) {
        debugPrint(
          '[CustomerLedger] auth failure; attempting one refresh: $error',
        );
        debugPrint('$stackTrace');
      }

      try {
        await _client.auth.refreshSession();
      } catch (refreshError) {
        if (kDebugMode) {
          debugPrint(
            '[CustomerLedger] session refresh failed: $refreshError',
          );
        }

        try {
          await _client.auth.signOut();
        } catch (_) {}

        rethrow;
      }

      return _fetchCustomerLedger(
        customerId: customerId,
        from: from,
        to: to,
      );
    }
  }

  Future<double?> getCustomerCurrentBalance({
    required String customerId,
  }) async {
    try {
      return await _fetchCustomerCurrentBalance(customerId);
    } catch (error, stackTrace) {
      if (!_isAuthenticationFailure(error)) rethrow;

      if (kDebugMode) {
        debugPrint(
          '[CustomerBalance] auth failure; attempting one refresh: $error',
        );
        debugPrint('$stackTrace');
      }

      try {
        await _client.auth.refreshSession();
      } catch (refreshError) {
        if (kDebugMode) {
          debugPrint(
            '[CustomerBalance] session refresh failed: $refreshError',
          );
        }

        try {
          await _client.auth.signOut();
        } catch (_) {}

        rethrow;
      }

      return _fetchCustomerCurrentBalance(customerId);
    }
  }

  Future<List<dynamic>> _fetchCustomerLedger({
    required String customerId,
    DateTime? from,
    DateTime? to,
  }) async {
    final result = await _client.rpc(
      'get_customer_ledger',
      params: {
        'p_customer_id': customerId,
        'p_from': from?.toIso8601String(),
        'p_to': to?.toIso8601String(),
      },
    );

    return result as List<dynamic>;
  }

  Future<double?> _fetchCustomerCurrentBalance(
    String customerId,
  ) async {
    final result = await _client.rpc(
      'get_customer_current_balance',
      params: {
        'p_customer_id': customerId,
      },
    );

    if (result == null) return null;
    return (result as num).toDouble();
  }

  bool _isAuthenticationFailure(Object error) {
    if (error is AuthException) return true;

    if (error is PostgrestException) {
      return error.code == '401' || error.code == 'PGRST301';
    }

    if (error is FunctionException) {
      return error.status == 401;
    }

    return false;
  }

  Future<Map<String, dynamic>> recordCustomerPayment({
    required String customerId,
    required double amount,
    String? invoiceId,
    required String source,
    String? notes,
  }) async {
    final result = await _client.rpc(
      'record_customer_payment',
      params: {
        'p_customer_id': customerId,
        'p_amount': amount,
        'p_invoice_id': invoiceId,
        'p_source': source,
        'p_notes': notes,
      },
    );

    return result as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> recordCustomerPaymentV2({
    required String customerId,
    required double amount,
    String? invoiceId,
    required String source,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    final result = await _client.rpc(
      'record_customer_payment_v2',
      params: {
        'p_customer_id': customerId,
        'p_amount': amount,
        'p_invoice_id': invoiceId,
        'p_source': source,
        'p_payment_method': paymentMethod.backendValue,
        'p_notes': notes,
      },
    );

    return result as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> recordCustomerAccountPayment({
    required String customerId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    final result = await _client.rpc(
      'record_customer_account_payment',
      params: {
        'p_customer_id': customerId,
        'p_amount': amount,
        'p_payment_method': paymentMethod.backendValue,
        'p_notes': notes,
      },
    );

    return result as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createSalesReturn({
    required String customerId,
    required String invoiceId,
    required List<Map<String, dynamic>> items,
    required String reason,
    String? notes,
  }) async {
    final result = await _client.rpc(
      'create_sales_return',
      params: {
        'p_customer_id': customerId,
        'p_invoice_id': invoiceId,
        'p_items': items,
        'p_reason': reason,
        'p_notes': notes,
      },
    );

    return result as Map<String, dynamic>;
  }

  Future<Map<String, int>> getReturnedQuantities({
    required String invoiceId,
  }) async {
    final result = await _client
        .from('sales_returns')
        .select('id, sales_return_items(invoice_item_id, quantity)')
        .eq('invoice_id', invoiceId);

    final returnedQuantities = <String, int>{};

    for (final row in result as List<dynamic>) {
      final items = row['sales_return_items'] as List<dynamic>?;

      if (items == null) continue;

      for (final item in items) {
        final itemId = item['invoice_item_id'] as String;
        final quantity = (item['quantity'] as num).toInt();

        returnedQuantities[itemId] =
            (returnedQuantities[itemId] ?? 0) + quantity;
      }
    }

    return returnedQuantities;
  }
}
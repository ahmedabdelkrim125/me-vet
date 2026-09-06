import 'dart:io';

import 'package:mivet_app/features/customer-visits/customers/domain/models/invoice_line_input.dart';
import 'package:mivet_app/features/customer-visits/customers/domain/models/invoice_record_model.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

const _testEmail = 'owner@mivet.com';
const _testPassword = 'Owner@2024';

late SupabaseClient _client;
final _harnessFailures = <String>[];

void main() {
  setUpAll(() async {
    final env = _readEnv();
    _client =
        SupabaseClient(env['SUPABASE_URL']!, env['SUPABASE_PUBLISHABLE_KEY']!);
    await _client.auth.signInWithPassword(
      email: _testEmail,
      password: _testPassword,
    );
  });

  tearDownAll(() async {
    await _client.auth.signOut();
  });

  test('financial harness: cases 3-17', () async {
    _harnessFailures.clear();
    await _runCase(3, () async {
      final customer = await _newCustomer(3);
      await _issue(customer, amount: 1000, quantity: 1, paidNow: 400);
      await _expectBalance(customer, 600);
    });

    await _runCase(4, () async {
      final customer = await _newCustomer(4);
      await _issue(customer, amount: 1000, quantity: 1);
      await _pay(customer, 300);
      await _pay(customer, 200);
      final ledger = await _ledger(customer);
      expect(_typesAscending(ledger), [
        'invoice',
        'payment',
        'payment',
      ]);
      await _expectBalance(customer, 500);
    });

    await _runCase(5, () async {
      final customer = await _newCustomer(5);
      final invoice = await _issue(customer, amount: 100, quantity: 10);
      final item = (await _invoiceItems(invoice.id)).single;
      await _return(customer, invoice.id, {item['id'] as String: 3});
      await _expectBalance(customer, 700);
    });

    await _runCase(6, () async {
      final customer = await _newCustomer(6);
      final invoice = await _issue(
        customer,
        amount: 100,
        quantity: 10,
        paidNow: 1000,
      );
      final item = (await _invoiceItems(invoice.id)).single;
      await _return(customer, invoice.id, {item['id'] as String: 3});
      await _expectBalance(customer, -300);
    });

    await _runCase(7, () async {
      final customer = await _newCustomer(7);
      final invoice = await _issue(
        customer,
        amount: 100,
        quantity: 10,
        paidNow: 1000,
      );
      final item = (await _invoiceItems(invoice.id)).single;
      await _return(customer, invoice.id, {item['id'] as String: 10});
      await _expectBalance(customer, -1000);
    });

    await _runCase(8, () async {
      final customer = await _newCustomer(8);
      final invoice = await _issue(customer, amount: 100, quantity: 2);
      final item = (await _invoiceItems(invoice.id)).single;
      final before = await _returnIds(invoice.id);
      final ledgerBefore = await _ledger(customer);
      await _expectRejected(() => _return(
            customer,
            invoice.id,
            {item['id'] as String: 3},
          ));
      expect(await _returnIds(invoice.id), before);
      expect(_ledgerIds(await _ledger(customer)), _ledgerIds(ledgerBefore));
      await _expectBalance(customer, 200);
    });

    await _runCase(9, () async {
      final customer = await _newCustomer(9);
      final invoice = await _issue(customer, amount: 100, quantity: 5);
      final item = (await _invoiceItems(invoice.id)).single;
      final itemId = item['id'] as String;
      await _return(customer, invoice.id, {itemId: 2});
      expect(await _returnedQuantity(invoice.id, itemId), 2);
      await _return(customer, invoice.id, {itemId: 2});
      expect(await _returnedQuantity(invoice.id, itemId), 4);
      await _expectRejected(() => _return(customer, invoice.id, {itemId: 2}));
      expect(await _returnedQuantity(invoice.id, itemId), 4);
      await _expectBalance(customer, 100);
    });

    await _runCase(10, () async {
      final customer = await _newCustomer(10);
      final invoice = await _issue(
        customer,
        lines: const [
          InvoiceLineInput(
            productId: null,
            productName: 'Product A',
            unitPrice: 100,
            quantity: 5,
          ),
          InvoiceLineInput(
            productId: null,
            productName: 'Product B',
            unitPrice: 200,
            quantity: 3,
          ),
        ],
      );
      final items = await _invoiceItems(invoice.id);
      await _return(customer, invoice.id, {
        items[0]['id'] as String: 2,
        items[1]['id'] as String: 1,
      });
      final returnRow = await _latestReturn(invoice.id);
      expect((returnRow['total_amount'] as num).toDouble(), 400);
      await _expectBalance(customer, 700);
    });

    await _runCase(11, () async {
      final customer = await _newCustomer(11);
      final invoice = await _issue(
        customer,
        discountPercent: 10,
        lines: const [
          InvoiceLineInput(
            productId: null,
            productName: 'Product A',
            unitPrice: 100,
            quantity: 5,
          ),
          InvoiceLineInput(
            productId: null,
            productName: 'Product B',
            unitPrice: 200,
            quantity: 3,
          ),
        ],
      );
      final items = await _invoiceItems(invoice.id);
      await _return(customer, invoice.id, {items[0]['id'] as String: 2});
      const uiTotal = 2 * 100 * (1 - 10 / 100);
      final dbTotal =
          ((await _latestReturn(invoice.id))['total_amount'] as num).toDouble();
      expect(dbTotal, uiTotal);
    });

    await _runCase(12, () async {
      final customer = await _newCustomer(12);
      await _issue(customer, amount: 1000, quantity: 1, paidNow: 1200);
      await _expectBalance(customer, -200);
    });

    await _runCase(13, () async {
      final customer = await _newCustomer(13);
      final invoice = await _issue(customer, amount: 100, quantity: 15);
      await _pay(customer, 500);
      final item = (await _invoiceItems(invoice.id)).single;
      await _return(customer, invoice.id, {item['id'] as String: 2});
      await _expectBalance(customer, 800);
    });

    await _runCase(14, () async {
      final customer = await _newCustomer(14);
      final invoice = await _issue(customer, amount: 100, quantity: 15);
      await _pay(customer, 500);
      await _pay(customer, 300);
      final item = (await _invoiceItems(invoice.id)).single;
      await _return(customer, invoice.id, {item['id'] as String: 2});
      await _expectBalance(customer, 500);
    });

    await _runCase(15, () async {
      final customer = await _newCustomer(15);
      final invoice = await _issue(
        customer,
        amount: 1000,
        quantity: 1,
        paidNow: 1000,
      );
      final item = (await _invoiceItems(invoice.id)).single;
      final before = await _ledger(customer);
      await _expectRejected(() => _return(
            customer,
            invoice.id,
            {item['id'] as String: 2},
          ));
      expect(_ledgerIds(await _ledger(customer)), _ledgerIds(before));
      expect(await _returnIds(invoice.id), isEmpty);
      await _expectBalance(customer, 0);
    });

    await _runCase(16, () async {
      final customer = await _newCustomer(16);
      final invoice = await _issue(customer, amount: 1500, quantity: 15);
      await _pay(customer, 500);
      await _pay(customer, 300);
      final item = (await _invoiceItems(invoice.id)).single;
      await _return(customer, invoice.id, {item['id'] as String: 2});
      final types = _typesAscending(await _ledger(customer));
      expect(types, ['invoice', 'payment', 'payment', 'sales_return']);
    });

    await _runCase(17, () async {
      final customer = await _newCustomer(17);
      final invoice = await _issue(customer, amount: 1000, quantity: 10);
      await _pay(customer, 100);
      final item = (await _invoiceItems(invoice.id)).single;
      await _return(customer, invoice.id, {item['id'] as String: 1});
      final ledger = await _ledger(customer);
      final codes = ledger
          .map((row) => row['reference_code'] as String)
          .toList(growable: false);
      expect(codes.where((code) => code.startsWith('INV-')), hasLength(1));
      expect(codes.where((code) => code.startsWith('PAY-')), hasLength(1));
      expect(codes.where((code) => code.startsWith('RET-')), hasLength(1));
      expect(codes.toSet(), hasLength(codes.length));
    });

    expect(_harnessFailures, isEmpty);
  });

  test('financial harness: cases 19-20 database verification', () async {
    _harnessFailures.clear();
    await _runCase(19, () async {
      final customer = await _newCustomer(19);
      final invoice = await _issue(customer, amount: 100, quantity: 1);
      final item = (await _invoiceItems(invoice.id)).single;
      await _return(customer, invoice.id, {item['id'] as String: 1});
      final ledger = await _ledger(customer);
      expect(_typesAscending(ledger), ['invoice', 'sales_return']);
      await _expectBalance(customer, 0);
    });

    await _runCase(20, () async {
      final customer = await _newCustomer(20);
      final invoice = await _issue(customer, amount: 100, quantity: 1);
      final item = (await _invoiceItems(invoice.id)).single;
      final itemId = item['id'] as String;
      await _return(customer, invoice.id, {itemId: 1});
      expect(await _returnedQuantity(invoice.id, itemId), 1);
      final returned = await _returnedQuantities(invoice.id);
      expect(returned[itemId], 1);
      expect((item['quantity'] as num).toInt() - returned[itemId]!, 0);
    });

    expect(_harnessFailures, isEmpty);
  });
}

Future<void> _runCase(int number, Future<void> Function() body) async {
  try {
    await body();
    stdout.writeln('CASE $number | PASS');
  } catch (error, stackTrace) {
    stderr.writeln('CASE $number | FAIL | $error');
    stderr.writeln(stackTrace);
    _harnessFailures.add('CASE $number | $error');
  }
}

Future<Map<String, dynamic>> _newCustomer(int caseNumber) async {
  final rows = await _client
      .from('customers')
      .insert({
        'name':
            'HARNESS-CASE-$caseNumber-${DateTime.now().microsecondsSinceEpoch}',
        'area': 'TEST',
        'category': 'TEST',
        'status': 'active',
        'phone': '',
        'address': '',
        'notes': 'Financial test harness case $caseNumber',
        'credit_limit': 0,
        'current_balance': 0,
      })
      .select('id')
      .single();
  return rows;
}

Future<InvoiceRecordModel> _issue(
  Map<String, dynamic> customer, {
  double? amount,
  int? quantity,
  List<InvoiceLineInput>? lines,
  double discountPercent = 0,
  double paidNow = 0,
}) {
  final invoiceLines = lines ??
      [
        InvoiceLineInput(
          productId: null,
          productName: 'Harness Product',
          unitPrice: amount!,
          quantity: quantity!,
        ),
      ];
  return _client.rpc('issue_invoice', params: {
    'p_customer_id': customer['id'],
    'p_items': invoiceLines.map((item) => item.toRpcJson()).toList(),
    'p_discount_percent': discountPercent,
    'p_sale_type': 'credit',
    'p_paid_now': paidNow,
    'p_notes': 'Financial test harness',
  }).then((row) => InvoiceRecordModel.fromSupabaseRow(
        row as Map<String, dynamic>,
      ));
}

Future<void> _pay(Map<String, dynamic> customer, double amount) async {
  await _client.rpc('record_customer_payment', params: {
    'p_customer_id': customer['id'],
    'p_amount': amount,
    'p_invoice_id': null,
    'p_source': 'old_debt_payment',
    'p_notes': 'Financial test harness',
  });
}

Future<void> _return(
  Map<String, dynamic> customer,
  String invoiceId,
  Map<String, int> items,
) {
  return _client.rpc('create_sales_return', params: {
    'p_customer_id': customer['id'],
    'p_invoice_id': invoiceId,
    'p_items': items.entries
        .map((entry) => {
              'invoice_item_id': entry.key,
              'quantity': entry.value,
            })
        .toList(),
    'p_reason': 'Financial test harness',
    'p_notes': null,
  });
}

Future<List<Map<String, dynamic>>> _invoiceItems(String invoiceId) async {
  final rows = await _client
      .from('invoice_items')
      .select('id, quantity, unit_price, product_name')
      .eq('invoice_id', invoiceId);
  return (rows as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();
}

Future<List<dynamic>> _ledger(Map<String, dynamic> customer) {
  return _client.rpc('get_customer_ledger', params: {
    'p_customer_id': customer['id'],
    'p_from': null,
    'p_to': null,
  });
}

Future<void> _expectBalance(
  Map<String, dynamic> customer,
  double expected,
) async {
  final rows = await _ledger(customer);
  expect(rows, isNotEmpty);
  final chronological = rows
      .map((row) => Map<String, dynamic>.from(row))
      .toList()
    ..sort((a, b) =>
        (a['occurred_at'] as String).compareTo(b['occurred_at'] as String));
  expect((chronological.last['balance_after'] as num).toDouble(), expected);
}

Future<List<String>> _returnIds(String invoiceId) async {
  final rows = await _client
      .from('sales_returns')
      .select('id')
      .eq('invoice_id', invoiceId);
  return (rows as List).map((row) => row['id'] as String).toList();
}

Future<Map<String, dynamic>> _latestReturn(String invoiceId) async {
  final row = await _client
      .from('sales_returns')
      .select('id, total_amount, code')
      .eq('invoice_id', invoiceId)
      .order('created_at', ascending: false)
      .limit(1)
      .single();
  return Map<String, dynamic>.from(row);
}

Future<int> _returnedQuantity(String invoiceId, String itemId) async {
  final quantities = await _returnedQuantities(invoiceId);
  return quantities[itemId] ?? 0;
}

Future<Map<String, int>> _returnedQuantities(String invoiceId) async {
  final rows = await _client
      .from('sales_returns')
      .select('id, sales_return_items(invoice_item_id, quantity)')
      .eq('invoice_id', invoiceId);
  final result = <String, int>{};
  for (final row in rows as List) {
    for (final item in (row['sales_return_items'] as List? ?? const [])) {
      final itemId = item['invoice_item_id'] as String;
      result[itemId] =
          (result[itemId] ?? 0) + (item['quantity'] as num).toInt();
    }
  }
  return result;
}

Future<void> _expectRejected(Future<void> Function() operation) async {
  var rejected = false;
  try {
    await operation();
  } on PostgrestException {
    rejected = true;
  }
  expect(rejected, isTrue);
}

List<String> _typesAscending(List<dynamic> rows) {
  final copy = rows.map((row) => Map<String, dynamic>.from(row)).toList();
  copy.sort((a, b) =>
      (a['occurred_at'] as String).compareTo(b['occurred_at'] as String));
  return copy.map((row) => row['transaction_type'] as String).toList();
}

List<String> _ledgerIds(List<dynamic> rows) =>
    rows.map((row) => row['id'] as String).toList()..sort();

Map<String, String> _readEnv() {
  final values = <String, String>{};
  for (final line in File('.env').readAsLinesSync()) {
    final separator = line.indexOf('=');
    if (separator <= 0) continue;
    values[line.substring(0, separator)] = line.substring(separator + 1);
  }
  return values;
}

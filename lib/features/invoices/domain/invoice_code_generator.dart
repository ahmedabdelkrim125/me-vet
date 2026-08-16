class InvoiceCodeGenerator {
  InvoiceCodeGenerator._();

  static int _counter = 0;

  static String generate() {
    _counter += 1;
    final year = DateTime.now().year;
    final sequence = _counter.toString().padLeft(4, '0');
    return 'INV-$year-$sequence';
  }
}

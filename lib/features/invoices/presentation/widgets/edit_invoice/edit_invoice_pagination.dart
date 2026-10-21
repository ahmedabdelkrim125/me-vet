import 'package:flutter/material.dart';

class EditInvoicePagination extends StatelessWidget {
  final int page;
  final int pageCount;
  final ValueChanged<int> onChanged;

  const EditInvoicePagination({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: page > 1 ? () => onChanged(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('$page / $pageCount'),
        IconButton(
          onPressed: page < pageCount ? () => onChanged(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

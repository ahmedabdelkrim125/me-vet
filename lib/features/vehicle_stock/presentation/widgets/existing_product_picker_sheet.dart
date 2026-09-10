import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/inventory/domain/models/product_model.dart';

class ExistingProductPickerSheet extends StatefulWidget {
  final Future<List<ProductModel>> Function() loadProducts;

  const ExistingProductPickerSheet({super.key, required this.loadProducts});

  @override
  State<ExistingProductPickerSheet> createState() =>
      _ExistingProductPickerSheetState();
}

class _ExistingProductPickerSheetState
    extends State<ExistingProductPickerSheet> {
  final _search = TextEditingController();
  List<ProductModel>? _products;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.loadProducts().then((products) {
      if (mounted) setState(() => _products = products);
    }).catchError((Object error) {
      if (mounted) setState(() => _error = error.toString());
    });
    _search.addListener(_onSearchChanged);
  }

  void _onSearchChanged() => setState(() {});

  @override
  void dispose() {
    _search
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = _products;
    if (products == null) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final query = _search.text.trim().toLowerCase();
    final filtered = products
        .where((product) =>
            query.isEmpty || product.name.toLowerCase().contains(query))
        .toList();
    return SafeArea(
      child: Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .8),
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
        child: Column(
          children: [
            Text('اختيار صنف موجود',
                style: AppTextStyles.cairoBold18.copyWith(fontSize: 16.sp)),
            SizedBox(height: 12.h),
            TextField(
              controller: _search,
              autofocus: true,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'ابحث باسم الصنف',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 8.h),
            Expanded(
              child: _error != null
                  ? Center(child: Text(_error!))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return ListTile(
                          title: Text(product.name),
                          subtitle:
                              Text('${product.category} — ${product.unit}'),
                          onTap: () => Navigator.pop(context, product),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/product_catalog_item.dart';
import '../domain/models/product_model.dart';

class ProductsRepository {
  ProductsRepository._();

  static final instance = ProductsRepository._();

  SupabaseClient get _supabase => Supabase.instance.client;

  static const productImageBucket = 'product-images';
  static const _productFields =
      'id, name, image_path, category, unit, retail_price, wholesale_price, '
      'min_stock_threshold, expiry_date, created_at';

  Future<List<ProductCatalogItem>> getCategories() =>
      _getCatalog('product_categories');

  Future<List<ProductCatalogItem>> getUnits() => _getCatalog('product_units');

  Future<List<ProductCatalogItem>> _getCatalog(String table) async {
    final rows = await _supabase.from(table).select('code, name').order('name');
    return (rows as List)
        .map((row) =>
            ProductCatalogItem.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<ProductCatalogItem> createCategory(String name) =>
      _createCatalog('product_categories', name, 'category');

  Future<ProductCatalogItem> createUnit(String name) =>
      _createCatalog('product_units', name, 'unit');

  Future<ProductCatalogItem> _createCatalog(
    String table,
    String name,
    String prefix,
  ) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('الاسم مطلوب');
    final code = '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
    final row = await _supabase
        .from(table)
        .insert({'code': code, 'name': cleanName})
        .select('code, name')
        .single();
    return ProductCatalogItem.fromMap(Map<String, dynamic>.from(row));
  }

  Future<String> uploadProductImage(String localPath) async {
    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}_${localPath.split(Platform.pathSeparator).last}';

    final storagePath = 'products/$fileName';

    await _supabase.storage
        .from(productImageBucket)
        .upload(storagePath, File(localPath));

    return _supabase.storage.from(productImageBucket).getPublicUrl(storagePath);
  }

  Future<void> deleteProductImage(String imagePath) async {
    const marker = '/storage/v1/object/public/$productImageBucket/';

    final index = imagePath.indexOf(marker);

    if (index == -1) return;

    final storagePath = imagePath.substring(index + marker.length);

    await _supabase.storage.from(productImageBucket).remove([storagePath]);
  }

  Future<List<ProductModel>> getProducts() async {
    final rows = await _supabase
        .from('products')
        .select(_productFields)
        .order('name', ascending: true);

    return (rows as List)
        .map(
          (row) => _fromRow(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<ProductModel> createProduct({
    required String name,
    required String category,
    required String unit,
    required double retailPrice,
    required double wholesalePrice,
    required int minStockThreshold,
    String? imagePath,
    DateTime? expiryDate,
  }) async {
    final row = await _supabase
        .from('products')
        .insert({
          'name': name,
          'category': category,
          'unit': unit,
          'retail_price': retailPrice,
          'wholesale_price': wholesalePrice,
          'min_stock_threshold': minStockThreshold,
          if (imagePath != null) 'image_path': imagePath,
          if (expiryDate != null) 'expiry_date': _dateOnly(expiryDate),
        })
        .select(_productFields)
        .single();

    return _fromRow(row);
  }

  Future<ProductModel> updateProduct(ProductModel product) async {
    final row = await _supabase
        .from('products')
        .update({
          'name': product.name,
          'category': product.category,
          'unit': product.unit,
          'retail_price': product.retailPrice,
          'wholesale_price': product.wholesalePrice,
          'min_stock_threshold': product.minStockThreshold,
          'image_path': product.imagePath,
          'expiry_date': product.expiryDate == null
              ? null
              : _dateOnly(product.expiryDate!),
        })
        .eq('id', product.id)
        .select(_productFields)
        .single();

    return _fromRow(row);
  }

  Future<void> deleteProduct(String id) async {
    await _supabase.from('products').delete().eq('id', id);
  }

  ProductModel _fromRow(Map<String, dynamic> row) => ProductModel.fromMap(row);

  String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

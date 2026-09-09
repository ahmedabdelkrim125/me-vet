import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/product_category.dart';
import '../domain/models/product_model.dart';
import '../domain/models/product_unit.dart';

class ProductsRepository {
  ProductsRepository._();

  static final instance = ProductsRepository._();

  SupabaseClient get _supabase => Supabase.instance.client;

  static const productImageBucket = 'product-images';

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
        .select(
          'id, name, image_path, category, unit, retail_price, wholesale_price, '
          'min_stock_threshold, expiry_date, created_at',
        )
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
    required ProductCategory category,
    required ProductUnit unit,
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
          'category': _categoryValue(category),
          'unit': _unitValue(unit),
          'retail_price': retailPrice,
          'wholesale_price': wholesalePrice,
          'min_stock_threshold': minStockThreshold,
          if (imagePath != null) 'image_path': imagePath,
          if (expiryDate != null) 'expiry_date': _dateOnly(expiryDate),
        })
        .select(
          'id, name, image_path, category, unit, retail_price, wholesale_price, '
          'min_stock_threshold, expiry_date, created_at',
        )
        .single();

    return _fromRow(row);
  }

  Future<ProductModel> updateProduct(ProductModel product) async {
    final row = await _supabase
        .from('products')
        .update({
          'name': product.name,
          'category': _categoryValue(product.category),
          'unit': _unitValue(product.unit),
          'retail_price': product.retailPrice,
          'wholesale_price': product.wholesalePrice,
          'min_stock_threshold': product.minStockThreshold,
          'image_path': product.imagePath,
          'expiry_date': product.expiryDate == null
              ? null
              : _dateOnly(product.expiryDate!),
        })
        .eq('id', product.id)
        .select(
          'id, name, image_path, category, unit, retail_price, wholesale_price, '
          'min_stock_threshold, expiry_date, created_at',
        )
        .single();

    return _fromRow(row);
  }

  Future<void> deleteProduct(String id) async {
    await _supabase.from('products').delete().eq('id', id);
  }

  ProductModel _fromRow(Map<String, dynamic> row) {
    return ProductModel(
      id: row['id'] as String,
      name: row['name'] as String,
      imagePath: row['image_path'] as String?,
      category: _categoryFromValue(row['category'] as String),
      unit: _unitFromValue(row['unit'] as String),
      retailPrice: (row['retail_price'] as num).toDouble(),
      wholesalePrice: (row['wholesale_price'] as num).toDouble(),
      minStockThreshold: (row['min_stock_threshold'] as num).toInt(),
      expiryDate: row['expiry_date'] == null
          ? null
          : DateTime.parse(row['expiry_date'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  String _categoryValue(ProductCategory value) {
    return value == ProductCategory.largeAnimal ? 'large_animal' : value.name;
  }

  ProductCategory _categoryFromValue(String value) {
    if (value == 'large_animal') {
      return ProductCategory.largeAnimal;
    }

    return ProductCategory.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ProductCategory.other,
    );
  }

  String _unitValue(ProductUnit value) {
    return value.name;
  }

  ProductUnit _unitFromValue(String value) {
    return ProductUnit.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ProductUnit.piece,
    );
  }

  String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/product_catalog_item.dart';
import '../domain/models/product_model.dart';

class DuplicateCatalogItemException implements Exception {
  final String message;

  DuplicateCatalogItemException(this.message);

  @override
  String toString() => message;
}

class CategoryInUseException implements Exception {
  final String message;

  CategoryInUseException(this.message);

  @override
  String toString() => message;
}

class ProductsRepository {
  ProductsRepository._();

  static final instance = ProductsRepository._();

  SupabaseClient get _supabase => Supabase.instance.client;

  static const productImageBucket = 'product-images';
  static const _productFields =
      'id, name, image_path, category, retail_price, wholesale_price, '
      'min_stock_threshold, expiry_date, created_at, deleted_at';

  Future<List<ProductCatalogItem>> getCategories() =>
      _getCatalog('product_categories');

  Future<List<ProductCatalogItem>> _getCatalog(String table) async {
    final rows = await _supabase.from(table).select('code, name').order('name');
    return (rows as List)
        .map((row) =>
            ProductCatalogItem.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<ProductCatalogItem> createCategory(String name) => _createCatalog(
        'product_categories',
        name,
        'category',
        duplicateMessage: 'هذا التصنيف موجود بالفعل',
      );

  Future<ProductCatalogItem> _createCatalog(
    String table,
    String name,
    String prefix, {
    required String duplicateMessage,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('الاسم مطلوب');
    final code = '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
    try {
      final row = await _supabase
          .from(table)
          .insert({'code': code, 'name': cleanName})
          .select('code, name')
          .single();
      return ProductCatalogItem.fromMap(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw DuplicateCatalogItemException(duplicateMessage);
      }
      rethrow;
    }
  }

  Future<ProductCatalogItem> updateCategory(String code, String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('الاسم مطلوب');
    try {
      final row = await _supabase
          .from('product_categories')
          .update({'name': cleanName})
          .eq('code', code)
          .select('code, name')
          .single();
      return ProductCatalogItem.fromMap(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw DuplicateCatalogItemException('هذا التصنيف موجود بالفعل');
      }
      rethrow;
    }
  }

  Future<void> deleteCategory(
    String code, {
    String? reassignProductsTo,
  }) async {
    if (reassignProductsTo != null && reassignProductsTo != code) {
      await _supabase
          .from('products')
          .update({'category': reassignProductsTo}).eq('category', code);
    }
    try {
      await _supabase.from('product_categories').delete().eq('code', code);
    } on PostgrestException catch (error) {
      if (error.code == '23503') {
        throw CategoryInUseException(
          'لا يمكن حذف التصنيف لأنه مرتبط بمنتجات موجودة',
        );
      }
      rethrow;
    }
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
        .isFilter('deleted_at', null)
        .order('name', ascending: true);

    return (rows as List)
        .map(
          (row) => _fromRow(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<ProductModel?> getProductById(String id) async {
    try {
      final row = await _supabase
          .from('products')
          .select(_productFields)
          .eq('id', id)
          .maybeSingle();

      if (row == null) return null;
      return _fromRow(Map<String, dynamic>.from(row));
    } catch (e) {
      return null;
    }
  }

  Future<ProductModel> createProduct({
    required String name,
    required String category,
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
    final result =
        await _supabase.from('products').delete().eq('id', id).select('id');
    if ((result as List).isEmpty) {
      throw Exception('لم يتم العثور على الصنف لحذفه');
    }
  }

  ProductModel _fromRow(Map<String, dynamic> row) => ProductModel.fromMap(row);

  String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

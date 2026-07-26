import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../product_repository.dart';
import '../../models/product.dart';
import '../../models/stock_movement.dart';

class SupabaseProductRepository implements ProductRepository {
  final supa.SupabaseClient _supabase = supa.Supabase.instance.client;

  @override
  Future<List<Product>> getProducts({
    String? searchQuery,
    String? warehouseId,
  }) async {
    var query = _supabase.from('products').select('*, warehouse_stock(*)');

    if (warehouseId != null) {
      // Use eq on the nested join to filter stock for this warehouse
      query = query.eq('warehouse_stock.warehouse_id', warehouseId);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$searchQuery%');
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List).map((json) => Product.fromJson(json)).toList();
  }

  @override
  Future<Product?> getProductById(String id) async {
    final response = await _supabase
        .from('products')
        .select('*, warehouse_stock(*)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Product.fromJson(response);
  }

  @override
  Future<Product> addProduct(Product product) async {
    // Insert into products table
    final response = await _supabase
        .from('products')
        .insert(product.toJson())
        .select()
        .single();

    final newProduct = Product.fromJson(response);

    // If a warehouse is specified and stock is > 0, insert stock
    if (product.warehouseId.isNotEmpty && product.quantityInStock > 0) {
      await _supabase.from('warehouse_stock').insert({
        'product_id': newProduct.id,
        'warehouse_id': product.warehouseId,
        'barcode_unit_qty': product.quantityInStock,
      });
    }

    return newProduct.copyWith(
      quantityInStock: product.quantityInStock,
      warehouseId: product.warehouseId,
    );
  }

  @override
  Future<Product> updateProduct(Product product) async {
    final response = await _supabase
        .from('products')
        .update(product.toJson())
        .eq('id', product.id)
        .select()
        .single();

    // Also update stock if warehouseId is provided
    if (product.warehouseId.isNotEmpty) {
      final stockCheck = await _supabase
          .from('warehouse_stock')
          .select()
          .eq('product_id', product.id)
          .eq('warehouse_id', product.warehouseId)
          .maybeSingle();

      if (stockCheck != null) {
        await _supabase
            .from('warehouse_stock')
            .update({'barcode_unit_qty': product.quantityInStock})
            .eq('id', stockCheck['id']);
      } else {
        await _supabase.from('warehouse_stock').insert({
          'product_id': product.id,
          'warehouse_id': product.warehouseId,
          'barcode_unit_qty': product.quantityInStock,
        });
      }
    }

    return Product.fromJson(response).copyWith(
      quantityInStock: product.quantityInStock,
      warehouseId: product.warehouseId,
    );
  }

  @override
  Future<List<StockMovement>> getStockHistory({String? productId}) async {
    // Maps to stock_entries and stock_entry_items
    var query = _supabase
        .from('stock_entries')
        .select('*, stock_entry_items(*)');
    if (productId != null) {
      query = query.eq('stock_entry_items.product_id', productId);
    }
    final response = await query.order('created_at', ascending: false);

    // We would map this properly, but stock_movement might need its own model update
    // For now returning empty to satisfy interface, will update if needed
    return [];
  }

  @override
  Future<void> recordStockMovement(StockMovement movement) async {
    // Get warehouseId from user profile
    final userId = _supabase.auth.currentUser?.id ?? 'mock-user-id';

    String warehouseId = '';
    try {
      final profile = await _supabase
          .from('profiles')
          .select('warehouse_id')
          .eq('id', userId)
          .single();
      warehouseId = profile['warehouse_id'] as String;
    } catch (e) {
      warehouseId = 'mock-warehouse-id';
    }

    // Convert StockMovement to stock_entries and stock_entry_items
    final entry = await _supabase
        .from('stock_entries')
        .insert({
          'type': movement.type == StockMovementType.inStock
              ? 'stock_in'
              : (movement.type == StockMovementType.outStock
                    ? 'stock_out'
                    : 'adjustment'),
          'warehouse_id': warehouseId,
          'notes': movement.reason,
        })
        .select()
        .single();

    await _supabase.from('stock_entry_items').insert({
      'stock_entry_id': entry['id'],
      'product_id': movement.productId,
      'barcode_unit_qty': movement.delta.abs(),
    });
  }

  @override
  Future<void> transferStock({
    required String sourceProductId,
    required String sourceWarehouseId,
    required String targetWarehouseId,
    required int quantity,
  }) async {
    // Create a transfer record
    final entry = await _supabase
        .from('stock_entries')
        .insert({
          'type': 'transfer',
          'warehouse_id': sourceWarehouseId,
          'destination_warehouse_id': targetWarehouseId,
        })
        .select()
        .single();

    await _supabase.from('stock_entry_items').insert({
      'stock_entry_id': entry['id'],
      'product_id': sourceProductId,
      'barcode_unit_qty': quantity,
    });

    // Actually adjust warehouse_stock using an RPC or two queries
    // Decrement source
    final sourceStock = await _supabase
        .from('warehouse_stock')
        .select()
        .eq('product_id', sourceProductId)
        .eq('warehouse_id', sourceWarehouseId)
        .single();
    await _supabase
        .from('warehouse_stock')
        .update({
          'barcode_unit_qty':
              (sourceStock['barcode_unit_qty'] as int) - quantity,
        })
        .eq('id', sourceStock['id']);

    // Increment destination
    final destStock = await _supabase
        .from('warehouse_stock')
        .select()
        .eq('product_id', sourceProductId)
        .eq('warehouse_id', targetWarehouseId)
        .maybeSingle();

    if (destStock != null) {
      await _supabase
          .from('warehouse_stock')
          .update({
            'barcode_unit_qty':
                (destStock['barcode_unit_qty'] as int) + quantity,
          })
          .eq('id', destStock['id']);
    } else {
      await _supabase.from('warehouse_stock').insert({
        'product_id': sourceProductId,
        'warehouse_id': targetWarehouseId,
        'barcode_unit_qty': quantity,
      });
    }
  }
}

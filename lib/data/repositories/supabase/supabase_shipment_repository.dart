import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../shipment_repository.dart';
import '../../models/shipment.dart';

class SupabaseShipmentRepository implements ShipmentRepository {
  final supa.SupabaseClient _supabase = supa.Supabase.instance.client;

  @override
  Future<Shipment> dispatchShipment({
    required String productId,
    required String productName,
    required int quantity,
    required String destinationWarehouseId,
    required String dispatchedByUserId,
  }) async {
    // Determine source warehouse
    String sourceWarehouseId = '';
    try {
      final profile = await _supabase
          .from('profiles')
          .select('warehouse_id')
          .eq('id', dispatchedByUserId)
          .single();
      sourceWarehouseId = profile['warehouse_id'] as String;
    } catch (e) {
      sourceWarehouseId = 'mock-warehouse-id';
    }

    // 1. Insert into stock_entries (type = 'transfer')
    final entry = await _supabase
        .from('stock_entries')
        .insert({
          'type': 'transfer',
          'warehouse_id': sourceWarehouseId,
          'destination_warehouse_id': destinationWarehouseId,
          'user_id': dispatchedByUserId,
          'notes': 'Pending transfer', // we can use notes to store status
        })
        .select()
        .single();

    // 2. Insert into stock_entry_items
    await _supabase.from('stock_entry_items').insert({
      'stock_entry_id': entry['id'],
      'product_id': productId,
      'product_name': productName,
      'barcode_unit_qty': quantity,
    });

    // 3. Decrement source warehouse stock immediately
    final stockRes = await _supabase
        .from('warehouse_stock')
        .select()
        .eq('product_id', productId)
        .eq('warehouse_id', sourceWarehouseId)
        .single();

    await _supabase
        .from('warehouse_stock')
        .update({
          'barcode_unit_qty': (stockRes['barcode_unit_qty'] as int) - quantity,
        })
        .eq('id', stockRes['id']);

    return (await getShipmentById(entry['id'] as String))!;
  }

  @override
  Future<Shipment?> getShipmentById(String id) async {
    final response = await _supabase
        .from('stock_entries')
        .select('*, stock_entry_items(*)')
        .eq('id', id)
        .eq('type', 'transfer')
        .maybeSingle();

    if (response == null) return null;

    // Convert status mapping
    final statusStr = response['notes'] as String?;
    final isReceived = statusStr?.contains('received') ?? false;
    response['status'] = isReceived ? 'received' : 'pending';

    return Shipment.fromJson(response);
  }

  @override
  Future<void> receiveShipment({
    required String shipmentId,
    required String receivedByUserId,
  }) async {
    final shipmentData = await _supabase
        .from('stock_entries')
        .select('*, stock_entry_items(*)')
        .eq('id', shipmentId)
        .single();
    final destWarehouseId = shipmentData['destination_warehouse_id'];

    final items = shipmentData['stock_entry_items'] as List;
    if (items.isEmpty) return;

    final productId = items.first['product_id'];
    final quantity = items.first['barcode_unit_qty'] as int;

    // 1. Mark as received
    await _supabase
        .from('stock_entries')
        .update({
          'notes':
              'received by $receivedByUserId at ${DateTime.now().toIso8601String()}',
        })
        .eq('id', shipmentId);

    // 2. Increment destination warehouse stock
    final destStock = await _supabase
        .from('warehouse_stock')
        .select()
        .eq('product_id', productId)
        .eq('warehouse_id', destWarehouseId)
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
        'product_id': productId,
        'warehouse_id': destWarehouseId,
        'barcode_unit_qty': quantity,
      });
    }
  }

  @override
  Future<List<Shipment>> getPendingShipmentsForWarehouse(
    String warehouseId,
  ) async {
    final response = await _supabase
        .from('stock_entries')
        .select('*, stock_entry_items(*)')
        .eq('type', 'transfer')
        .eq('destination_warehouse_id', warehouseId)
        .ilike('notes', '%Pending transfer%') // simplistic way to check pending
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      json['status'] = 'pending';
      return Shipment.fromJson(json);
    }).toList();
  }
}

import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../warehouse_repository.dart';
import '../../models/warehouse.dart';

class SupabaseWarehouseRepository implements WarehouseRepository {
  final supa.SupabaseClient _supabase = supa.Supabase.instance.client;

  @override
  Future<List<Warehouse>> getWarehouses({
    bool? activeOnly,
    String? searchQuery,
  }) async {
    var query = _supabase.from('warehouses').select();

    if (activeOnly == true) {
      query = query.eq('is_active', true);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$searchQuery%');
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List).map((json) => Warehouse.fromJson(json)).toList();
  }

  @override
  Future<Warehouse?> getWarehouseById(String id) async {
    final response = await _supabase
        .from('warehouses')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Warehouse.fromJson(response);
  }

  @override
  Future<Warehouse> addWarehouse(Warehouse warehouse) async {
    final response = await _supabase
        .from('warehouses')
        .insert(warehouse.toJson())
        .select()
        .single();

    return Warehouse.fromJson(response);
  }

  @override
  Future<Warehouse> updateWarehouse(Warehouse warehouse) async {
    final response = await _supabase
        .from('warehouses')
        .update(warehouse.toJson())
        .eq('id', warehouse.id)
        .select()
        .single();

    return Warehouse.fromJson(response);
  }
}

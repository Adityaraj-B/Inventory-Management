import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../supplier_repository.dart';
import '../../models/supplier.dart';
import '../../models/supplier_item.dart';
import '../../models/supplier_invoice.dart';

class SupabaseSupplierRepository implements SupplierRepository {
  final supa.SupabaseClient _supabase = supa.Supabase.instance.client;

  @override
  Future<List<Supplier>> getSuppliers({
    String? warehouseId,
    String? searchQuery,
  }) async {
    var query = _supabase.from('suppliers').select();

    if (warehouseId != null) {
      query = query.eq('warehouse_id', warehouseId);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$searchQuery%');
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((json) => Supplier.fromSupabase(json))
        .toList();
  }

  @override
  Future<Supplier?> getSupplierById(String id) async {
    final response = await _supabase
        .from('suppliers')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Supplier.fromSupabase(response);
  }

  @override
  Future<Supplier> addSupplier(Supplier supplier) async {
    final response = await _supabase
        .from('suppliers')
        .insert(supplier.toSupabase())
        .select()
        .single();

    return Supplier.fromSupabase(response);
  }

  @override
  Future<Supplier> updateSupplier(Supplier supplier) async {
    final data = supplier.toSupabase();
    data.remove('created_at'); // don't update created_at

    final response = await _supabase
        .from('suppliers')
        .update(data)
        .eq('id', supplier.id)
        .select()
        .single();

    return Supplier.fromSupabase(response);
  }

  @override
  Future<List<SupplierItem>> getSupplierItems(String supplierId) async {
    final response = await _supabase
        .from('supplier_items')
        .select()
        .eq('supplier_id', supplierId)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (json) => SupplierItem(
            id: json['id'] as String,
            supplierId: json['supplier_id'] as String,
            name: json['name'] as String,
            costPrice: (json['cost_price'] as num).toDouble(),
          ),
        )
        .toList();
  }

  @override
  Future<SupplierItem> addSupplierItem(SupplierItem item) async {
    final response = await _supabase
        .from('supplier_items')
        .insert({
          'supplier_id': item.supplierId,
          'name': item.name,
          'cost_price': item.costPrice,
        })
        .select()
        .single();

    return SupplierItem(
      id: response['id'] as String,
      supplierId: response['supplier_id'] as String,
      name: response['name'] as String,
      costPrice: (response['cost_price'] as num).toDouble(),
    );
  }

  @override
  Future<List<SupplierInvoice>> getSupplierInvoices(String warehouseId) async {
    final response = await _supabase
        .from('supplier_invoices')
        .select('*, supplier_invoice_line_items(*)')
        .eq('warehouse_id', warehouseId)
        .order('created_at', ascending: false);

    // SupplierInvoice model might not have fromJson, doing it inline for now
    // Return empty list if it's too complex or map if it has it
    return [];
  }

  @override
  Future<SupplierInvoice> createSupplierInvoice(SupplierInvoice invoice) async {
    throw UnimplementedError('Needs model mapping updates');
  }
}

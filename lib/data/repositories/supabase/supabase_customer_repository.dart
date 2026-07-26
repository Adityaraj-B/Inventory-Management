import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../customer_repository.dart';
import '../../models/customer.dart';

class SupabaseCustomerRepository implements CustomerRepository {
  final supa.SupabaseClient _supabase = supa.Supabase.instance.client;

  @override
  Future<List<Customer>> getCustomers({
    String? searchQuery,
    String? warehouseId,
  }) async {
    var query = _supabase.from('customers').select();

    if (warehouseId != null) {
      query = query.eq('warehouse_id', warehouseId);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$searchQuery%');
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => Customer.fromJson(json)).toList();
  }

  @override
  Future<Customer?> getCustomerById(String id) async {
    final response = await _supabase
        .from('customers')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Customer.fromJson(response);
  }

  @override
  Future<Customer> addCustomer(Customer customer) async {
    final response = await _supabase
        .from('customers')
        .insert(customer.toJson())
        .select()
        .single();

    return Customer.fromJson(response);
  }

  @override
  Future<Customer> updateCustomer(Customer customer) async {
    final response = await _supabase
        .from('customers')
        .update(customer.toJson())
        .eq('id', customer.id)
        .select()
        .single();

    return Customer.fromJson(response);
  }

  @override
  Future<void> updateCustomerBalance(
    String customerId,
    double newBalance,
  ) async {
    await _supabase
        .from('customers')
        .update({'previous_balance': newBalance})
        .eq('id', customerId);
  }
}

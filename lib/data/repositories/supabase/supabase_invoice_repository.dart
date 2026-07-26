import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../invoice_repository.dart';
import '../../models/invoice.dart';

class SupabaseInvoiceRepository implements InvoiceRepository {
  final supa.SupabaseClient _supabase = supa.Supabase.instance.client;

  @override
  Future<List<Invoice>> getInvoices({String? customerId}) async {
    var query = _supabase.from('invoices').select('*, invoice_line_items(*)');

    if (customerId != null) {
      query = query.eq('customer_id', customerId);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => Invoice.fromJson(json)).toList();
  }

  @override
  Future<List<Invoice>> getTodayInvoices() async {
    final today = DateTime.now();
    final startOfDay = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();

    final response = await _supabase
        .from('invoices')
        .select('*, invoice_line_items(*)')
        .gte('created_at', startOfDay)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Invoice.fromJson(json)).toList();
  }

  @override
  Future<Invoice?> getInvoiceById(String id) async {
    final response = await _supabase
        .from('invoices')
        .select('*, invoice_line_items(*)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Invoice.fromJson(response);
  }

  @override
  Future<Invoice> createInvoice(Invoice invoice) async {
    // Need to get the current user's warehouse_id for the invoice
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
      warehouseId = invoice.lineItems.isNotEmpty
          ? 'mock-warehouse-id'
          : ''; // fallback for bypass
    }

    // Remove empty invoice number so DB trigger can generate it
    final invoiceJson = invoice.toJson();
    invoiceJson.remove('invoice_number');

    // Add required fields
    invoiceJson['warehouse_id'] = warehouseId;
    invoiceJson['user_id'] = userId;
    // Add subtotal and discount as 0 since they aren't explicitly in the app yet
    invoiceJson['subtotal'] = invoice.grandTotal;
    invoiceJson['discount'] = 0.0;

    // Remove fields not in DB or handled by line items
    invoiceJson.remove('id'); // let DB generate UUID

    // 1. Insert Invoice
    final newInvoiceData = await _supabase
        .from('invoices')
        .insert(invoiceJson)
        .select()
        .single();

    final invoiceId = newInvoiceData['id'];

    // 2. Insert Line Items
    if (invoice.lineItems.isNotEmpty) {
      final lineItemsData = invoice.lineItems.map((item) {
        final itemJson = item.toJson();
        itemJson['invoice_id'] = invoiceId;
        return itemJson;
      }).toList();

      await _supabase.from('invoice_line_items').insert(lineItemsData);
    }

    // 3. Update stock levels and customer balance if needed
    // Usually this would be handled by backend triggers, but since the mock did it manually,
    // we should deduct stock here if it isn't in a DB trigger.
    for (final item in invoice.lineItems) {
      final stockRes = await _supabase
          .from('warehouse_stock')
          .select()
          .eq('product_id', item.productId)
          .eq('warehouse_id', warehouseId)
          .maybeSingle();

      if (stockRes != null) {
        final currentStock = stockRes['barcode_unit_qty'] as int;
        await _supabase
            .from('warehouse_stock')
            .update({'barcode_unit_qty': currentStock - item.quantity})
            .eq('id', stockRes['id']);
      }
    }

    if (invoice.outstandingAmount > 0) {
      final custRes = await _supabase
          .from('customers')
          .select('previous_balance')
          .eq('id', invoice.customerId)
          .single();
      final currentBal = custRes['previous_balance'] as num;
      await _supabase
          .from('customers')
          .update({'previous_balance': currentBal + invoice.outstandingAmount})
          .eq('id', invoice.customerId);
    }

    // Return the newly created invoice with generated number
    return await getInvoiceById(invoiceId) ?? invoice;
  }
}

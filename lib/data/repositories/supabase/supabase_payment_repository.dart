import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../payment_repository.dart';
import '../../models/payment.dart';

class SupabasePaymentRepository implements PaymentRepository {
  final supa.SupabaseClient _supabase = supa.Supabase.instance.client;

  @override
  Future<List<Payment>> getPayments({String? customerId}) async {
    var query = _supabase.from('payments').select();

    if (customerId != null) {
      query = query.eq('customer_id', customerId);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => Payment.fromJson(json)).toList();
  }

  @override
  Future<Payment> recordPayment(Payment payment) async {
    final paymentJson = payment.toJson();
    paymentJson.remove('id'); // let db generate UUID

    final response = await _supabase
        .from('payments')
        .insert(paymentJson)
        .select()
        .single();

    return Payment.fromJson(response);
  }
}

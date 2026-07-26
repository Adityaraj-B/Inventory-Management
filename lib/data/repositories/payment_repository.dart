import '../models/payment.dart';

abstract class PaymentRepository {
  Future<List<Payment>> getPayments({String? customerId});
  Future<Payment> recordPayment(Payment payment);
}

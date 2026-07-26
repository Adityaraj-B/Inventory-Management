import '../../models/payment.dart';
import '../../repositories/payment_repository.dart';

class MockPaymentRepository implements PaymentRepository {
  final List<Payment> _payments = [
    Payment(
      id: 'pay-501',
      customerId: 'cust-1',
      invoiceId: 'inv-1001',
      amount: 20000.0,
      paymentMethod: 'UPI / Bank Transfer',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      balanceBefore: 65000.0,
      balanceAfter: 45000.0,
      referenceNumber: 'UPI9876543210',
      notes: 'Partial payment at checkout',
    ),
    Payment(
      id: 'pay-502',
      customerId: 'cust-2',
      invoiceId: 'inv-1002',
      amount: 21000.0,
      paymentMethod: 'Cash',
      date: DateTime.now().subtract(const Duration(hours: 5)),
      balanceBefore: 33500.0,
      balanceAfter: 12500.0,
      referenceNumber: 'CASH-REC-002',
      notes: 'Full payment received',
    ),
  ];

  @override
  Future<List<Payment>> getPayments({String? customerId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (customerId != null && customerId.isNotEmpty) {
      return _payments.where((p) => p.customerId == customerId).toList();
    }
    return List.from(_payments);
  }

  @override
  Future<Payment> recordPayment(Payment payment) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _payments.insert(0, payment);
    return payment;
  }
}

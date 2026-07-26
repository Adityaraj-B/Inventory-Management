import '../models/invoice.dart';

abstract class InvoiceRepository {
  Future<List<Invoice>> getInvoices({String? customerId});
  Future<List<Invoice>> getTodayInvoices();
  Future<Invoice?> getInvoiceById(String id);
  Future<Invoice> createInvoice(Invoice invoice);
}

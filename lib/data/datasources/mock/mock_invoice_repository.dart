import '../../models/invoice.dart';
import '../../models/invoice_line_item.dart';
import '../../repositories/invoice_repository.dart';

class MockInvoiceRepository implements InvoiceRepository {
  final List<Invoice> _invoices = [
    Invoice(
      id: 'inv-1001',
      invoiceNumber: 'INV-2026-001',
      customerId: 'cust-1',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      lineItems: const [
        InvoiceLineItem(
          productId: 'prod-101',
          productName: 'Ultratech Cement (50kg Bag)',
          quantity: 100,
          rate: 380.0,
          lineTotal: 38000.0,
        ),
        InvoiceLineItem(
          productId: 'prod-102',
          productName: 'TMT Steel Bar 12mm (per kg)',
          quantity: 200,
          rate: 65.0,
          lineTotal: 13000.0,
        ),
      ],
      grandTotal: 51000.0,
      amountPaid: 20000.0,
      outstandingAmount: 31000.0,
      paymentMethod: 'UPI / Bank Transfer',
    ),
    Invoice(
      id: 'inv-1002',
      invoiceNumber: 'INV-2026-002',
      customerId: 'cust-2',
      date: DateTime.now().subtract(const Duration(hours: 5)),
      lineItems: const [
        InvoiceLineItem(
          productId: 'prod-103',
          productName: 'Asian Paints Royale White 20L',
          quantity: 5,
          rate: 4200.0,
          lineTotal: 21000.0,
        ),
      ],
      grandTotal: 21000.0,
      amountPaid: 21000.0,
      outstandingAmount: 0.0,
      paymentMethod: 'Cash',
    ),
    Invoice(
      id: 'inv-1003',
      invoiceNumber: 'INV-2026-003',
      customerId: 'cust-4',
      date: DateTime.now().subtract(const Duration(days: 2)),
      lineItems: const [
        InvoiceLineItem(
          productId: 'prod-104',
          productName: 'Havells Copper Wire 2.5sqmm (90m)',
          quantity: 10,
          rate: 1850.0,
          lineTotal: 18500.0,
        ),
      ],
      grandTotal: 18500.0,
      amountPaid: 0.0,
      outstandingAmount: 18500.0,
      paymentMethod: 'Credit / Ledger',
    ),
  ];

  @override
  Future<List<Invoice>> getInvoices({String? customerId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (customerId != null && customerId.isNotEmpty) {
      return _invoices.where((inv) => inv.customerId == customerId).toList();
    }
    return List.from(_invoices);
  }

  @override
  Future<List<Invoice>> getTodayInvoices() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    return _invoices.where((inv) {
      return inv.date.year == now.year &&
          inv.date.month == now.month &&
          inv.date.day == now.day;
    }).toList();
  }

  @override
  Future<Invoice?> getInvoiceById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _invoices.firstWhere((inv) => inv.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Invoice> createInvoice(Invoice invoice) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _invoices.insert(0, invoice);
    return invoice;
  }
}

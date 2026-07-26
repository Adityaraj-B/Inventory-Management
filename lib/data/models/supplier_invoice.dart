import 'package:equatable/equatable.dart';
import 'package:vishnu_enterprises/data/models/supplier_invoice_line_item.dart';

enum PaymentStatus {
  paid,
  partial,
  credit;

  String get displayName {
    switch (this) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.partial:
        return 'Partial';
      case PaymentStatus.credit:
        return 'Credit';
    }
  }

  String toSupabase() {
    switch (this) {
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.partial:
        return 'partial';
      case PaymentStatus.credit:
        return 'credit';
    }
  }

  static PaymentStatus fromSupabase(String value) {
    switch (value) {
      case 'paid':
        return PaymentStatus.paid;
      case 'partial':
        return PaymentStatus.partial;
      case 'credit':
        return PaymentStatus.credit;
      default:
        return PaymentStatus.credit;
    }
  }
}

class SupplierInvoice extends Equatable {
  final String id;
  final String? supplierId;
  final String? warehouseId;
  final String? supplierName;
  final String invoiceNumber;
  final PaymentStatus paymentStatus;
  final DateTime date;
  final double totalAmount;
  final String? notes;
  final List<SupplierInvoiceLineItem> lineItems;

  const SupplierInvoice({
    required this.id,
    this.supplierId,
    this.warehouseId,
    this.supplierName,
    required this.invoiceNumber,
    required this.paymentStatus,
    required this.date,
    required this.totalAmount,
    this.notes,
    required this.lineItems,
  });

  SupplierInvoice copyWith({
    String? id,
    String? supplierId,
    String? warehouseId,
    String? supplierName,
    String? invoiceNumber,
    PaymentStatus? paymentStatus,
    DateTime? date,
    double? totalAmount,
    String? notes,
    List<SupplierInvoiceLineItem>? lineItems,
  }) {
    return SupplierInvoice(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      warehouseId: warehouseId ?? this.warehouseId,
      supplierName: supplierName ?? this.supplierName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      lineItems: lineItems ?? this.lineItems,
    );
  }

  @override
  List<Object?> get props => [
    id,
    supplierId,
    warehouseId,
    supplierName,
    invoiceNumber,
    paymentStatus,
    date,
    totalAmount,
    notes,
    lineItems,
  ];
}

import 'package:equatable/equatable.dart';
import 'invoice_line_item.dart';

class Invoice extends Equatable {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final DateTime date;
  final List<InvoiceLineItem> lineItems;
  final double grandTotal;
  final double amountPaid;
  final double outstandingAmount;
  final String paymentMethod;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.date,
    required this.lineItems,
    required this.grandTotal,
    required this.amountPaid,
    required this.outstandingAmount,
    required this.paymentMethod,
  });

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? customerId,
    DateTime? date,
    List<InvoiceLineItem>? lineItems,
    double? grandTotal,
    double? amountPaid,
    double? outstandingAmount,
    String? paymentMethod,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      date: date ?? this.date,
      lineItems: lineItems ?? this.lineItems,
      grandTotal: grandTotal ?? this.grandTotal,
      amountPaid: amountPaid ?? this.amountPaid,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    List<InvoiceLineItem> items = [];
    if (json['invoice_line_items'] != null) {
      items = (json['invoice_line_items'] as List)
          .map((i) => InvoiceLineItem.fromJson(i))
          .toList();
    }

    return Invoice(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      lineItems: items,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
      outstandingAmount:
          (json['grand_total'] as num?)?.toDouble() ??
          0.0 - ((json['amount_paid'] as num?)?.toDouble() ?? 0.0),
      paymentMethod: json['payment_method'] as String? ?? 'Cash',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber, // ignored by db usually due to trigger
      'customer_id': customerId,
      'date': date.toIso8601String(),
      'grand_total': grandTotal,
      'amount_paid': amountPaid,
      'payment_method': paymentMethod,
      'payment_status': outstandingAmount <= 0
          ? 'paid'
          : (amountPaid > 0 ? 'partial' : 'credit'),
      // line items are handled separately by the repository usually
    };
  }

  @override
  List<Object?> get props => [
    id,
    invoiceNumber,
    customerId,
    date,
    lineItems,
    grandTotal,
    amountPaid,
    outstandingAmount,
    paymentMethod,
  ];
}

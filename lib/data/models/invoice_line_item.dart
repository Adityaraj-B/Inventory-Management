import 'package:equatable/equatable.dart';

class InvoiceLineItem extends Equatable {
  final String productId;
  final String productName;
  final int quantity;
  final double rate;
  final double lineTotal;

  const InvoiceLineItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.rate,
    required this.lineTotal,
  });

  InvoiceLineItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? rate,
    double? lineTotal,
  }) {
    return InvoiceLineItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      lineTotal: lineTotal ?? this.lineTotal,
    );
  }

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItem(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String? ?? 'Unknown',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      lineTotal:
          (json['rate'] as num?)?.toDouble() ??
          0.0 * ((json['quantity'] as num?)?.toInt() ?? 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'rate': rate,
      // sell_mode, units_per_barcode, barcode handled by repository
    };
  }

  @override
  List<Object?> get props => [
    productId,
    productName,
    quantity,
    rate,
    lineTotal,
  ];
}
